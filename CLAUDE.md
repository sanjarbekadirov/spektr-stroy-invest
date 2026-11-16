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
- **Kompaniyaning ish tili:** asosan rus tili. Sayt UZ / RU / EN, standart til o'zbek.
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
supabase/schema.sql            profiles, orders jadvallari, RLS, ro'yxatdan o'tish trigger'i
supabase/telegram.sql          Yangi buyurtma -> Telegram guruhi (pg_net + Vault)
supabase/fayl.sql              Buyurtmaga fayl biriktirish: order-files ombori
supabase/functions/order-file  Edge function: biriktirilgan faylni guruhga hujjat qilib yuboradi
.nojekyll                      GitHub Pages faylni o'zgartirmasdan bersin
```

## index.html xaritasi

Sahifa bo'limlari tartibda: sarlavha (logo, qidiruv, til va rejim tugmalari, so'rov ro'yxati, kabinet) -> `#home` banner-slayder -> `#directions` 4 yo'nalish -> `#catalog` -> `#partners` -> `#request` so'rov formasi -> `#contacts` -> footer. Telefonda pastki menyu paneli bor.

Asosiy JS konstantalar (`<script>` boshida, taxminan 640-qatordan):

| Nomi | Vazifasi |
|---|---|
| `SUPABASE` | `url` va `anonKey` (publishable kalit, saytda turishi mumkin) |
| `PARTNERS` | Hamkorlar ro'yxati. Bo'sh bo'lsa `#partners` bo'limi va unga havolalar yashiriladi |
| `PHONE_MAIN` | Xato xabarlaridagi telefon |
| `DIRS` | 4 yo'nalish: `sponge`, `pack`, `chem`, `tools` (rang, ikonka, illyustratsiya, 3 tildagi nom) |
| `U` | O'lchov birliklari: `pack`, `pc`, `pkg`, `lm`, `pair`, `kg` |
| `P` | Katalog: 112 mahsulot. Har biri `{id, dir, u, n:{uz,ru,en}, s:{uz,ru,en}}` |
| `T` | Barcha matnlar tarjimasi: `T.uz`, `T.ru`, `T.en`. HTML'da `data-i18n="kalit"` |
| `PAL`, `ART` | Brend uslubidagi izometrik illyustratsiyalar (SVG kodda chiziladi) |
| `FILE_TYPES` | Formaga biriktirish mumkin bo'lgan fayl turlari (xlsx, xls, csv, pdf, docx, doc, jpg, png) |
| `SB_SRC`, `SB_SRI` | supabase-js 2.45.4, jsDelivr'dan SRI bilan, faqat kerak bo'lganda yuklanadi |

Yo'nalishlar bo'yicha mahsulotlar: `chem` 59, `sponge` 23, `pack` 19, `tools` 11.

Brauzer xotirasi (`localStorage`): `ssi_lang`, `ssi_theme`, `ssi_list` (so'rov ro'yxati).

### Katalogga mahsulot qo'shish

1. `P` massiviga yangi yozuv: keyingi bo'sh kod (`SP-113`), `dir` 4 kalitdan biri, `u` birlik, `n` va `s` uch tilda.
2. Rasmni `img/catalog/SP-113.jpg` qilib qo'shing (taxminan 600-800 px, 100 KB atrofida).
3. Yangi yo'nalish yoki birlik kerak bo'lsa, `DIRS` / `U` va `T` dagi matnlarni ham to'ldiring.

### Yangi matn qo'shish

Har bir kalitni `T.uz`, `T.ru`, `T.en` uchalasiga qo'shing. Biror tilda kalit yo'q bo'lsa, sahifada kalit nomi chiqib qoladi.

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
- **Shriftlar:** Montserrat (sarlavhalar, 600-900), Inter (matn, 400-700). Google Fonts orqali.
- **Logotip:** binafsha, oq (qorong'u fonda) yoki qora variant. Nisbatlarini o'zgartirmang, effekt qo'shmang. Kompaniya nomi yozuvda: **SPEKTR STROY INVEST**.
- **Vizual til:** ulkan "S" belgisi fonda, chizma to'ri (grid), sariq spektr chiziqlari, doira ichidagi chiziqli ikonkalar, izometrik illyustratsiyalar.
- **Qorong'u rejim:** barcha ranglar CSS token orqali (`:root`, `@media (prefers-color-scheme: dark)`, `[data-theme]`). Yangi element qo'shganda literal rang emas, tokenlardan foydalaning.

## Ish tartibi

1. O'zgarishdan oldin: `git pull origin main` (foydalanuvchi GitHub'da to'g'ridan-to'g'ri ham tahrirlaydi).
2. Mahalliy tekshirish: `python3 -m http.server 8000`, keyin http://localhost:8000
3. Har o'zgarishdan keyin tekshiring: telefon kengligi (390 px, gorizontal scroll yo'q), yorug' va qorong'u rejim, uchala til, konsolda xato yo'q.
4. Commit -> `git push origin main` -> 1-2 daqiqada jonli saytda.

## Ochiq masalalar (foydalanuvchi bilan aniqlashtirish kerak)

- `PARTNERS` bo'sh: hamkorlar logotiplari va ruxsat kerak.
- Ish vaqti (hozir "har kuni 09:00-17:00") tasdiqlanmagan.
- Supabase Auth uchun SMTP ulanganmi, tekshirish kerak (busiz tasdiqlash va parol tiklash xatlari bormaydi).
- Kelajakda o'z domeni yoki serverga ko'chirish rejalashtirilgan. Ko'chirilganda Supabase'dagi Site URL va Redirect URLs ni yangilash kerak.
