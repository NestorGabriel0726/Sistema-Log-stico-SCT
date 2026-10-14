// Edge Function stub — dispara push (FCM/APNs) quando uma linha é inserida em notifications.
// Configure Database Webhook: INSERT on public.notifications -> this function.

import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';

serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 });
  }

  const payload = await req.json().catch(() => null);
  if (!payload) {
    return new Response('Invalid payload', { status: 400 });
  }

  // TODO: integrar FCM/APNs usando segredos do projeto Supabase.
  console.log('push-notification stub received', payload);

  return new Response(JSON.stringify({ ok: true, delivered: false, reason: 'stub' }), {
    headers: { 'Content-Type': 'application/json' },
  });
});
