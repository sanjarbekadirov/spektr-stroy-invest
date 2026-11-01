-- Spektr Stroy Invest: yangi buyurtmalar uchun Telegram xabarnomasi.
-- schema.sql dan keyin ishga tushiring. Oldin kerak:
--   1) Database > Extensions: pg_net yoqilgan bo'lsin;
--   2) Vault: telegram_bot_token nomli secret qo'shilgan bo'lsin.
-- Guruh supergroup'ga aylansa, uning ID'si o'zgaradi: pastdagi chat_id ni yangilang.

-- Tizimga kirmagan mijoz ham so'rov qoldira oladi, lekin o'qiy olmaydi
grant insert (org, inn, contact_name, phone, address, request_text, lang)
  on public.orders to anon;
create policy "orders: anon insert" on public.orders
  for insert to anon with check (user_id is null);

-- Ochiq forma bo'lgani uchun matn hajmi cheklanadi
alter table public.orders add constraint orders_size check (
  char_length(org) <= 200 and char_length(inn) <= 20 and char_length(contact_name) <= 120
  and char_length(phone) <= 30 and char_length(address) <= 300
  and char_length(request_text) between 2 and 5000 and char_length(lang) <= 5
);

create function public.notify_telegram()
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
    body := jsonb_build_object('chat_id', -5581426625, 'text', left(format(
      E'🏢 Yangi so''rov №%s\nTashkilot: %s\nSTIR: %s\nMas''ul shaxs: %s\nTelefon: %s\nManzil: %s\nTil: %s\nKabinet: %s\n\nPozitsiyalar:\n%s',
      new.id, new.org, nullif(new.inn, ''), new.contact_name, new.phone, nullif(new.address, ''),
      upper(new.lang), coalesce(v_email, 'kirmagan'), new.request_text
    ), 4000)),
    headers := '{"Content-Type": "application/json"}'::jsonb,
    timeout_milliseconds := 20000
  );
  return new;
exception when others then
  -- Telegram xatosi buyurtmani yo'qotmasin
  raise warning 'notify_telegram failed: %', sqlstate;
  return new;
end;
$$;
revoke execute on function public.notify_telegram() from public, anon, authenticated;

create trigger on_order_created
  after insert on public.orders
  for each row execute function public.notify_telegram();
