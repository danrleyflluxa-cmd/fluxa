-- ============================================================
-- FLUXA - Fase 1: RPC de Liberação de Escrow
-- ============================================================

create or replace function release_escrow_funds(
  p_transaction_id uuid,
  p_buyer_id       uuid   -- validação: só o comprador pode liberar
)
returns json
language plpgsql
security definer
as $$
declare
  v_tx        transactions_escrow%rowtype;
begin
  -- 1. Busca e trava a transação (FOR UPDATE evita race condition)
  select * into v_tx
  from transactions_escrow
  where id = p_transaction_id
  for update;

  if not found then
    raise exception 'TRANSACTION_NOT_FOUND' using errcode = 'P0010';
  end if;

  -- 2. Valida que quem está liberando é o comprador
  if v_tx.buyer_id <> p_buyer_id then
    raise exception 'UNAUTHORIZED' using errcode = 'P0011';
  end if;

  -- 3. Só libera se estiver em status 'paid'
  if v_tx.status <> 'paid' then
    raise exception 'INVALID_STATUS' using errcode = 'P0012';
  end if;

  -- 4. Move frozen_balance → balance_brl do vendedor
  update wallets
  set
    frozen_balance = frozen_balance - v_tx.amount,
    balance_brl    = balance_brl    + v_tx.amount,
    updated_at     = now()
  where user_id = v_tx.seller_id;

  if not found then
    raise exception 'SELLER_WALLET_NOT_FOUND' using errcode = 'P0013';
  end if;

  -- 5. Atualiza status da transação
  update transactions_escrow
  set status = 'released', updated_at = now()
  where id = p_transaction_id;

  return json_build_object(
    'transaction_id', p_transaction_id,
    'amount',         v_tx.amount,
    'seller_id',      v_tx.seller_id,
    'status',         'released'
  );

exception
  when others then raise;
end;
$$;
