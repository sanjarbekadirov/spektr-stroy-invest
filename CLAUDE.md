# Spektr Stroy Invest: loyiha konteksti

Bu fayl Claude Code uchun. Loyihada ishlashdan oldin to'liq o'qing.

## Muloqot qoidalari

- Foydalanuvchi bilan **o'zbek tilida (lotin yozuvi)** gaplashing.
- Javoblarda va sayt matnlarida **em dash (—) ishlatmang**. O'rniga vergul, ikki nuqta yoki qavs.
- Commit xabarlari o'zbek tilida, qisqa va aniq (masalan: "Katalogga 5 ta yangi mahsulot qo'shildi").
- Fakt o'ylab topmang. Kompaniya haqida bilmagan narsani so'rang yoki "tasdiqlash kerak" deb belgilang.

## Loyiha haqida

- **Mijoz:** «SPEKTR STROY INVEST» MChJ, Toshkent. Foydalanuvchining tog'asining kompaniyasi.
- **Segment:** B2B va B2G. Korxonalar va davlat tashkilotlariga ta'minot. To'lov faqat **pul o'tkazish** (bank orqali), shartnoma asosida.
- **Kompaniyaning ish tili:** asosan rus tili. Sayt UZ / RU (inglizcha 2026-11-20 da olib tashlangan), standart til o'zbek.
- **Pozitsiyalash (brendbukdan):** "Bitta hamkor. To'rt yo'nalish. Bitta shartnoma." Murojaat ohangi: "Hurmatli hamkor", rasmiy, aniq, va'dalarsiz.

## Manzillar

