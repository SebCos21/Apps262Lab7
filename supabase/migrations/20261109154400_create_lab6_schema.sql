-- Esquema base del muro (Laboratorio 6) sobre el proyecto del Laboratorio 5.
-- La tabla profiles ya existe; solo se amplía su lectura para que el muro
-- pueda mostrar el nombre y el avatar de los autores.

alter table public.profiles enable row level security;

drop policy if exists "profiles: leer autenticados" on public.profiles;
create policy "profiles: leer autenticados"
on public.profiles for select to authenticated
using (true);

grant select, insert, update on public.profiles to authenticated;

create table if not exists public.posts (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  content text not null default '',
  created_at timestamptz not null default now(),
  constraint posts_content_length check (char_length(content) <= 280)
);

create index if not exists posts_created_at_idx
on public.posts (created_at desc);

create index if not exists posts_profile_id_idx
on public.posts (profile_id);

alter table public.posts enable row level security;

drop policy if exists "posts: leer autenticados" on public.posts;
create policy "posts: leer autenticados"
on public.posts for select to authenticated
using (true);

drop policy if exists "posts: crear propio" on public.posts;
create policy "posts: crear propio"
on public.posts for insert to authenticated
with check (profile_id = (select auth.uid()));

drop policy if exists "posts: borrar propio" on public.posts;
create policy "posts: borrar propio"
on public.posts for delete to authenticated
using (profile_id = (select auth.uid()));

grant select, insert, update, delete on public.posts to authenticated;

create table if not exists public.likes (
  post_id uuid not null references public.posts(id) on delete cascade,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, profile_id)
);

create index if not exists likes_profile_id_idx
on public.likes (profile_id);

alter table public.likes enable row level security;

drop policy if exists "likes: leer autenticados" on public.likes;
create policy "likes: leer autenticados"
on public.likes for select to authenticated
using (true);

drop policy if exists "likes: crear propio" on public.likes;
create policy "likes: crear propio"
on public.likes for insert to authenticated
with check (profile_id = (select auth.uid()));

drop policy if exists "likes: borrar propio" on public.likes;
create policy "likes: borrar propio"
on public.likes for delete to authenticated
using (profile_id = (select auth.uid()));

grant select, insert, delete on public.likes to authenticated;
