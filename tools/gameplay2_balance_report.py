#!/usr/bin/env python3
"""Report actual solver measurements; preserve raw exploratory and corrected runs."""
from pathlib import Path
import csv,json,hashlib
root=Path(__file__).resolve().parents[1];build=root/'build';out=root/'docs/gameplay2';out.mkdir(exist_ok=True)
old={int(l['id']):l for l in json.loads((root/'data/legacy-gameplay-0.8.json').read_text())['levels']}
current={}
for p in sorted((root/'data').glob('levels*.json')):
 for l in json.loads(p.read_text())['levels']:current[int(l['id'])]=l
before={r['level']:r for r in json.loads((build/'gameplay2-balance-before.json').read_text())['levels']}
new={r['level']:r for r in json.loads((build/'gameplay2-balance-balanced-final.json').read_text())['levels']}
held={r['level']:r for r in json.loads((build/'gameplay2-balance-holdout.json').read_text())['levels']}
for row in json.loads((build/'gameplay2-balance-holdout-final.json').read_text())['levels']:held[row['level']]=row
for mode,dest in [('balanced',new),('holdout',held)]:
 for row in json.loads((build/f'gameplay2-balance-{mode}-correction.json').read_text())['levels']:dest[row['level']]=row
 for row in json.loads((build/f'gameplay2-balance-{mode}-correction62.json').read_text())['levels']:dest[row['level']]=row
rows=[]
for n in range(1,101):
 a,b,h=before[n],new[n],held[n];l=current[n];o=old[n]
 rows.append(dict(level=n,difficulty=l['difficulty'],old_moves=int(o['moves']),new_moves=int(l['moves']),old_win_rate=a['win_rate'],new_win_rate=b['win_rate'],holdout_win_rate=h['win_rate'],old_mean_used=a['mean_used'],new_mean_used=b['mean_used'],old_mean_remaining=a['mean_remaining'],new_mean_remaining=b['mean_remaining'],holdout_mean_remaining=h['mean_remaining'],old_targets=o['targets'],new_targets=l['targets'],old_mechanics=o.get('mechanics',[]),new_mechanics=l.get('mechanics',[]),old_powers=o.get('powers',{}),new_powers=l.get('powers',{}),power_creations=b['power_creations'],max_cascade=b['max_cascade'],storms=b['storms'],waves=b['crystal_waves'],cascade_guards=b['cascade_guards']))
def summary(stat):
 return dict(games=2000,wins=sum(r['wins'] for r in stat.values()),win_rate=sum(r['wins'] for r in stat.values())/2000,mean_used=sum(r['mean_used'] for r in stat.values())/100,mean_remaining=sum(r['mean_remaining'] for r in stat.values())/100,minimum_level_win_rate=min(r['win_rate'] for r in stat.values()),storms=sum(r.get('storms',0) for r in stat.values()),waves=sum(r.get('crystal_waves',0) for r in stat.values()),cascade_guards=sum(r.get('cascade_guards',0) for r in stat.values()))
report=dict(method='Eski ve yeni sürümde aynı deterministik açgözlü çözücü kullanıldı. Bölüm başına 20 seed (temel seed+0..19); ayrı kontrol temel seed+1000..1019. Eski motor stratejik manuel yer çekimi kullanır, yeni motor yönü otomatik seçer. RNG ve üretilen tahta kazanma/kaybetme sonucuna göre ayarlanmaz. Bölüm 54 hedefi 186 → 150, bölüm 62 hedefi 208 → 195 düzeltilip iki grup yeniden çalıştırıldı; ilk deney logları korundu. Bu örneklem insan kazanma oranı veya tüm seedlerin çözülebilirlik kanıtı değildir.',before=summary(before),after=summary(new),holdout=summary(held),levels=rows,level_file_sha256={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted((root/'data').glob('levels*.json'))})
(out/'balance.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
with (out/'balance.csv').open('w',newline='') as f:
 fields=list(rows[0]);writer=csv.DictWriter(f,fieldnames=fields,lineterminator="\n");writer.writeheader();writer.writerows({k:json.dumps(v,ensure_ascii=False) if isinstance(v,(dict,list)) else v for k,v in r.items()} for r in rows)
text=['# Bölüm dengesi — Oynanış 2.0','',report['method'],'','| Bölüm | Dalga | Eski → yeni hamle | Eski → yeni ortalama kalan | İlk / ayrı seed kazanma |','|---|---|---|---|---|']
for r in rows:text.append(f"| {r['level']} | {r['difficulty']} | {r['old_moves']} → {r['new_moves']} | {r['old_mean_remaining']:.1f} → {r['new_mean_remaining']:.1f} | {r['new_win_rate']:.0%} / {r['holdout_win_rate']:.0%} |")
text+=['','İlk 10 bölüm öğretici kalır. Sonraki bölümler sekiz bölümlük rahat/orta/orta/zor/rahat/stratejik/kombinasyon/meydan okuma dalgasıyla düzenlenir. Toplama hedefi, renk hedefi, ileri kilit maliyeti ve bazı hazır roket fırsatları veri dosyalarında değişir.','', 'Hamle azaltma oranları tek bir yüzdeye bağlı değildir: eski ölçümlerde çok fazla kalan hamle bulunduğundan bazı bölümlerde önerilen başlangıç yüzdelerinden daha büyük azaltma gerekir. 54. bölümde hamle azaltılmadı; sertleşen hedef 150 kristale ayarlandı.','', 'Ayrı seed grubunda 66, 70 ve 94. bölümler %65 çözücü başarısındadır; bunlar zor/meydan okuma dalgasıdır. Her bölümde örneklenmiş kazanılabilir oyunlar vardır; tüm rastgele tahtaların kazanılabilirliği kanıtlanmış değildir. İnsan ve gerçek Android oynanış testleri gerekir.','', 'Açık kalan eski oyunlar arşivlenmiş eski tanımı/move_budget alanını kullanır. Yeni/replay oyunları bu dengeyi kullanır; yıldızlar, ödüller ve ilerleme silinmez.']
(out/'BALANCE.md').write_text('\n'.join(text)+'\n')
print(json.dumps({k:report[k] for k in ['before','after','holdout']},indent=2))