- Jonli sayt (GitHub Pages): https://sanjarbekadirov.github.io/spektr-stroy-invest/
- Repozitoriy: `sanjarbekadirov/spektr-stroy-invest`, branch `main`. `main` ga push qilinsa, sayt 1-2 daqiqada avtomatik yangilanadi.
- Supabase loyihasi: `iwuouayiomygwuoppfob` (https://iwuouayiomygwuoppfob.supabase.co).

## Fayllar

```
index.html                     Butun sayt: HTML + CSS + JS bitta faylda, build bosqichi yo'q
logo.svg, logo-s.svg           Vektor logotip va "S" belgisi (index.html ichiga ham joylangan)
img/catalog/SP-001..112.jpg    Katalog rasmlari, fayl nomi = mahsulot kodi
img/hero/hero-1..3.webp        Bosh sahifa bannerlari (2400 px); hero-N-m.webp: telefon uchun kesilgan varianti
img/dirs/<kalit>.webp          Yo'nalish kartalari fotosi (640x1147, 9:16), kalit = DIRS kaliti
img/promo-N-uz|ru.webp         Hero promo-slayderi, N = 1..3 (21:9, 1568x672); promo-N-uz|ru-m.webp: telefon (1:1). Aksiya o'zgarsa faqat rasmni almashtiring, matn rasmning o'zida. Telefonda tugma joyi slaydning --mt/--ml o'zgaruvchisida
img/partners/*.webp, havas.svg  Hamkorlar logotiplari (balandligi 120 px, shaffof fon). Lentada monoxrom, hover'da asl rang. `PARTNERS` da oq logotip uchun `invert` ("alpha" yoki "bg"), ochiq rangli uchun `tone:"light"`
supabase/schema.sql            profiles, orders jadvallari, RLS, ro'yxatdan o'tish trigger'i
supabase/telegram.sql          Yangi buyurtma -> Telegram guruhi (pg_net + Vault)
supabase/fayl.sql              Buyurtmaga fayl biriktirish: order-files ombori
supabase/ping.sql              ping() funksiyasi: Supabase loyihasi to'xtab qolmasligi uchun
.github/workflows/keepalive.yml  Har 2 kunda ping() ni chaqiradi (faqat bepul tarifda kerak)
supabase/functions/order-file  Edge function: biriktirilgan faylni guruhga hujjat qilib yuboradi
.nojekyll                      GitHub Pages faylni o'zgartirmasdan bersin
```

## index.html xaritasi

Sahifa bo'limlari tartibda (redizayn 2026-11-20): sticky sarlavha (PNG logo, menyu, telefon, UZ/RU, rejim, smeta, kabinet, "Prays-list (XLSX)") -> `#home` hero (tepada to'liq kenglikdagi 3 slaydli promo-slider, ostida H1 va tugmalar) -> `#partners` hamkorlar + 4 KPI -> `#directions` 4 yo'nalish -> `#catalog` (kartochka / B2B jadval rejimi, `ssi_view`) -> `#smeta` "Smetangiz bormi?" banneri (drag & drop fayl + telefon, `orders` ga yoziladi) -> `#how` 4 qadam -> `#request` so'rov formasi -> `#contacts` (ish vaqti, 3 ta bosiladigan kartochka: Telegram, Instagram, e-pochta; ostida to'liq kenglikdagi xarita va manzil qatori) -> `#412A9D` footer. Telefonda pastki menyu paneli bor.

Standart (o'zbekcha) matnlar HTML ichida statik yozilgan (SEO). JS faqat til almashtirilganda yangilaydi. Matnni o'zgartirsangiz, `T.uz` va HTML ichidagi matnni birga yangilang. Redizayn matnlari `T` dan keyingi `Object.assign(T.uz, ...)` blokida.

Prays-list XLSX brauzerda kutubxonasiz yaratiladi (`priceListXlsx`, oddiy ZIP + SpreadsheetML).

Asosiy JS konstantalar (`<script>` boshida, taxminan 640-qatordan):

| Nomi | Vazifasi |
|---|---|
| `SUPABASE` | `url` va `anonKey` (publishable kalit, saytda turishi mumkin) |
| `PARTNERS` | Hamkorlar ro'yxati (10 ta), aylanuvchi lentada chiqadi. `logo` berilsa nom va monogramma o'rniga rasm. Bo'sh bo'lsa `#partners` bo'limi va unga havolalar yashiriladi |
| `PHONE_MAIN` | Xato xabarlaridagi telefon |
| `DIRS` | 4 yo'nalish: `sponge`, `pack`, `chem`, `tools` (rang, ikonka, illyustratsiya, 2 tildagi nom) |
| `U` | O'lchov birliklari: `pack`, `pc`, `pkg`, `lm`, `pair`, `kg` |
| `P` | Katalog: 112 mahsulot. Har biri `{id, dir, u, n:{uz,ru}, s:{uz,ru}}` |
| `T` | Barcha matnlar tarjimasi: `T.uz`, `T.ru`. HTML'da `data-i18n="kalit"` |
| `DIR_PHOTOS` | Fotosi bor yo'nalishlar. Kartaning foto, fon rangi (`--pb`) va pastki gradient rangi (`--pb2`) CSS'da `.dir[data-dir="..."]` da |
| `PAL`, `ART` | Izometrik SVG illyustratsiyalar. Hozir faqat fotosi yo'q yo'nalish uchun zaxira |
| `FILE_TYPES` | Formaga biriktirish mumkin bo'lgan fayl turlari (xlsx, xls, csv, pdf, docx, doc, jpg, png) |
| `SB_SRC`, `SB_SRI` | supabase-js 2.45.4, jsDelivr'dan SRI bilan, faqat kerak bo'lganda yuklanadi |

Yo'nalishlar bo'yicha mahsulotlar: `chem` 59, `sponge` 23, `pack` 19, `tools` 11.

Brauzer xotirasi (`localStorage`): `ssi_lang`, `ssi_theme`, `ssi_list` (so'rov ro'yxati).

### Katalogga mahsulot qo'shish

1. `P` massiviga yangi yozuv: keyingi bo'sh kod (`SP-113`), `dir` 4 kalitdan biri, `u` birlik, `n` va `s` ikki tilda.
2. Rasmni `img/catalog/SP-113.jpg` qilib qo'shing (taxminan 600-800 px, 100 KB atrofida).
3. Yangi yo'nalish yoki birlik kerak bo'lsa, `DIRS` / `U` va `T` dagi matnlarni ham to'ldiring.

### Yangi matn qo'shish

Har bir kalitni `T.uz` va `T.ru` ikkalasiga qo'shing. Biror tilda kalit yo'q bo'lsa, sahifada kalit nomi chiqib qoladi.

## Backend: Supabase

- **Buyurtma oqimi:** forma -> `orders` jadvaliga insert (kirmagan mijoz ham yuborishi mumkin, `user_id` null) -> `on_order_created` trigger'i `notify_telegram()` -> Telegram guruhiga xabar. Fayl bo'lsa, `order-files` omboriga `incoming/` papkasiga yuklanadi va `order-file` funksiyasi guruhga hujjat qilib yuboradi.
- **Telegram:** bot tokeni **faqat Supabase Vault'da** (`telegram_bot_token`). Guruh ID'si `public.telegram_chat_id()` funksiyasida. Guruh ID'si o'zgarsa, faqat shu funksiyani yangilang.
- **Kabinet:** Supabase Auth (email + parol). `profiles` ro'yxatdan o'tganda avtomatik yaratiladi. Mijoz faqat o'z buyurtmalarini ko'radi (RLS).
- **Buyurtma holati:** kompaniya Supabase > Table Editor > `orders` da `status` (`new`, `processing`, `delivered`, `cancelled`) va `amount` (so'mda) ni o'zgartiradi. `delivered` bo'lganlari mijozning "Haridlar" bo'limida chiqadi.
- **SQL tartibi** (yangi loyihada): `schema.sql` -> `telegram.sql` -> `fayl.sql` -> `order-file` funksiyasini joylash. Oldindan: pg_net yoqilgan, Vault'da `telegram_bot_token` va `functions_anon_key`.

## Xavfsizlik qoidalari

- `index.html` ga **hech qachon** bot tokeni, `service_role` kaliti yoki boshqa maxfiy kalit yozmang. Repozitoriy ochiq (public).
- Sxemaga o'zgartirish kiritganda RLS va `grant` larni saqlang. `anon` faqat insert qila oladi, o'qiy olmaydi.
- Forma matn hajmi `orders_size` cheklovi bilan chegaralangan; formadagi `maxlength` ni shunga mos tuting.

## Brend qoidalari (Brendbuk v2.0)

- **Ranglar:** Spektr Binafsha `#412A9D` (asosiy), Tungi `#1C1340`, Signal Sariq `#FFB71B` (faqat aksent: tugma, raqam, belgilash; katta maydonlarda emas), Lavanda `#8B7ED8`, Beton `#ECEAF2`, Po'lat `#6E6A85`, Grafit `#16141F`.
- **Shriftlar:** Manrope (sarlavhalar, 700/800), Inter (matn, raqamlar `tabular-nums`). 2026-11-20 redizaynida foydalanuvchi tanlovi bilan Montserrat o'rniga Manrope.
- **Tokenlar (redizayn):** `--brand-primary #412A9D`, `--brand-primary-dark #2E1C75`, `--brand-accent #FFB71B`, `--bg-surface #F5F4FA`, `--text-main #161324`, `--text-muted #5F5B73`, `--border-subtle #E5E2F0`. Eski o'zgaruvchilar shularga ulangan.
- **Logotip fayllari:** `img/01_Spektr_logo_binafsha_shaffof.png` (sarlavha), `img/02_Spektr_logo_oq_shaffof.png` (footer), `img/08_Spektr_belgi_S_binafsha_shaffof.png` (favicon). Asl fayllar: Desktop/Spektr Stroy Invest/Spektr_logotiplar 2.
- **Logotip:** binafsha, oq (qorong'u fonda) yoki qora variant. Nisbatlarini o'zgartirmang, effekt qo'shmang. Kompaniya nomi yozuvda: **SPEKTR STROY INVEST**.
- **Vizual til:** ulkan "S" belgisi fonda, chizma to'ri (grid), sariq spektr chiziqlari, doira ichidagi chiziqli ikonkalar, izometrik illyustratsiyalar.
- **Qorong'u rejim:** barcha ranglar CSS token orqali (`:root`, `@media (prefers-color-scheme: dark)`, `[data-theme]`). Yangi element qo'shganda literal rang emas, tokenlardan foydalaning.

## Ish tartibi

1. O'zgarishdan oldin: `git pull origin main` (foydalanuvchi GitHub'da to'g'ridan-to'g'ri ham tahrirlaydi).
2. Mahalliy tekshirish: `python3 -m http.server 8000`, keyin http://localhost:8000
3. Har o'zgarishdan keyin tekshiring: telefon kengligi (390 px, gorizontal scroll yo'q), yorug' va qorong'u rejim, ikkala til, konsolda xato yo'q.
4. Commit -> `git push origin main` -> 1-2 daqiqada jonli saytda.

## Ochiq masalalar (foydalanuvchi bilan aniqlashtirish kerak)

- Foydalanuvchi 2026-11-20 da tasdiqlagan da'volar: ish vaqti Du-Ju 09:00-17:00 (sarlavhada, telefon tugmasi yonida; faqat tugma qo'ng'iroq qiladi), 13+ yil, 5 000+ korporativ mijoz, 1 500+ SKU, 1000+ nom, 24 soatda yetkazish, 30 daqiqada hisob, QQS / UzRTSB birja / g'aznachilik, hamkorlar (Enter Engineering, Eriell, NGMK, Uzkabel, Bunyodkor, Deutsche Kabel; 2026-11-20 da qo'shildi: Havas, Tashkent City, Nestone, Humo Arena).
- Katalogda narx yo'q: jadvaldagi "Ulgurji narx (QQS bilan)" ustunida "Tijorat taklifida" turadi.
- Supabase Auth uchun SMTP ulanganmi, tekshirish kerak (busiz tasdiqlash va parol tiklash xatlari bormaydi).
- Kelajakda o'z domeni yoki serverga ko'chirish rejalashtirilgan. Ko'chirilganda Supabase'dagi Site URL va Redirect URLs ni yangilash kerak.
- Supabase bepul tarifda: 7 kun faolsiz tursa loyiha to'xtatiladi (2026-11-17 da shunday bo'lgan). Hozircha `keepalive.yml` uni faol saqlaydi. Pro tarifga o'tish rejalashtirilgan; o'tilgach, workflow va `ping.sql` ni olib tashlash mumkin.
