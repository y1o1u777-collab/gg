-- Moonlight Krathong public gallery. Use only a publishable/anon key in the client.
-- Existing table is retained. Expand supported design styles.
alter table public.krathongs drop constraint if exists krathongs_design_check;
alter table public.krathongs add constraint krathongs_design_check check (design = any(array['gold','lotus','jasmine','marigold','purple','nature','colorful','moon']::text[]));

alter table public.krathongs enable row level security;

-- Public read: everyone can see floated krathongs.
drop policy if exists "Public can view shared krathongs" on public.krathongs;
create policy "Public can view shared krathongs" on public.krathongs for select to anon, authenticated using (true);

-- Public create, validated. No update/delete policy is provided.
drop policy if exists "Public can launch krathongs" on public.krathongs;
create policy "Public can launch krathongs" on public.krathongs for insert to anon, authenticated with check (
 char_length(btrim(name)) between 1 and 30 and
 char_length(btrim(wish)) between 1 and 180 and
 design = any(array['gold','lotus','jasmine','marigold','purple','nature','colorful','moon']::text[])
);

grant select, insert on public.krathongs to anon, authenticated;

-- Realtime gallery
DO $$ BEGIN
 if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='krathongs') then
   alter publication supabase_realtime add table public.krathongs;
 end if;
END $$;
