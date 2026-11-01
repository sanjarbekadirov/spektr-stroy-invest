-- Spektr Stroy Invest: shaxsiy kabinet sxemasi.
-- Supabase > SQL Editor ga butunlay qo'yib, bir marta ishga tushiring.

-- Mijoz profili
create table public.profiles (
  id          uuid primary key references auth.users (id) on delete cascade,
  first_name  text not null default '',
  last_name   text not null default '',
  phone       text not null default '',
  email       text not null default '',
  created_at  timestamptz not null default now()
);

-- Buyurtmalar. status va amount ni faqat kompaniya (Supabase > Table Editor) o'zgartiradi.
create table public.orders (
  id            bigint generated always as identity primary key,
  user_id       uuid references auth.users (id) on delete set null default auth.uid(),
  org           text not null,
  inn           text not null default '',
  contact_name  text not null,
  phone         text not null,
  address       text not null default '',
  request_text  text not null,
  lang          text not null default 'uz',
  status        text not null default 'new'
                check (status in ('new', 'processing', 'delivered', 'cancelled')),
  amount        numeric(16, 2),
  created_at    timestamptz not null default now()
);
create index orders_user_created_idx on public.orders (user_id, created_at desc);

-- Ro'yxatdan o'tganda profil avtomatik yaratiladi
create function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, first_name, last_name, phone, email)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'first_name', ''),
    coalesce(new.raw_user_meta_data ->> 'last_name', ''),
    coalesce(new.raw_user_meta_data ->> 'phone', ''),
    coalesce(new.email, '')
  );
  return new;
end;
$$;
revoke execute on function public.handle_new_user() from public, anon, authenticated;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Ruxsatlar: har kim faqat o'z yozuvini ko'radi
alter table public.profiles enable row level security;
alter table public.orders   enable row level security;

revoke all on public.profiles from anon, authenticated;
revoke all on public.orders   from anon, authenticated;

grant select on public.profiles to authenticated;
grant update (first_name, last_name, phone) on public.profiles to authenticated;
grant select on public.orders to authenticated;
grant insert (user_id, org, inn, contact_name, phone, address, request_text, lang)
  on public.orders to authenticated;

create policy "profile: read own" on public.profiles
  for select to authenticated using ((select auth.uid()) = id);
create policy "profile: update own" on public.profiles
  for update to authenticated using ((select auth.uid()) = id) with check ((select auth.uid()) = id);
create policy "orders: read own" on public.orders
  for select to authenticated using ((select auth.uid()) = user_id);
create policy "orders: insert own" on public.orders
  for insert to authenticated with check ((select auth.uid()) = user_id);
