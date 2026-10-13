#!/usr/bin/env python3
"""Package unchanged real renderer images and completed tests / raw timings."""
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
import hashlib, html, json, subprocess
ROOT=Path(__file__).resolve().parents[1]
BUILD=ROOT/'build';DOC=ROOT/'docs/package5'
entries={}
for p in DOC.rglob('*'):
 if p.is_file():entries[p.relative_to(DOC).as_posix()]=p
for name in ['prizma-runtime.sha256','prizma-match3.apk.sha256','android-package.txt','package5-build.log','android-export.log','package5-native-performance.log','package5-advanced-performance.log','package5-low-performance.log']:
 p=BUILD/name
 if p.is_file():entries['build/'+name]=p
for p in sorted((ROOT/'assets/casual').glob('advanced*')):
 if p.suffix in ['.png','.import']:entries['original-art/'+p.name]=p
page=['<!doctype html><html lang="tr"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>PRİZMA Paket 5</title><style>body{font:16px system-ui;background:#fff8ed;color:#35436d;max-width:1100px;margin:auto;padding:20px}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:20px}img{width:100%;max-width:540px;border-radius:16px}a{color:#8050c0}figure{margin:0}table{border-collapse:collapse}td,th{padding:8px;border:1px solid #dbcda8}</style><h1>PRİZMA 0.8.0 — Paket 5</h1><p>İkonlu hedef paneli · 16 mekanik · iki dünya · 100 gerçek bölüm. İlk 75 bölümün verileri korunur; 13–16 yalnızca geliştirici sahnelerinde.</p><p><a href="PACKAGE5_REPORT.md">Tam rapor</a> · <a href="test-summary.txt">Gerçek test çıktıları</a> · <a href="changed-files.txt">Değişen dosyalar</a> · <a href="preserved-levels.json">İlk 75 bölüm SHA-256</a></p><p>Bu görüntüler Godot/Linux gerçek render çıktılarıdır. Android cihaz test edilmedi; FPS ve dokunma süreleri telefon sonucu değildir. Ölçüm sınırları tam raporda açıklanır.</p><div class="grid">']
for name,title in [('goals-49','Altı hedefli bölüm 49'),('goal-description-highlight','Açıklama / taş vurgusu'),('goals-76','Portal bölümü'),('goals-81','Canlı Sarmaşık'),('goals-86','Patlayıcı Sandık'),('goals-91','Yönlü Ayna'),('fountain','Boyama Çeşmesi — laboratuvar'),('bubble','Yüzen Baloncuk — laboratuvar'),('conveyor','Konveyör — laboratuvar'),('seal','Şifreli Mühür — laboratuvar'),('final-stage-1','Final hedef aşaması 1'),('final-stage-2','Final hedef aşaması 2'),('final-stage-3','Final hedef aşaması 3'),('ocean-final-win','Gerçek hamlelerle kazanılmış bölüm 100'),('map-100','Tam Okyanus haritası'),('six-goals-1170','19.5:9 hedef/tahta uyumu'),('six-goals-1200','20:9 hedef/tahta uyumu')]:
 file='screens/package5-'+name+'.png'
 assert file in entries,file
 page.append(f'<figure><figcaption>{html.escape(title)}</figcaption><img src="{file}" loading="lazy"></figure>')
page.append('</div><p>Ham JSON ölçümleri performance/, tamamlanmış koşu çıktıları logs/, özgün atlas original-art/ klasöründe. Sonraki geliştirme aşamasına geçilmedi.</p></html>')
out=BUILD/'prizma-package5-report.zip'
with ZipFile(out,'w',ZIP_DEFLATED,compresslevel=6) as archive:
 for name,p in sorted(entries.items()):archive.write(p,name)
 archive.writestr('PACKAGE5_REPORT.md',(ROOT/'docs/PACKAGE5_REPORT.md').read_text().replace('package5/',''))
 archive.writestr('index.html',''.join(page))
with ZipFile(out) as archive:assert archive.testzip() is None
print(json.dumps({'file':str(out),'bytes':out.stat().st_size,'sha256':hashlib.sha256(out.read_bytes()).hexdigest(),'entries':len(entries)+2}))
