# Spektr Stroy Invest

«SPEKTR STROY INVEST» MChJ sayti: korxonalar va davlat tashkilotlari uchun ta'minot (B2B · B2G).
Brendbuk v2.0 asosida: Montserrat + Inter, Spektr Binafsha #412A9D, Signal Sariq #FFB71B.

- `index.html`: butun sayt (UZ / RU / EN), katalog, so'rov ro'yxati, so'rov formasi
- `logo.svg`, `logo-s.svg`: vektor logotip va S belgisi
- `img/products/`: katalog rasmlari (`<kod>.jpg`, masalan `QM-01.jpg`). Hozircha Wikimedia Commons'dan olingan namunalar. O'z suratingizni shu nom bilan almashtiring va `credits.html` dan o'sha qatorni o'chiring

Buyurtmalar Supabase'dagi `orders` jadvaliga tushadi va `supabase/telegram.sql` orqali Telegram guruhiga yuboriladi. Bot tokeni faqat Supabase Vault'da saqlanadi, uni saytga yozmang.

## Shaxsiy kabinet

Kabinet (ro'yxatdan o'tish, kirish, buyurtmalar va haridlar tarixi) Supabase bazasida ishlaydi. `SUPABASE` sozlamasi bo'sh bo'lsa, kabinet saytda ko'rinmaydi.

1. [supabase.com](https://supabase.com) da yangi loyiha oching.
2. **SQL Editor** ga `supabase/schema.sql` ni butunlay qo'yib, ishga tushiring.
3. **Authentication > URL Configuration**: Site URL va Redirect URLs ga `https://sanjarbekadirov.github.io/spektr-stroy-invest/` ni yozing.
4. **Authentication > Emails > SMTP Settings**: o'z SMTP'ingizni ulang. Busiz tasdiqlash va parolni tiklash xatlari mijozlarga bormaydi.
5. **Project Settings > API**: Project URL va anon/publishable kalitni `index.html` dagi `SUPABASE` ga yozing. `service_role` kalitini saytga hech qachon yozmang.

Buyurtma holati: **Table Editor > orders** da `status` (`new`, `processing`, `delivered`, `cancelled`) va `amount` (so'mda) ni o'zgartiring. `delivered` bo'lgan buyurtma mijozning "Haridlar" bo'limida ko'rinadi.
