-- ============================================================
-- FLUXA - Auditoria: correções de schema e segurança
-- ============================================================

-- 1. Índices ausentes — críticos para performance em produção
create index if not exists idx_wallets_user_id          on wallets(user_id);
create index if not exists idx_products_seller_id       on products(seller_id);
create index if not exists idx_products_category        on products(category);
create index if not exists idx_products_is_active       on products(is_active);
create index if not exists idx_escrow_buyer_id          on transactions_escrow(buyer_id);
create index if not exists idx_escrow_seller_id         on transactions_escrow(seller_id);
create index if not exists idx_escrow_status            on transactions_escrow(status);
create index if not exists idx_escrow_created_at        on transactions_escrow(created_at desc);

-- 2. Constraint: comprador não pode ser o mesmo que o vendedor
alter table transactions_escrow
  add constraint chk_buyer_ne_seller check (buyer_id <> seller_id);

-- 3. Constraint: saldos nunca negativos
alter table wallets
  add constraint chk_balance_brl_non_negative    check (balance_brl    >= 0),
  add constraint chk_frozen_balance_non_negative check (frozen_balance >= 0),
  add constraint chk_girocoin_non_negative       check (balance_girocoin >= 0);

-- 4. Constraint: amount sempre positivo
alter table transactions_escrow
  add constraint chk_amount_positive check (amount > 0);

-- 5. RLS ausente em wallets para INSERT (trigger usa security definer, mas
--    um insert direto via anon key ficaria aberto)
create policy "wallets_insert_own" on wallets
  for insert with check (auth.uid() = user_id);

-- 6. Política de UPDATE em transactions_escrow estava ausente
--    (a RPC usa security definer, mas protege contra updates diretos)
create policy "escrow_update_participant" on transactions_escrow
  for update using (auth.uid() = buyer_id or auth.uid() = seller_id);

-- 7. updated_at automático via trigger (evita esquecer de setar manualmente)
create or replace function set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger trg_profiles_updated_at
  before update on profiles
  for each row execute procedure set_updated_at();

create trigger trg_wallets_updated_at
  before update on wallets
  for each row execute procedure set_updated_at();

create trigger trg_products_updated_at
  before update on products
  for each row execute procedure set_updated_at();

create trigger trg_escrow_updated_at
  before update on transactions_escrow
  for each row execute procedure set_updated_at();

-- 8. price_brl nunca negativo ou zero
alter table products
  add constraint chk_price_positive check (price_brl > 0);

-- 9. stock_quantity nunca negativo
alter table products
  add constraint chk_stock_non_negative check (stock_quantity >= 0);
