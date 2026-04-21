-- ============================================================
-- FLUXA - Fase 1: Schema Inicial
-- ============================================================

-- Extensões necessárias
create extension if not exists "uuid-ossp";

-- ============================================================
-- ENUMS
-- ============================================================
create type user_type as enum ('vendedor', 'indicador', 'investidor', 'comprador');
create type transaction_status as enum ('pending', 'paid', 'held', 'released', 'cancelled');

-- ============================================================
-- PROFILES
-- ============================================================
create table profiles (
  id           uuid primary key references auth.users(id) on delete cascade,
  full_name    text not null,
  email        text not null unique,
  avatar_url   text,
  user_type    user_type not null default 'comprador',
  bio          text,
  score_reputation numeric(5,2) not null default 0.00,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

-- ============================================================
-- WALLETS
-- ============================================================
create table wallets (
  id               uuid primary key default uuid_generate_v4(),
  user_id          uuid not null unique references profiles(id) on delete cascade,
  balance_brl      numeric(15,2) not null default 0.00,
  balance_girocoin numeric(15,8) not null default 0.00,
  frozen_balance   numeric(15,2) not null default 0.00,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

-- ============================================================
-- PRODUCTS
-- ============================================================
create table products (
  id             uuid primary key default uuid_generate_v4(),
  seller_id      uuid not null references profiles(id) on delete cascade,
  title          text not null,
  description    text,
  price_brl      numeric(15,2) not null,
  category       text not null,
  images_url     text[] default '{}',
  stock_quantity integer not null default 0,
  is_active      boolean not null default true,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

-- ============================================================
-- TRANSACTIONS ESCROW
-- ============================================================
create table transactions_escrow (
  id             uuid primary key default uuid_generate_v4(),
  buyer_id       uuid not null references profiles(id),
  seller_id      uuid not null references profiles(id),
  product_id     uuid not null references products(id),
  amount         numeric(15,2) not null,
  status         transaction_status not null default 'pending',
  tracking_code  text unique,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

-- ============================================================
-- FUNÇÃO: auto-criar wallet ao registrar usuário
-- ============================================================
create or replace function handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into wallets (user_id) values (new.id);
  return new;
end;
$$;

create trigger on_profile_created
  after insert on profiles
  for each row execute procedure handle_new_user();

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

-- profiles: usuário vê/edita apenas o próprio perfil
alter table profiles enable row level security;
create policy "profiles_select_own" on profiles for select using (auth.uid() = id);
create policy "profiles_update_own" on profiles for update using (auth.uid() = id);
create policy "profiles_insert_own" on profiles for insert with check (auth.uid() = id);

-- wallets: usuário vê/edita apenas a própria carteira
alter table wallets enable row level security;
create policy "wallets_select_own" on wallets for select using (auth.uid() = user_id);
create policy "wallets_update_own" on wallets for update using (auth.uid() = user_id);

-- products: qualquer autenticado lê; vendedor gerencia os seus
alter table products enable row level security;
create policy "products_select_all" on products for select using (auth.role() = 'authenticated');
create policy "products_insert_own" on products for insert with check (auth.uid() = seller_id);
create policy "products_update_own" on products for update using (auth.uid() = seller_id);
create policy "products_delete_own" on products for delete using (auth.uid() = seller_id);

-- transactions_escrow: comprador e vendedor veem as suas
alter table transactions_escrow enable row level security;
create policy "escrow_select_participant" on transactions_escrow for select
  using (auth.uid() = buyer_id or auth.uid() = seller_id);
create policy "escrow_insert_buyer" on transactions_escrow for insert
  with check (auth.uid() = buyer_id);
