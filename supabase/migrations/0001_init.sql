-- MangWalo — initial shared-noticeboard schema.
--
-- Trust model: the Flutter web client holds only the *publishable* key, which
-- is public by design and ships inside main.dart.js. Every table below is
-- therefore protected by Row Level Security, and RLS — never a client-side
-- check — is the actual security boundary.
--
-- Apply either way (see SETUP.md); both are safe to re-run:
--   • Dashboard → SQL Editor → paste this file → Run     (no CLI, no token)
--   • npx supabase db push                               (needs supabase login)

-- ---------------------------------------------------------------------------
-- profiles: one row per auth user, holding the display name the board shows.
-- Deliberately minimal: a first name. No phone, no address, no last name.
-- ---------------------------------------------------------------------------
create table if not exists public.profiles (
  id           uuid primary key references auth.users (id) on delete cascade,
  display_name text not null default '',
  locality     text,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  constraint display_name_len check (char_length(display_name) <= 30)
);

alter table public.profiles enable row level security;

-- Names are shown next to listings and reviews, so they are readable by all
-- signed-in users; only you can change yours.
drop policy if exists "profiles are readable by authenticated users" on public.profiles;
create policy "profiles are readable by authenticated users"
  on public.profiles for select
  to authenticated using (true);

drop policy if exists "you may insert only your own profile" on public.profiles;
create policy "you may insert only your own profile"
  on public.profiles for insert
  to authenticated with check (auth.uid() = id);

drop policy if exists "you may update only your own profile" on public.profiles;
create policy "you may update only your own profile"
  on public.profiles for update
  to authenticated using (auth.uid() = id) with check (auth.uid() = id);

-- Create the profile row automatically so the client never has to.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'display_name', ''))
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- listings: the noticeboard itself. Mirrors the Dart domain model; the client
-- codec is the single translation point.
-- ---------------------------------------------------------------------------
create table if not exists public.listings (
  id                     uuid primary key,
  owner_id               uuid not null references auth.users (id) on delete cascade,
  type                   text not null check (type in ('offer', 'request')),
  title                  text not null,
  description            text not null default '',
  category               text not null,
  sub_category           text not null default '',
  condition_tags         text[] not null default '{}',
  -- Landmark only, never an exact address. Enforced client-side by the
  -- privacy scanner; the length cap here is the backstop.
  area                   text not null default '',
  locality               text not null,
  price_per_day_inr      integer not null,
  deposit_inr            integer,
  status                 text not null default 'saved'
                           check (status in ('saved', 'contacted', 'closed')),
  lending_state          text not null default 'available'
                           check (lending_state in ('available', 'lentOut', 'returned')),
  due_date               date,
  returned_at            timestamptz,
  borrower_name          text not null default '',
  suggested_duration_days integer,
  -- Public Storage URLs, cover first. Photos are downscaled and re-encoded
  -- on-device (stripping EXIF/GPS) before they ever reach the bucket.
  photos                 text[] not null default '{}',
  is_demo                boolean not null default false,
  created_at             timestamptz not null default now(),
  updated_at             timestamptz not null default now(),

  constraint title_len check (char_length(title) between 3 and 60),
  constraint description_len check (char_length(description) <= 500),
  constraint area_len check (char_length(area) <= 60),
  constraint sub_category_len check (char_length(sub_category) <= 30),
  constraint borrower_name_len check (char_length(borrower_name) <= 30),
  constraint price_range check (price_per_day_inr between 50 and 100000),
  constraint deposit_range check (deposit_inr is null or deposit_inr between 0 and 500000),
  constraint photos_max check (array_length(photos, 1) is null or array_length(photos, 1) <= 5),
  -- The invariant the Dart domain also enforces: a due date exists exactly
  -- when the item is rented out.
  constraint due_date_iff_lent_out check (
    (lending_state = 'lentOut') = (due_date is not null)
  )
);

create index if not exists listings_locality_idx on public.listings (locality);
create index if not exists listings_owner_idx on public.listings (owner_id);
create index if not exists listings_updated_idx on public.listings (updated_at desc);

