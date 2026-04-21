import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, content-type',
}

interface PurchasePayload {
  product_id: string
  seller_id: string
  amount: number
}

serve(async (req) => {
  // Preflight CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: CORS_HEADERS })
  }

  if (req.method !== 'POST') {
    return json({ error: 'Method not allowed' }, 405)
  }

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    )

    // Valida JWT
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) return json({ error: 'Unauthorized' }, 401)

    const { data: { user }, error: authError } = await supabase.auth.getUser(
      authHeader.replace('Bearer ', '')
    )
    if (authError || !user) return json({ error: 'Unauthorized' }, 401)

    // Valida payload
    let payload: PurchasePayload
    try {
      payload = await req.json()
    } catch {
      return json({ error: 'JSON inválido' }, 400)
    }

    const { product_id, seller_id, amount } = payload

    if (!product_id || typeof product_id !== 'string') return json({ error: 'product_id inválido' }, 400)
    if (!seller_id  || typeof seller_id  !== 'string') return json({ error: 'seller_id inválido' }, 400)
    if (!amount     || typeof amount     !== 'number' || amount <= 0) return json({ error: 'amount inválido' }, 400)

    // Impede comprador = vendedor
    if (user.id === seller_id) {
      return json({ error: 'Você não pode comprar seu próprio produto', code: 'SELF_PURCHASE' }, 422)
    }

    // Verifica saldo do comprador
    const { data: buyerWallet, error: walletErr } = await supabase
      .from('wallets')
      .select('id, balance_brl')
      .eq('user_id', user.id)
      .single()

    if (walletErr || !buyerWallet) return json({ error: 'Carteira não encontrada' }, 404)
    if (buyerWallet.balance_brl < amount) {
      return json({ error: 'Saldo insuficiente', code: 'INSUFFICIENT_BALANCE' }, 422)
    }

    // Verifica produto disponível
    const { data: product, error: productErr } = await supabase
      .from('products')
      .select('id, stock_quantity, is_active, seller_id')
      .eq('id', product_id)
      .single()

    if (productErr || !product) return json({ error: 'Produto não encontrado' }, 404)

    // Valida que o seller_id do payload bate com o do produto (evita spoofing)
    if (product.seller_id !== seller_id) {
      return json({ error: 'seller_id não corresponde ao produto' }, 422)
    }

    if (!product.is_active || product.stock_quantity < 1) {
      return json({ error: 'Produto indisponível', code: 'OUT_OF_STOCK' }, 422)
    }

    // Transação atômica via RPC
    const { data: escrow, error: rpcError } = await supabase.rpc('create_escrow_transaction', {
      p_buyer_id:   user.id,
      p_seller_id:  seller_id,
      p_product_id: product_id,
      p_amount:     amount,
    })

    if (rpcError) {
      console.error('RPC error:', rpcError.message)
      const code = rpcError.message
      if (code.includes('INSUFFICIENT_BALANCE')) return json({ error: 'Saldo insuficiente', code }, 422)
      if (code.includes('OUT_OF_STOCK'))         return json({ error: 'Produto esgotado', code }, 422)
      return json({ error: 'Falha na transação', detail: rpcError.message }, 500)
    }

    return json({ success: true, transaction: escrow }, 200)

  } catch (err) {
    console.error('Unexpected error:', err)
    return json({ error: 'Erro interno' }, 500)
  }
})

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
  })
}
