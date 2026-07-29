-- Rental requests and the conversation that follows.
--
-- Defined now so the schema is applied in one pass, even though the client UI
-- for it lands in Phase C. Nothing here is reachable without RLS passing.

-- ---------------------------------------------------------------------------
-- rental_requests: "I'd like to rent this, these dates."
-- ---------------------------------------------------------------------------
create table if not exists public.rental_requests (
  id           uuid primary key default gen_random_uuid(),
  listing_id   uuid not null references public.listings (id) on delete cascade,
  -- Denormalised so the owner's inbox is a single-table read, and so the row
  -- survives for the record even if the listing is later deleted upstream.
  owner_id     uuid not null references auth.users (id) on delete cascade,
  requester_id uuid not null references auth.users (id) on delete cascade,
  status       text not null default 'pending'
                 check (status in ('pending', 'accepted', 'declined', 'withdrawn')),
  start_date   date,
  end_date     date,
  note         text not null default '',
  -- Unread markers drive the app-bar bell badge; each side tracks its own.
  owner_read_at     timestamptz,
  requester_read_at timestamptz,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),

  constraint note_len check (char_length(note) <= 300),
  constraint dates_ordered check (
    start_date is null or end_date is null or end_date >= start_date
  ),
  -- You cannot request your own item.
  constraint not_own_listing check (owner_id <> requester_id),
  -- One open request per person per listing; re-requesting means reusing it.
  unique (listing_id, requester_id)
);

create index if not exists rental_requests_owner_idx
  on public.rental_requests (owner_id, created_at desc);
create index if not exists rental_requests_requester_idx
  on public.rental_requests (requester_id, created_at desc);

alter table public.rental_requests enable row level security;

-- Visible only to the two people involved — not to the rest of the board.
drop policy if exists "requests are visible to the two parties" on public.rental_requests;
create policy "requests are visible to the two parties"
  on public.rental_requests for select
  to authenticated using (auth.uid() in (owner_id, requester_id));

drop policy if exists "you may request someone else's listing" on public.rental_requests;
create policy "you may request someone else's listing"
  on public.rental_requests for insert
  to authenticated with check (
    auth.uid() = requester_id
    and exists (
      select 1 from public.listings l
      where l.id = listing_id and l.owner_id = owner_id and l.owner_id <> auth.uid()
    )
  );

-- Both sides can update: the owner accepts/declines, the requester withdraws
-- or marks read. Column-level intent is enforced in the client; RLS keeps
-- strangers out entirely.
drop policy if exists "the two parties may update the request" on public.rental_requests;
create policy "the two parties may update the request"
  on public.rental_requests for update
  to authenticated using (auth.uid() in (owner_id, requester_id))
  with check (auth.uid() in (owner_id, requester_id));

-- ---------------------------------------------------------------------------
-- messages: the thread attached to a request, so a conversation always has a
-- subject — no context-free DMs between strangers.
-- ---------------------------------------------------------------------------
create table if not exists public.messages (
  id         uuid primary key default gen_random_uuid(),
  request_id uuid not null references public.rental_requests (id) on delete cascade,
  sender_id  uuid not null references auth.users (id) on delete cascade,
  body       text not null,
  created_at timestamptz not null default now(),

  constraint body_len check (char_length(body) between 1 and 2000)
);

create index if not exists messages_request_idx
  on public.messages (request_id, created_at);

alter table public.messages enable row level security;

drop policy if exists "thread messages are visible to the two parties" on public.messages;
create policy "thread messages are visible to the two parties"
  on public.messages for select
  to authenticated using (
    exists (
      select 1 from public.rental_requests r
      where r.id = request_id and auth.uid() in (r.owner_id, r.requester_id)
    )
  );

drop policy if exists "you may post into a thread you are part of" on public.messages;
create policy "you may post into a thread you are part of"
  on public.messages for insert
  to authenticated with check (
    auth.uid() = sender_id
    and exists (
      select 1 from public.rental_requests r
      where r.id = request_id and auth.uid() in (r.owner_id, r.requester_id)
    )
  );

-- Messages are deliberately NOT updatable or deletable: an agreed handover
-- date should not be editable after the fact.

-- Realtime for the inbox badge and live threads.
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public' and tablename = 'rental_requests'
  ) then
    alter publication supabase_realtime add table public.rental_requests;
  end if;
end $$;
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public' and tablename = 'messages'
  ) then
    alter publication supabase_realtime add table public.messages;
  end if;
end $$;
