-- Spektr Stroy Invest: buyurtmaga fayl biriktirish.
-- telegram.sql dan keyin ishga tushiring, keyin functions/order-file ni joylang (JWT tekshiruvi yoqiq qoladi).
-- Oldin kerak: Vault'da functions_anon_key nomli secret (Project Settings > API Keys > Legacy dagi anon kalit).
-- Guruh ID'si o'zgarsa, faqat telegram_chat_id() ni yangilang.

alter table public.orders
  add column attachment_path text,
  add column attachment_name text,
  add column attachment_sent_at timestamptz,
  add constraint orders_attachment check (
    (attachment_path is null or (attachment_path like 'incoming/%' and char_length(attachment_path) <= 200))
    and char_length(attachment_name) <= 200
  );

grant insert (attachment_path, attachment_name) on public.orders to anon, authenticated;

-- Fayllar yopiq saqlanadi: sayt faqat yuklay oladi, o'qiy olmaydi
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('order-files', 'order-files', false, 10485760, array[
  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  'application/vnd.ms-excel',
  'text/csv',
  'application/pdf',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'application/msword',
  'image/jpeg',
  'image/png'
]);

create policy "order files: upload" on storage.objects
  for insert to anon, authenticated
  with check (bucket_id = 'order-files' and (storage.foldername(name))[1] = 'incoming');

create function public.telegram_chat_id()
returns bigint language sql immutable as $$ select -1003909099944::bigint $$;

-- Faqat order-file funksiyasi (service_role) chaqira oladi
create function public.telegram_config()
returns jsonb
language sql
security definer
set search_path = ''
as $$
  select jsonb_build_object('token', decrypted_secret, 'chat_id', public.telegram_chat_id())
  from vault.decrypted_secrets where name = 'telegram_bot_token'
$$;
revoke execute on function public.telegram_config() from public, anon, authenticated;
grant execute on function public.telegram_config() to service_role;

create or replace function public.notify_telegram()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_token text;
  v_email text;
begin
  select decrypted_secret into v_token from vault.decrypted_secrets where name = 'telegram_bot_token';
  if new.user_id is not null then
    select email into v_email from auth.users where id = new.user_id;
  end if;
  perform net.http_post(
    url := 'https://api.telegram.org/bot' || v_token || '/sendMessage',
    body := jsonb_build_object('chat_id', public.telegram_chat_id(), 'text', left(format(
      E'🏢 Yangi buyurtma №%s\nTashkilot: %s\nSTIR: %s\nMas''ul shaxs: %s\nTelefon: %s\nManzil: %s\nTil: %s\nKabinet: %s\n\nPozitsiyalar:\n%s%s',
      new.id, new.org, nullif(new.inn, ''), new.contact_name, new.phone, nullif(new.address, ''),
      upper(new.lang), coalesce(v_email, 'kirmagan'), new.request_text,
      case when new.attachment_name is not null then E'\n\n📎 Fayl: ' || new.attachment_name else '' end
    ), 4000)),
    headers := '{"Content-Type": "application/json"}'::jsonb,
    timeout_milliseconds := 20000
  );
  if new.attachment_path is not null then
    perform net.http_post(
      url := 'https://iwuouayiomygwuoppfob.supabase.co/functions/v1/order-file',
      body := jsonb_build_object('order_id', new.id),
      headers := jsonb_build_object('Content-Type', 'application/json', 'Authorization', 'Bearer ' || (select decrypted_secret from vault.decrypted_secrets where name = 'functions_anon_key')),
      timeout_milliseconds := 100000
    );
  end if;
  return new;
exception when others then
  -- Telegram xatosi buyurtmani yo'qotmasin
  raise warning 'notify_telegram failed: %', sqlstate;
  return new;
end;
$$;
