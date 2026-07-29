-- Date-range booking.
--
-- Replaces the binary available / lentOut model, which could not express
-- "booked 12–15 December" and therefore could not prevent double-booking.
--
-- The important line in this file is the EXCLUDE constraint: overlapping
-- confirmed bookings are impossible in the DATABASE, not merely discouraged in
-- the UI. Two renters tapping "confirm" in the same second is exactly when a
-- UI-level check fails, and that is the one moment it must not.

create extension if not exists btree_gist;

-- ---------------------------------------------------------------------------
-- bookings: one row per rental, from request through return.
--
-- Supersedes rental_requests (0002), which modelled interest but had no
-- calendar. Kept as a separate table rather than migrated in place because the
-- lifecycle is genuinely different and 0002 has no production data yet.
-- ---------------------------------------------------------------------------
create table if not exists public.bookings (
  id           uuid primary key default gen_random_uuid(),
  listing_id   uuid not null references public.listings (id) on delete cascade,
  -- Denormalised so each side's inbox is a single-table read.
  owner_id     uuid not null references auth.users (id) on delete cascade,
  renter_id    uuid not null references auth.users (id) on delete cascade,

  -- Half-open [start, end): the renter has the item from start_date up to but
  -- not including end_date, so a same-day handover to the next renter is
  -- representable and back-to-back ranges do not "overlap".
  during       daterange not null,

  status       text not null default 'requested' check (status in (
                 'requested',   -- renter asked, owner has not answered
                 'declined',    -- owner said no
                 'expired',     -- owner never answered in time
                 'withdrawn',   -- renter pulled out before approval
                 'confirmed',   -- approved and paid; the calendar is now blocked
                 'in_progress', -- handover done, condition captured
                 'returned',    -- back with the owner, condition captured
                 'closed',      -- deposit settled, reviews open
                 'cancelled'    -- called off after confirmation
               )),

  -- Priced at request time so a later listing edit cannot change what was
  -- agreed. Money is settled in phase 3; these are the agreed figures.
  price_per_day_inr integer not null,
  deposit_inr       integer,

  note         text not null default '',
  -- Owner must answer before this or a scheduled job expires the request.
  responds_by  timestamptz,
  confirmed_at timestamptz,
  returned_at  timestamptz,

  owner_read_at  timestamptz,
  renter_read_at timestamptz,

  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),

  constraint note_len check (char_length(note) <= 300),
  constraint price_range check (price_per_day_inr between 50 and 100000),
  constraint deposit_range check (deposit_inr is null or deposit_inr between 0 and 500000),
  -- You cannot rent your own item.
  constraint not_own_listing check (owner_id <> renter_id),
  -- A range must be bounded and at least one day long.
  constraint during_bounded check (
    lower(during) is not null and upper(during) is not null
  ),
  constraint during_not_empty check (not isempty(during))
);

-- The heart of it: no two bookings that actually hold the item may overlap.
-- Only live states participate — a declined or expired request must not block
-- the calendar, and a cancelled booking releases its dates immediately.
alter table public.bookings drop constraint if exists bookings_no_overlap;
alter table public.bookings add constraint bookings_no_overlap
  exclude using gist (
    listing_id with =,
    during with &&
  ) where (status in ('confirmed', 'in_progress', 'returned', 'closed'));

create index if not exists bookings_owner_idx
  on public.bookings (owner_id, created_at desc);
create index if not exists bookings_renter_idx
  on public.bookings (renter_id, created_at desc);
create index if not exists bookings_listing_during_idx
  on public.bookings using gist (listing_id, during);

alter table public.bookings enable row level security;

-- Visible only to the two people involved. Note this means the calendar itself
-- is not readable row-by-row by strangers — availability is exposed through
-- the aggregate function below instead, which leaks dates but not identities.
drop policy if exists "bookings are visible to the two parties" on public.bookings;
create policy "bookings are visible to the two parties"
  on public.bookings for select
  to authenticated using (auth.uid() in (owner_id, renter_id));

drop policy if exists "renters may request someone else's listing" on public.bookings;
create policy "renters may request someone else's listing"
  on public.bookings for insert
  to authenticated with check (
    auth.uid() = renter_id
    and status = 'requested'
    and exists (
      select 1 from public.listings l
      where l.id = listing_id
        and l.owner_id = owner_id
        and l.owner_id <> auth.uid()
        and l.type = 'offer'
    )
  );

drop policy if exists "the two parties may advance a booking" on public.bookings;
create policy "the two parties may advance a booking"
  on public.bookings for update
  to authenticated using (auth.uid() in (owner_id, renter_id))
  with check (auth.uid() in (owner_id, renter_id));

-- ---------------------------------------------------------------------------
-- owner_blackouts: dates the owner keeps for themselves ("wearing it that
-- weekend"). Separate from bookings so a personal hold is not an empty rental.
-- ---------------------------------------------------------------------------
create table if not exists public.owner_blackouts (
  id         uuid primary key default gen_random_uuid(),
  listing_id uuid not null references public.listings (id) on delete cascade,
  owner_id   uuid not null references auth.users (id) on delete cascade,
  during     daterange not null,
  reason     text not null default '',
  created_at timestamptz not null default now(),

  constraint reason_len check (char_length(reason) <= 120),
  constraint blackout_not_empty check (not isempty(during))
);

alter table public.owner_blackouts drop constraint if exists blackouts_no_overlap;
alter table public.owner_blackouts add constraint blackouts_no_overlap
  exclude using gist (listing_id with =, during with &&);

create index if not exists blackouts_listing_during_idx
  on public.owner_blackouts using gist (listing_id, during);

alter table public.owner_blackouts enable row level security;

-- Readable by all so renters can see what is unavailable before requesting.
drop policy if exists "blackouts are readable" on public.owner_blackouts;
create policy "blackouts are readable"
  on public.owner_blackouts for select
  to authenticated using (true);

drop policy if exists "owners manage their own blackouts" on public.owner_blackouts;
create policy "owners manage their own blackouts"
  on public.owner_blackouts for all
  to authenticated using (auth.uid() = owner_id) with check (auth.uid() = owner_id);

-- ---------------------------------------------------------------------------
-- Availability, exposed without leaking who booked what.
--
-- security definer so it can read bookings the caller cannot select directly;
-- it returns only date ranges, never identities. search_path is pinned, which
-- is mandatory for a definer function.
-- ---------------------------------------------------------------------------
create or replace function public.listing_unavailable_ranges(p_listing_id uuid)
returns table (during daterange)
language sql
stable
security definer
set search_path = public
as $$
  select b.during
  from public.bookings b
  where b.listing_id = p_listing_id
    and b.status in ('confirmed', 'in_progress', 'returned', 'closed')
  union all
  select k.during
  from public.owner_blackouts k
  where k.listing_id = p_listing_id;
$$;

grant execute on function public.listing_unavailable_ranges(uuid) to authenticated;

-- Is a listing free for the whole requested span?
create or replace function public.listing_is_available(
  p_listing_id uuid, p_from date, p_to date)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select not exists (
    select 1 from public.listing_unavailable_ranges(p_listing_id) r
    where r.during && daterange(p_from, p_to, '[)')
  );
$$;

grant execute on function public.listing_is_available(uuid, date, date) to authenticated;

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public' and tablename = 'bookings'
  ) then
    alter publication supabase_realtime add table public.bookings;
  end if;
end $$;
