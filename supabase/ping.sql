-- Supabase bepul tarifida loyiha to'xtab qolmasligi uchun.
-- .github/workflows/keepalive.yml har 2 kunda shu funksiyani chaqiradi.
-- Hech qanday ma'lumot o'qimaydi va yozmaydi, faqat 'ok' qaytaradi.
create or replace function public.ping()
returns text
language sql
stable
set search_path = ''
as $$ select 'ok'::text $$;

grant execute on function public.ping() to anon;
