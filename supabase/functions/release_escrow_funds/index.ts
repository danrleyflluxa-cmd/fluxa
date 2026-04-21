import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: CORS_HEADERS })
  }

  if (req.method !== 'POST') return json({ error: 'Method not allowed' }, 405)

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
    let body: { transaction_id?: unknown }
    try {
      body = await req.json()
    } catch {
      return json({ error: 'JSON inválido' }, 400)
    }

    const { transaction_id } = body
    if (!transaction_id || typeof transaction_id !== 'string') {
      return json({ error: 'transaction_id obrigatório e deve ser string' }, 400)
    }

    // Chama RPC atômica
    const { data, error } = await supabase.rpc('release_escrow_funds', {
      p_transaction_id: transaction_id,
      p_buyer_id:       user.id,
    })

    if (error) {
      const msg = error.message ?? 'UNKNOWN'
      const statusMap: Record<string, number> = {
        TRANSACTION_NOT_FOUND: 404,
        UNAUTHORIZED:          403,
        INVALID_STATUS:        422,
        SELLER_WALLET_NOT_FOUND: 500,
      }
      // Encontra a chave que aparece na mensagem de erro
      const matchedKey = Object.keys(statusMap).find(k => msg.includes(k))
      return json({ error: msg }, matchedKey ? statusMap[matchedKey] : 500)
    }

    console.log(`[FLUXA] Pagamento liberado: tx=${transaction_id} vendedor=${data.seller_id} valor=R$${data.amount}`)

    return json({ success: true, release: data }, 200)

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
