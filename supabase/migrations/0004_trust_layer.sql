-- Trust layer: the machinery that makes a stranger willing to hand over a
-- ₹2-lakh bag to a neighbour.
--
-- Four concerns, deliberately separate:
--   verifications   who you are (KYC, enforced just-in-time)
--   condition_sets  what the item looked like at handover and return
--   listing_proofs  evidence a branded item is genuine
--   reports         abuse and counterfeit reporting
--
-- Privacy note that shapes most of this file: identity documents and purchase
-- receipts are the most sensitive data the product will ever hold. Under the
-- DPDP Act 2023 collecting them makes the operator a Data Fiduciary. So none
-- of it is world-readable, none of it lives in the public photo bucket, and
-- the raw document is never stored in Postgres — only a provider reference and
-- a status. See docs/security-baseline.md.

-- ---------------------------------------------------------------------------
-- verifications: one row per user per method.
--
-- Deliberately stores the OUTCOME, not the document: a status, when it was
-- checked, and an opaque provider reference. A leak of this table therefore
-- leaks no Aadhaar or PAN number.
-- ---------------------------------------------------------------------------
create table if not exists public.verifications (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users (id) on delete cascade,
  method      text not null check (method in ('phone', 'government_id', 'pan')),
  status      text not null default 'pending'
                check (status in ('pending', 'verified', 'failed', 'expired')),
  -- Opaque handle from DigiLocker / the KYC provider. Never a document number.
  provider          text not null default '',
  provider_ref      text not null default '',
  -- Safe, low-entropy display crumbs only, e.g. last 2 of a phone.
  masked_hint text not null default '',
  verified_at timestamptz,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),

  constraint provider_ref_len check (char_length(provider_ref) <= 200),
  constraint masked_hint_len check (char_length(masked_hint) <= 12),
  constraint verified_at_iff_verified check (
    (status = 'verified') = (verified_at is not null)
  ),
  unique (user_id, method)
);

create index if not exists verifications_user_idx on public.verifications (user_id);

alter table public.verifications enable row level security;

-- Only you can see your own verification records. Everyone else sees the
-- derived badge below, which exposes "verified: yes/no" and nothing more.
drop policy if exists "you see only your own verifications" on public.verifications;
create policy "you see only your own verifications"
  on public.verifications for select
  to authenticated using (auth.uid() = user_id);

-- Writes come from the server (a KYC webhook via service_role), never the
-- client: a user must not be able to declare themselves verified.
drop policy if exists "clients may not write verifications" on public.verifications;
create policy "clients may not write verifications"
  on public.verifications for insert
  to authenticated with check (false);

-- Public, non-sensitive trust signal: is this user verified enough to transact?
-- A view rather than a column so it cannot drift from the underlying records.
create or replace view public.user_trust as
select
  p.id                                          as user_id,
  p.display_name,
  coalesce(bool_or(v.method = 'phone'         and v.status = 'verified'), false) as phone_verified,
  coalesce(bool_or(v.method = 'government_id' and v.status = 'verified'), false) as id_verified,
  coalesce(bool_or(v.method = 'pan'           and v.status = 'verified'), false) as pan_verified,
  p.created_at                                  as member_since
from public.profiles p
left join public.verifications v on v.user_id = p.id
group by p.id, p.display_name, p.created_at;

grant select on public.user_trust to authenticated;

-- Just-in-time gate. Browsing is open; this is what a first transaction needs.
--   renting  phone + government id
--   listing  phone + government id + PAN (payouts require it regardless)
create or replace function public.may_transact(p_user_id uuid, p_as_owner boolean)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce((
    select t.phone_verified and t.id_verified
             and (not p_as_owner or t.pan_verified)
    from public.user_trust t where t.user_id = p_user_id
  ), false);
$$;

grant execute on function public.may_transact(uuid, boolean) to authenticated;

