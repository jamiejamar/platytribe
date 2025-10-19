create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique,
  is_guest boolean not null default false,
  display_name text,
  photo_url text,
  created_at timestamptz not null default now()
);

create table if not exists public.chats (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  avatar_url text,
  background_url text,
  is_group boolean not null default false,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end $$;

drop trigger if exists trg_chats_updated_at on public.chats;
create trigger trg_chats_updated_at before update on public.chats
for each row execute function public.set_updated_at();

create table if not exists public.chat_tags (
  chat_id uuid not null references public.chats(id) on delete cascade,
  tag text not null,
  primary key (chat_id, tag)
);

create table if not exists public.chat_followers (
  chat_id uuid not null references public.chats(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (chat_id, user_id)
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  chat_id uuid not null references public.chats(id) on delete cascade,
  user_id uuid references auth.users(id) on delete set null,
  text text,
  media_url text,
  created_at timestamptz not null default now(),
  edited_at timestamptz
);

create table if not exists public.user_interests (
  user_id uuid not null references auth.users(id) on delete cascade,
  tag text not null,
  created_at timestamptz not null default now(),
  primary key (user_id, tag)
);

alter table public.profiles enable row level security;
alter table public.chats enable row level security;
alter table public.chat_tags enable row level security;
alter table public.chat_followers enable row level security;
alter table public.messages enable row level security;
alter table public.user_interests enable row level security;

create policy "profiles read public" on public.profiles for select using (true);
create policy "profiles insert self" on public.profiles for insert with check (auth.uid() = id);
create policy "profiles update self" on public.profiles for update using (auth.uid() = id);

create policy "chats read public" on public.chats for select using (true);
create policy "chats insert creator" on public.chats for insert with check (auth.uid() = created_by);
create policy "chats update creator" on public.chats for update using (auth.uid() = created_by);
create policy "chats delete creator" on public.chats for delete using (auth.uid() = created_by);

create policy "chat_tags read public" on public.chat_tags for select using (true);
create policy "chat_tags manage by owner"
on public.chat_tags for all
using (exists (select 1 from public.chats c where c.id = chat_id and c.created_by = auth.uid()))
with check (exists (select 1 from public.chats c where c.id = chat_id and c.created_by = auth.uid()));

create policy "chat_followers read public" on public.chat_followers for select using (true);
create policy "chat_followers upsert self" on public.chat_followers for insert with check (auth.uid() = user_id);
create policy "chat_followers delete self" on public.chat_followers for delete using (auth.uid() = user_id);

create policy "messages read public" on public.messages for select using (true);
create policy "messages insert self" on public.messages for insert with check (auth.uid() = user_id);
create policy "messages update self" on public.messages for update using (auth.uid() = user_id);
create policy "messages delete self" on public.messages for delete using (auth.uid() = user_id);

create policy "user_interests read self" on public.user_interests for select using (auth.uid() = user_id);
create policy "user_interests upsert self" on public.user_interests for insert with check (auth.uid() = user_id);
create policy "user_interests delete self" on public.user_interests for delete using (auth.uid() = user_id);
