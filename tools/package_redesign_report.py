#!/usr/bin/env python3
"""Package real renderer evidence and unmodified measurement logs for review."""
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
import hashlib, html, json, shutil, subprocess
ROOT=Path(__file__).resolve().parents[1]
BUILD=ROOT/'build'
TARGET=BUILD/'prizma-redesign-report.zip'
summary=json.loads((ROOT/'docs/redesign/performance/after-native-touch.json').read_text())
interval=summary['frame_interval_ms']
page=['<!doctype html><html lang="tr"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>PRİZMA 0.7 Görsel Revizyon</title><style>body{font:16px system-ui;background:#fff8ed;color:#35436d;max-width:1100px;margin:auto;padding:20px}figure{margin:0}img{width:100%;max-width:540px;height:auto;border-radius:16px}.pair{display:grid;grid-template-columns:repeat(auto-fit,minmax(250px,1fr));gap:18px;margin-bottom:24px}video{width:100%;max-width:540px}a{color:#8050c0}pre{white-space:pre-wrap}</style><h1>PRİZMA 0.7 — Aydınlık görsel yenileme</h1><p>75 bölüm, motor ve kayıtlar korunur. Özgün kristaller, iki dünya ve 12 mekanik için yeni sanat; kıvrımlı harita, açık HUD ve kısa efektler.</p>']
page.append(f'<p>Son kaynak: 100 geçerli native kaydırma, 100 engellenen ikinci kaydırma, 10 geçersiz takas. Ortalama {1000/interval["mean"]:.2f} FPS; p95 {interval["p95"]:.2f} ms; en büyük kare {interval["max"]:.2f} ms. Godot/Linux llvmpipe yazılım renderer. Gerçek Android cihaz test edilmedi.</p>')
for name,title in [('home','Ana menü'),('garden-map','Bahçe haritası'),('ocean-960','Okyanus, bölüm 51')]:
 page.append(f'<h2>{title}</h2><div class="pair"><figure><figcaption>Önce — 0.6</figcaption><img src="screens/before-{name}.png"></figure><figure><figcaption>Sonra — 0.7</figcaption><img src="screens/after-{name}.png"></figure></div>')
page.append('<h2>Gerçek render animasyonları</h2><video controls src="prizma-casual-animations.mp4"></video><p>30 kare/sn, ses kapalı. Normal, dört/beş eşleşme, güç birleşimi ve renk bombası. Telefon kaydı değildir.</p>')
for name,title in [('garden-game','Bahçe oyun ekranı'),('garden-map-locked','Kilitli harita'),('settings','Ayarlar'),('challenge75','75. bölüm gerçekten kazanıldı'),('mechanic-all-states','Tohum, buz, taş ve renk kilitleri'),('package2-crystals-and-pins','Çift renk, bukalemun, köprü, çivi'),('crate-effect','Sandık'),('portal-effect','Portal'),('mirror-effect','Ayna')]:
 page.append(f'<h2>{title}</h2><img src="screens/after-{name}.png">')
page.append('<h2>Belgeler</h2><p><a href="CASUAL_REDESIGN_REPORT.md">Detaylı rapor</a> · <a href="asset-manifest.json">Varlık listesi ve SHA-256</a> · <a href="automated-test-summary.txt">Test özetleri</a> · <a href="changed-files.txt">Değişen dosyalar</a></p><p>Ham ölçümler performance/; gerçek test çıktıları logs/ klasöründe. Birincil 4 sanat ölçümü son iki küçük yıldız/ikon yerleşme düzeltmesinden öncedir; son native ölçüm ve APK son kaynakla çalıştırıldı. Kaynak SHA-256 kayıtları performance/measurement-provenance.json içindedir. Bu aşamada sonraki geliştirmeye geçilmedi.</p></html>')
entries={}
def add(path,name):
 assert path.is_file(),path
 entries[name]=path
for p in (ROOT/'docs/redesign/screens').glob('*.png'):add(p,'screens/'+p.name)
for p in (ROOT/'docs/redesign/performance').glob('*'):add(p,'performance/'+p.name)
for p in ['asset-manifest.json','automated-test-summary.txt','unchanged-engine.json']:add(ROOT/'docs/redesign'/p,p)

add(BUILD/'prizma-casual-animations.mp4','prizma-casual-animations.mp4')
add(BUILD/'prizma-runtime.sha256','prizma-runtime.sha256')
add(BUILD/'prizma-match3.apk.sha256','prizma-match3.apk.sha256')
logs=['test-results.log','persistence-write.log','persistence-read.log','quality-results.log','swipe-stress.log','mechanic_tests.log','mechanic_ui_tests.log','package2_tests.log','package2_levels.log','package2_ui.log','package4_tests.log','ocean_levels.log','package4_ui.log','casual-ui-final.log','casual-package2-ui-final.log','casual-package4-ui-final.log','casual-final-capture.log','casual-mechanic-capture.log','casual-trait-capture.log','casual-animation-final.log','casual-touch-release-perf.log','casual-apk-final-validation.log','casual-build.log']
for name in logs:
 p=BUILD/name
 if p.is_file():add(p,'logs/'+name)
# Additional complete renderer/aspect/state frames, unchanged pixels.
for pattern in ['package4-*.png','mechanic-*.png','package2-*.png']:
 for p in BUILD.glob(pattern):add(p,'renderer/'+p.name)
for p in (ROOT/'assets/casual').glob('*.svg'):add(p,'vector-sources/'+p.name)
changed=subprocess.check_output(['git','status','--porcelain','--untracked-files=all'],cwd=ROOT,text=True)
with ZipFile(TARGET,'w',ZIP_DEFLATED,compresslevel=6) as output:
 for name,p in sorted(entries.items()):output.write(p,name)
 output.writestr('CASUAL_REDESIGN_REPORT.md',(ROOT/'docs/CASUAL_REDESIGN_REPORT.md').read_text().replace('redesign/',''));output.writestr('index.html',''.join(page));output.writestr('changed-files.txt',changed)
with ZipFile(TARGET) as archive:assert archive.testzip() is None
print(json.dumps({'report':str(TARGET.relative_to(ROOT)),'bytes':TARGET.stat().st_size,'sha256':hashlib.sha256(TARGET.read_bytes()).hexdigest(),'files':len(entries)+3}))
