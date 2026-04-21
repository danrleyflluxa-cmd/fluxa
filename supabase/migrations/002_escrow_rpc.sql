-- ============================================================
-- FLUXA - Fase 1: RPC Atômica de Escrow
-- ============================================================

create or replace function create_escrow_transaction(
  p_buyer_id   uuid,
  p_seller_id  uuid,
  p_product_id uuid,
  p_amount     numeric
)
returns json
language plpgsql
security definer
as $$
declare
  v_transaction_id uuid;
  v_tracking_code  text;
begin
  -- Gera código de rastreio único
  v_tracking_code := 'FLX-' || upper(substring(gen_random_uuid()::text, 1, 8));

  -- 1. Debita saldo do comprador
  update wallets
  set
    balance_brl = balance_brl - p_amount,
    updated_at  = now()
  where user_id = p_buyer_id
    and balance_brl >= p_amount; -- guard extra contra race condition

  if not found then
    raise exception 'INSUFFICIENT_BALANCE' using errcode = 'P0001';
  end if;

  -- 2. Adiciona ao frozen_balance do vendedor
  update wallets
  set
    frozen_balance = frozen_balance + p_amount,
    updated_at     = now()
  where user_id = p_seller_id;

  if not found then
    raise exception 'SELLER_WALLET_NOT_FOUND' using errcode = 'P0002';
  end if;

  -- 3. Decrementa estoque
  update products
  set
    stock_quantity = stock_quantity - 1,
    updated_at     = now()
  where id = p_product_id
    and stock_quantity > 0;

  if not found then
    raise exception 'OUT_OF_STOCK' using errcode = 'P0003';
  end if;

  -- 4. Cria registro de escrow
  insert into transactions_escrow
    (buyer_id, seller_id, product_id, amount, status, tracking_code)
  values
    (p_buyer_id, p_seller_id, p_product_id, p_amount, 'paid', v_tracking_code)
  returning id into v_transaction_id;

  return json_build_object(
    'transaction_id',  v_transaction_id,
    'tracking_code',   v_tracking_code,
    'amount',          p_amount,
    'status',          'paid'
  );

exception
  when others then
    -- Rollback automático pelo Postgres; repropaga o erro
    raise;
end;
$$;
