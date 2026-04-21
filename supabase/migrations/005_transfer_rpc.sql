-- ============================================================
-- FLUXA - Fase 1: RPC de Transferência entre Wallets
-- ============================================================

create or replace function transfer_balance(
  p_sender_id    uuid,
  p_recipient_id uuid,
  p_amount       numeric
)
returns json
language plpgsql
security definer
as $$
declare
  v_sender_balance numeric;
begin
  -- Validações básicas
  if p_sender_id = p_recipient_id then
    raise exception 'SELF_TRANSFER' using errcode = 'P0020';
  end if;

  if p_amount <= 0 then
    raise exception 'INVALID_AMOUNT' using errcode = 'P0021';
  end if;

  -- Trava as duas wallets em ordem consistente (evita deadlock)
  perform id from wallets
  where user_id in (p_sender_id, p_recipient_id)
  order by user_id
  for update;

  -- Verifica saldo do remetente
  select balance_brl into v_sender_balance
  from wallets where user_id = p_sender_id;

  if v_sender_balance < p_amount then
    raise exception 'INSUFFICIENT_BALANCE' using errcode = 'P0022';
  end if;

  -- Debita remetente
  update wallets
  set balance_brl = balance_brl - p_amount, updated_at = now()
  where user_id = p_sender_id;

  -- Credita destinatário
  update wallets
  set balance_brl = balance_brl + p_amount, updated_at = now()
  where user_id = p_recipient_id;

  return json_build_object(
    'sender_id',    p_sender_id,
    'recipient_id', p_recipient_id,
    'amount',       p_amount,
    'status',       'completed'
  );

exception
  when others then raise;
end;
$$;