alter table public.listings enable row level security;

-- A noticeboard is meant to be read. Writes are owner-only.
drop policy if exists "listings are readable by authenticated users" on public.listings;
create policy "listings are readable by authenticated users"
  on public.listings for select
  to authenticated using (true);

drop policy if exists "you may insert your own listings" on public.listings;
create policy "you may insert your own listings"
  on public.listings for insert
  to authenticated with check (auth.uid() = owner_id);

drop policy if exists "you may update your own listings" on public.listings;
create policy "you may update your own listings"
  on public.listings for update
  to authenticated using (auth.uid() = owner_id) with check (auth.uid() = owner_id);

drop policy if exists "you may delete your own listings" on public.listings;
create policy "you may delete your own listings"
  on public.listings for delete
  to authenticated using (auth.uid() = owner_id);

-- ---------------------------------------------------------------------------
-- reviews: feedback on a listing, which in practice reviews the person too.
-- ---------------------------------------------------------------------------
create table if not exists public.reviews (
  id            uuid primary key default gen_random_uuid(),
  listing_id    uuid not null references public.listings (id) on delete cascade,
  reviewer_id   uuid not null references auth.users (id) on delete cascade,
  rating        integer not null check (rating between 1 and 5),
  body          text not null,
  reviewer_name text not null default '',
  created_at    timestamptz not null default now(),

  constraint body_len check (char_length(body) between 5 and 500),
  -- One review per person per listing: keeps ratings honest.
  unique (listing_id, reviewer_id)
);

create index if not exists reviews_listing_idx on public.reviews (listing_id);

alter table public.reviews enable row level security;

drop policy if exists "reviews are readable by authenticated users" on public.reviews;
create policy "reviews are readable by authenticated users"
  on public.reviews for select
  to authenticated using (true);

-- You cannot review your own listing, and you cannot review as someone else.
drop policy if exists "you may review someone else's listing" on public.reviews;
create policy "you may review someone else's listing"
  on public.reviews for insert
  to authenticated with check (
    auth.uid() = reviewer_id
    and not exists (
      select 1 from public.listings l
      where l.id = listing_id and l.owner_id = auth.uid()
    )
  );

drop policy if exists "you may edit your own review" on public.reviews;
create policy "you may edit your own review"
  on public.reviews for update
  to authenticated using (auth.uid() = reviewer_id) with check (auth.uid() = reviewer_id);

drop policy if exists "you may delete your own review" on public.reviews;
create policy "you may delete your own review"
  on public.reviews for delete
  to authenticated using (auth.uid() = reviewer_id);

-- ---------------------------------------------------------------------------
-- Shared sample data (Phase A decision: ONE server-side demo set, not a copy
-- per device). Owned by a fixed system user so RLS still applies uniformly.
-- Rows are flagged is_demo, badged "Sample" in the UI, and hideable locally.
-- The seed script inserts them; see tool/seed_supabase.dart.
-- ---------------------------------------------------------------------------
comment on column public.listings.is_demo is
  'Illustrative sample data: generated imagery, fictional neighbours. Badged in the UI and hideable per device.';

-- ---------------------------------------------------------------------------
-- Storage: listing photos. Public read (the board is public to members),
-- owner-only write, and each user is confined to a folder named by their uid.
-- ---------------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('listing-photos', 'listing-photos', true, 2097152,
        array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do nothing;

drop policy if exists "listing photos are publicly readable" on storage.objects;
create policy "listing photos are publicly readable"
  on storage.objects for select
  using (bucket_id = 'listing-photos');

drop policy if exists "you may upload into your own folder" on storage.objects;
create policy "you may upload into your own folder"
  on storage.objects for insert
  to authenticated with check (
    bucket_id = 'listing-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "you may replace your own photos" on storage.objects;
create policy "you may replace your own photos"
  on storage.objects for update
  to authenticated using (
    bucket_id = 'listing-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "you may delete your own photos" on storage.objects;
create policy "you may delete your own photos"
  on storage.objects for delete
  to authenticated using (
    bucket_id = 'listing-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