-- ---------------------------------------------------------------------------
-- condition_sets: the dispute mechanism.
--
-- Chosen because the platform never takes custody, so it cannot inspect
-- anything itself. Both parties photograph the item together, twice, and each
-- confirms the other's set. A dispute then turns on evidence rather than
-- memory — and knowing it is documented is itself a deterrent.
--
-- Timestamps are server-side (`now()`), never client-supplied: a client clock
-- is not evidence.
-- ---------------------------------------------------------------------------
create table if not exists public.condition_sets (
  id          uuid primary key default gen_random_uuid(),
  booking_id  uuid not null references public.bookings (id) on delete cascade,
  -- handover: owner -> renter.  return: renter -> owner.
  phase       text not null check (phase in ('handover', 'return')),
  captured_by uuid not null references auth.users (id) on delete cascade,
  -- Storage paths in the PRIVATE evidence bucket, not public URLs.
  photos      text[] not null default '{}',
  notes       text not null default '',
  -- Each side confirms it is a fair record before the item changes hands.
  owner_confirmed_at  timestamptz,
  renter_confirmed_at timestamptz,
  -- Set when a claim is opened; from then on the set is frozen.
  sealed_at   timestamptz,
  created_at  timestamptz not null default now(),

  constraint notes_len check (char_length(notes) <= 500),
  constraint photos_present check (array_length(photos, 1) between 1 and 10),
  unique (booking_id, phase)
);

create index if not exists condition_sets_booking_idx
  on public.condition_sets (booking_id);

alter table public.condition_sets enable row level security;

drop policy if exists "condition sets are visible to the two parties" on public.condition_sets;
create policy "condition sets are visible to the two parties"
  on public.condition_sets for select
  to authenticated using (
    exists (
      select 1 from public.bookings b
      where b.id = booking_id and auth.uid() in (b.owner_id, b.renter_id)
    )
  );

drop policy if exists "a party may capture condition for their booking" on public.condition_sets;
create policy "a party may capture condition for their booking"
  on public.condition_sets for insert
  to authenticated with check (
    auth.uid() = captured_by
    and exists (
      select 1 from public.bookings b
      where b.id = booking_id
        and auth.uid() in (b.owner_id, b.renter_id)
        and b.status in ('confirmed', 'in_progress')
    )
  );

-- Confirmations may be added, but a sealed set is immutable: evidence must not
-- be editable after a claim is opened. Photos and notes are frozen from the
-- start — a trigger below enforces that, since RLS cannot compare columns.
drop policy if exists "parties may confirm an unsealed set" on public.condition_sets;
create policy "parties may confirm an unsealed set"
  on public.condition_sets for update
  to authenticated using (
    sealed_at is null
    and exists (
      select 1 from public.bookings b
      where b.id = booking_id and auth.uid() in (b.owner_id, b.renter_id)
    )
  );

-- Evidence integrity: once captured, the photos and notes never change. Only
-- the confirmation and seal timestamps may be filled in.
create or replace function public.freeze_condition_evidence()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  if new.photos is distinct from old.photos
     or new.notes is distinct from old.notes
     or new.phase is distinct from old.phase
     or new.booking_id is distinct from old.booking_id
     or new.captured_by is distinct from old.captured_by then
    raise exception 'condition evidence is immutable once captured';
  end if;
  if old.sealed_at is not null then
    raise exception 'condition set is sealed';
  end if;
  return new;
end;
$$;

drop trigger if exists condition_sets_freeze on public.condition_sets;
create trigger condition_sets_freeze
  before update on public.condition_sets
  for each row execute function public.freeze_condition_evidence();

-- Deletion would destroy evidence.
drop policy if exists "condition sets cannot be deleted" on public.condition_sets;
create policy "condition sets cannot be deleted"
  on public.condition_sets for delete
  to authenticated using (false);

-- ---------------------------------------------------------------------------
-- listing_proofs: authenticity evidence for branded listings.
--
-- The platform never holds the item, so it cannot authenticate anything. What
-- it can do is require a receipt or authenticity card once per listing, which
-- shifts liability to the lister and deters casual counterfeits.
-- ---------------------------------------------------------------------------
create table if not exists public.listing_proofs (
  id          uuid primary key default gen_random_uuid(),
  listing_id  uuid not null references public.listings (id) on delete cascade,
  owner_id    uuid not null references auth.users (id) on delete cascade,
  kind        text not null check (kind in ('receipt', 'authenticity_card',
                                            'serial_photo', 'other')),
  -- Private bucket path. Never public: a receipt carries a name and a price.
  storage_path text not null,
  status      text not null default 'pending'
                check (status in ('pending', 'approved', 'rejected')),
  reviewed_at timestamptz,
  review_note text not null default '',
  created_at  timestamptz not null default now(),

  constraint storage_path_len check (char_length(storage_path) between 1 and 400),
  constraint review_note_len check (char_length(review_note) <= 300)
);

