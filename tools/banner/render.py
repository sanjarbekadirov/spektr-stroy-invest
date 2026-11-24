#!/usr/bin/env python3
"""Promo-bannerlarni chiqaradi: tools/banner/banner.html + bg/N-d|m.jpg -> img/promo-N-uz|ru[-m].webp

Ishga tushirish (loyiha papkasidan):  python3 tools/banner/render.py        (hammasi)
                                       python3 tools/banner/render.py 4      (faqat 4-banner)
Kerak: Google Chrome va Pillow (python3 -m pip install --user pillow).
Telefon variantlari uchun saytdagi tugma joyini (--mt / --ml) chiqarib beradi: index.html dagi .ps-slide style ga yozing.
"""
import html, re, shutil, subprocess, sys, tempfile
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
SIZES = {"d": (1568, 672), "m": (928, 1160)}
ids = sys.argv[1:] or sorted({p.name.split("-")[0] for p in (ROOT / "tools/banner/bg").glob("*-d.jpg")})

tmp = Path(tempfile.mkdtemp(prefix="banner-"))
work = tmp / "tools/banner"
shutil.copytree(ROOT / "tools/banner", work)
shutil.copytree(ROOT / "fonts", tmp / "fonts")
base = ["--headless=new", "--disable-gpu", "--hide-scrollbars", "--allow-file-access-from-files",
        "--force-device-scale-factor=1", "--virtual-time-budget=4000", f"--user-data-dir={tmp / 'chrome'}"]

for b in ids:
    for l in ("uz", "ru"):
        for s, (w, h) in SIZES.items():
            url = f"{(work / 'banner.html').as_uri()}?b={b}&l={l}&s={s}"
            dom = subprocess.run([CHROME, *base, f"--window-size={w},{h}", "--dump-dom", url],
                                 capture_output=True, text=True, timeout=90).stdout
            m = re.search(r"<body([^>]*)>", dom)
            attrs = dict(re.findall(r'data-(\w+)="([^"]*)"', html.unescape(m.group(1)) if m else ""))
            png = tmp / f"{b}-{l}-{s}.png"
            subprocess.run([CHROME, *base, f"--window-size={w},{h}", f"--screenshot={png}", url],
                           capture_output=True, timeout=90)
            out = ROOT / "img" / f"promo-{b}-{l}{'-m' if s == 'm' else ''}.webp"
            Image.open(png).convert("RGB").crop((0, 0, w, h)).save(out, "WEBP", quality=82, method=6)
            note = f"--mt:{attrs.get('mt')}%;--ml:{attrs.get('ml')}%" if s == "m" else f"matn pasti {attrs.get('bottom')}px / {h}px"
            print(f"{out.relative_to(ROOT)}  {out.stat().st_size // 1024} KB  {note}")

shutil.rmtree(tmp, ignore_errors=True)
