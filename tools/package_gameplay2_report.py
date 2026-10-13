#!/usr/bin/env python3
from pathlib import Path
from zipfile import ZipFile,ZIP_DEFLATED
import hashlib,json,html
root=Path(__file__).resolve().parents[1];doc=root/'docs/gameplay2';build=root/'build'
page=['<!doctype html><html lang="tr"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>PRİZMA Oynanış 2.0</title><style>body{font:16px system-ui;background:#fff8ed;color:#35436d;max-width:1100px;margin:auto;padding:20px}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:16px}figure{margin:0}img{width:100%;max-width:540px;border-radius:15px}a{color:#8050c0}</style><h1>PRİZMA 0.9.0 — Oynanış 2.0</h1><p>191.467 kaynak kontrolü başarılı. Otomatik fırtına, Kristal Dalgası, yeni 100 bölüm dengesi ve güçlü efektler. Android cihaz kabul testleri henüz yapılmadı.</p><p><a href="GAMEPLAY2_REPORT.md">Tam rapor</a> · <a href="BALANCE.md">100 bölüm hamle tablosu</a> · <a href="balance.csv">CSV</a> · <a href="PERFORMANCE.md">Kare/işlem ölçümleri ve sınırlar</a> · <a href="test-summary.txt">Gerçek test çıktıları</a> · <a href="changed-files.txt">Dosya listesi</a></p><p>Bütün görüntüler gerçek Godot/Linux renderıdır. Eşleşme karşılaştırmaları aynı kontrollü test tahtasından alınır; kampanya başlangıç tahtası değildir. 49. bölüm ekranları gerçek eski/yeni bölüm verisini kullanır. PNG pikselleri düzenlenmedi.</p><div class="grid">']
items=[('before-board','Eski oyun ekranı / 49. bölüm'),('board','Yeni oyun ekranı / 49. bölüm')]
for name,label in [('match3','Üçlü kırılma'),('match4','Dörtlü / roket doğuşu'),('match5','Beşli / renk bombası doğuşu'),('prism-birth','T / prizma doğuşu')]:items += [('before-'+name,'Eski: '+label),(name,'Yeni: '+label)]
items += [('storm','Otomatik Prizma Fırtınası'),('crystal_wave','Kristal Dalgası'),('color-rocket','Renk bombası + roket'),('board-1170','19.5:9 yerleşim'),('board-1200','20:9 yerleşim')]
for name,label in items:
 file='screens/gameplay2-'+name+'.png';assert (doc/file).is_file(),file
 page.append(f'<figure><figcaption>{html.escape(label)}</figcaption><img src="{file}" loading="lazy"></figure>')
page.append('</div><p>performance/: ham ölçümler ve kapsam. logs/: tamamlanan kaynak testleri, denge deneyleri ve geçmiş başarısız 62. bölüm denemesi. APK kriptografik doğrulama apk-validation.json dosyasındadır. Sonraki aşamaya geçilmedi.</p></html>')
out=build/'prizma-gameplay2-report.zip'
with ZipFile(out,'w',ZIP_DEFLATED,compresslevel=6) as z:
 for p in sorted(doc.rglob('*')):
  if p.is_file():z.write(p,p.relative_to(doc).as_posix())
 z.writestr('GAMEPLAY2_REPORT.md',(root/'docs/GAMEPLAY2_REPORT.md').read_text().replace('gameplay2/',''))
 z.writestr('index.html',''.join(page))
 for name in ['prizma-runtime.sha256','prizma-match3.apk.sha256','android-package.txt','gameplay2-export-verify.log','gameplay2-verified-build.log']:
  z.write(build/name,'build/'+name)
with ZipFile(out) as z:assert z.testzip() is None
print(json.dumps({'file':str(out),'bytes':out.stat().st_size,'sha256':hashlib.sha256(out.read_bytes()).hexdigest()}))