create index if not exists listing_proofs_listing_idx
  on public.listing_proofs (listing_id);

alter table public.listing_proofs enable row level security;

drop policy if exists "you see only your own proofs" on public.listing_proofs;
create policy "you see only your own proofs"
  on public.listing_proofs for select
  to authenticated using (auth.uid() = owner_id);

drop policy if exists "you may submit proof for your own listing" on public.listing_proofs;
create policy "you may submit proof for your own listing"
  on public.listing_proofs for insert
  to authenticated with check (
    auth.uid() = owner_id
    and status = 'pending'
    and exists (
      select 1 from public.listings l
      where l.id = listing_id and l.owner_id = auth.uid()
    )
  );

-- Whether a listing carries approved proof — safe to show publicly, and it is
-- the badge a renter actually cares about.
create or replace view public.listing_authenticity as
select
  l.id as listing_id,
  coalesce(bool_or(p.status = 'approved'), false) as proof_approved,
  coalesce(bool_or(p.status = 'pending'), false)  as proof_pending
from public.listings l
left join public.listing_proofs p on p.listing_id = l.id
group by l.id;

grant select on public.listing_authenticity to authenticated;

-- ---------------------------------------------------------------------------
-- reports: abuse, counterfeit suspicion, safety.
-- ---------------------------------------------------------------------------
create table if not exists public.reports (
  id            uuid primary key default gen_random_uuid(),
  reporter_id   uuid not null references auth.users (id) on delete cascade,
  -- Exactly one target.
  listing_id    uuid references public.listings (id) on delete cascade,
  reported_user uuid references auth.users (id) on delete cascade,
  reason        text not null check (reason in ('counterfeit', 'not_as_described',
                  'unsafe', 'harassment', 'spam', 'prohibited_item', 'other')),
  detail        text not null default '',
  status        text not null default 'open'
                  check (status in ('open', 'reviewing', 'actioned', 'dismissed')),
  created_at    timestamptz not null default now(),

  constraint detail_len check (char_length(detail) <= 1000),
  constraint one_target check (
    (listing_id is not null) <> (reported_user is not null)
  ),
  constraint not_self check (reported_user is null or reported_user <> reporter_id)
);

create index if not exists reports_status_idx on public.reports (status, created_at desc);

alter table public.reports enable row level security;

drop policy if exists "you see only your own reports" on public.reports;
create policy "you see only your own reports"
  on public.reports for select
  to authenticated using (auth.uid() = reporter_id);

drop policy if exists "anyone signed in may report" on public.reports;
create policy "anyone signed in may report"
  on public.reports for insert
  to authenticated with check (auth.uid() = reporter_id and status = 'open');

-- Reports are a record; a reporter cannot retract or edit one.
drop policy if exists "reports are not editable by clients" on public.reports;
create policy "reports are not editable by clients"
  on public.reports for update
  to authenticated using (false);

-- ---------------------------------------------------------------------------
-- Private evidence bucket. Separate from listing-photos, which is public:
-- receipts and condition photos must never be world-readable by URL.
-- ---------------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('evidence', 'evidence', false, 5242880,
        array['image/jpeg', 'image/png', 'image/webp', 'application/pdf'])
on conflict (id) do nothing;

drop policy if exists "evidence is readable only by its uploader" on storage.objects;
create policy "evidence is readable only by its uploader"
  on storage.objects for select
  to authenticated using (
    bucket_id = 'evidence'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "you may upload evidence into your own folder" on storage.objects;
create policy "you may upload evidence into your own folder"
  on storage.objects for insert
  to authenticated with check (
    bucket_id = 'evidence'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- No update or delete policy: evidence is write-once.
