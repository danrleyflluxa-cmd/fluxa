import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS_HEADERS })
  if (req.method !== 'POST') return json({ error: 'Method not allowed' }, 405)

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    )

    const authHeader = req.headers.get('Authorization')
    if (!authHeader) return json({ error: 'Unauthorized' }, 401)

    const { data: { user }, error: authError } = await supabase.auth.getUser(
      authHeader.replace('Bearer ', '')
    )
    if (authError || !user) return json({ error: 'Unauthorized' }, 401)

    let body: { recipient_email?: unknown; amount?: unknown }
    try { body = await req.json() } catch { return json({ error: 'JSON inválido' }, 400) }

    const { recipient_email, amount } = body

    if (!recipient_email || typeof recipient_email !== 'string') return json({ error: 'recipient_email obrigatório' }, 400)
    if (!amount || typeof amount !== 'number' || amount <= 0) return json({ error: 'amount inválido' }, 400)

    // Busca destinatário pelo e-mail
    const { data: recipient, error: recipientErr } = await supabase
      .from('profiles')
      .select('id, full_name')
      .eq('email', recipient_email)
      .maybeSingle()

    if (recipientErr || !recipient) return json({ error: 'Destinatário não encontrado' }, 404)
    if (recipient.id === user.id) return json({ error: 'Você não pode transferir para si mesmo' }, 422)

    const { data, error } = await supabase.rpc('transfer_balance', {
      p_sender_id:    user.id,
      p_recipient_id: recipient.id,
      p_amount:       amount,
    })

    if (error) {
      const msg = error.message ?? ''
      if (msg.includes('INSUFFICIENT_BALANCE')) return json({ error: 'Saldo insuficiente' }, 422)
      if (msg.includes('INVALID_AMOUNT'))       return json({ error: 'Valor inválido' }, 422)
      return json({ error: msg }, 500)
    }

    console.log(`[FLUXA] Transferência: ${user.id} → ${recipient.id} R$${amount}`)
    return json({ success: true, transfer: data, recipient_name: recipient.full_name }, 200)

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
