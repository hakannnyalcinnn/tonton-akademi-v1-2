#!/usr/bin/env python3
from pathlib import Path
from zipfile import ZipFile,ZIP_DEFLATED
import html
root=Path(__file__).resolve().parents[1]
report=root/'docs/v010'
images=sorted((report/'screens').glob('*.png'))
page='<!doctype html><html lang="tr"><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>PRİZMA v0.10.0</title><style>body{font:16px system-ui;background:#f4edff;color:#283355;max-width:1100px;margin:auto;padding:24px}section{display:grid;grid-template-columns:repeat(auto-fit,minmax(240px,1fr));gap:20px}img{width:100%;border-radius:16px}figure{margin:0}a{color:#6644b0}</style><h1>PRİZMA v0.10.0 — Gökkuşağı Kanyonu</h1><p>Gerçek Godot render görüntüleri; Android cihaz ekran görüntüsü değildir. Zemin/dev/mıknatıs/çekirdek efektleri oyunun gerçek hamlelerinden, ücretsiz karıştırma görüntüsü kontrollü hamlesiz test tahtasından alınmıştır.</p><p><a href="REPORT.md">Rapor</a> · <a href="PERFORMANCE.md">Performans</a> · <a href="balance.csv">Bölüm dengesi</a> · <a href="test-summary.txt">Testler</a></p><section>'
for p in images:page+=f'<figure><img loading="lazy" src="screens/{html.escape(p.name)}"><figcaption>{html.escape(p.stem)}</figcaption></figure>'
page+='</section></html>'
(report/'index.html').write_text(page)
with ZipFile(root/'build/prizma-v010-report.zip','w',ZIP_DEFLATED,compresslevel=6) as z:
 for p in report.rglob('*'):
  if p.is_file():z.write(p,'report/'+str(p.relative_to(report)))
 for pattern in ['v010-*.log','v010-signature.txt','prizma-runtime.sha256','prizma-match3.apk.sha256','android-package.txt']:
  for p in (root/'build').glob(pattern):z.write(p,'logs/'+p.name)
print('Report ZIP', (root/'build/prizma-v010-report.zip').stat().st_size,'bytes')
