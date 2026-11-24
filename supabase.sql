-- Moonlight Krathong setup (idempotent): run in Supabase SQL Editor.
-- Public gallery: visitors can read and create, but cannot edit/delete records.
create table if not exists public.krathongs (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  wish text not null,
  design text not null default 'lotus',
  created_at timestamptz not null default now()
);

-- Ensure columns exist if a partial/older table was created.
alter table public.krathongs add column if not exists name text;
alter table public.krathongs add column if not exists wish text;
alter table public.krathongs add column if not exists design text default 'lotus';
alter table public.krathongs add column if not exists created_at timestamptz default now();

alter table public.krathongs drop constraint if exists krathongs_design_check;
alter table public.krathongs add constraint krathongs_design_check
  check (design = any(array['gold','lotus','jasmine','marigold','purple','nature','colorful','moon']::text[]));

alter table public.krathongs enable row level security;

drop policy if exists "Public can view shared krathongs" on public.krathongs;
create policy "Public can view shared krathongs" on public.krathongs
  for select to anon, authenticated using (true);

drop policy if exists "Public can launch krathongs" on public.krathongs;
create policy "Public can launch krathongs" on public.krathongs
  for insert to anon, authenticated with check (
    char_length(btrim(name)) between 1 and 30 and
    char_length(btrim(wish)) between 1 and 180 and
    design = any(array['gold','lotus','jasmine','marigold','purple','nature','colorful','moon']::text[])
  );

grant select, insert on public.krathongs to anon, authenticated;

-- Realtime publication, safe to run repeatedly.
do $$ begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname='supabase_realtime' and schemaname='public' and tablename='krathongs'
  ) then
    alter publication supabase_realtime add table public.krathongs;
  end if;
end $$;
