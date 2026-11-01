// Buyurtmaga biriktirilgan faylni Telegram guruhiga hujjat qilib yuboradi.
// Har bir fayl faqat bir marta yuboriladi. Funksiyani notify_telegram trigger'i anon kalit bilan chaqiradi.
import { createClient } from "npm:@supabase/supabase-js@2.45.4";

const ALLOWED = /\.(xlsx|xls|csv|pdf|docx|doc|jpe?g|png)$/i;
const reply = (status: number, msg: string) => new Response(msg, { status });

Deno.serve(async (req) => {
  const { order_id } = await req.json().catch(() => ({}));
  if (!Number.isInteger(order_id)) return reply(400, "order_id required");

  const sb = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const { data: order, error } = await sb.from("orders")
    .select("id, org, attachment_path, attachment_name, attachment_sent_at")
    .eq("id", order_id).maybeSingle();
  if (error) return reply(500, error.message);
  if (!order?.attachment_path || order.attachment_sent_at) return reply(200, "nothing to send");

  const name = order.attachment_name ?? "fayl";
  if (!ALLOWED.test(name)) return reply(422, "file type not allowed");

  const { data: cfg, error: cfgError } = await sb.rpc("telegram_config");
  if (cfgError) return reply(500, cfgError.message);

  // Telegram bilan ulanish vaqti-vaqti bilan qotib qoladi, shuning uchun qayta urinamiz
  let sent = false, lastError = "";
  for (let attempt = 1; attempt <= 3 && !sent; attempt++) {
    try {
      const { data: file, error: dlError } = await sb.storage.from("order-files").download(order.attachment_path);
      if (dlError) throw dlError;
      const form = new FormData();
      form.set("chat_id", String(cfg.chat_id));
      form.set("caption", `📎 Buyurtma №${order.id}: ${order.org}`.slice(0, 1000));
      form.set("document", file, name);
      const tg = await fetch(`https://api.telegram.org/bot${cfg.token}/sendDocument`, {
        method: "POST", body: form, signal: AbortSignal.timeout(25000),
      });
      if (!tg.ok) throw new Error(`telegram ${tg.status}`);
      sent = true;
    } catch (e) {
      lastError = String(e?.message ?? e);
      console.error(`order ${order.id} attempt ${attempt}: ${lastError}`);
    }
  }
  if (!sent) return reply(502, lastError);

  await sb.from("orders").update({ attachment_sent_at: new Date().toISOString() }).eq("id", order.id);
  return reply(200, "sent");
});
