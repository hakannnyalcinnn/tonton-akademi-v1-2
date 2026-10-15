"""Author minimal additive, reviewable changes; never rewrite the 500 source packets."""
import json
from pathlib import Path
root=Path(__file__).resolve().parents[1]
if (root/'data/evolution-levels.json').exists():raise SystemExit('Reviewed sidecar already exists; preserve authored adjustments.')
c=json.loads((root/'data/campaign.json').read_text());levels={int(d['id']):d for p in c['packages'] for d in json.loads((root/p['path'].removeprefix('res://')).read_text())['levels']}
plans={
'cargo':[61,66,71,86,106,126,156,186,216,246,266,286,316,336,366,386,416,436,456,476,496],
'shutter':[151,161,171,181,191,196,206,236,276,326,376,426,466,486],
'relay':[301,306,311,321,331,341,346,371,411,441,461,481,491],
'key':[351,356,361,371,381,391,396,421,451,471,493],
'balance':[401,406,411,421,431,441,446,461,481,498,500]}
changes={};skipped=[]
for kind,ids in plans.items():
 for n in ids:
  d=levels[n];out=changes.setdefault(str(n),{'evolution':[],'targets':{}})
  used=set(d.get('holes',[]))|{int(m['index']) for m in d.get('mechanics',[])}|{int(k) for k in d.get('powers',{})}|{int(m['index']) for m in out['evolution']}
  for m in d.get('canyon',[]):used.update([int(m['index'])]+([int(m['index'])+a for a in [1,8,9]] if m['kind'] in ['core','giant'] else []))
  for p in d.get('portals',[]):used.update([int(p['entry']),int(p['exit'])])
  for p in d.get('conveyors',[]):used.update(map(int,p['cells']))
  free=[i for i in range(8,64) if i not in used]
  if kind=='cargo':
   candidates=[i for i in free if all(j not in used for j in range(i,72,8))]
   candidates.sort(key=lambda i:(abs(i//8-(7 if n==61 else 3)),(i%8-n%8)%8))
   if not candidates:skipped.append((n,kind));continue
   out['evolution'].append({'kind':'cargo','index':candidates[0]});out['targets']['deliveries']=1
  elif kind=='relay':
   pairs=[(i,i+4) for i in free if i%8<4 and all(j not in used for j in range(i,i+5))]
   if not pairs:skipped.append((n,kind));continue
   a,b=min(pairs,key=lambda p:abs(p[0]//8-4))
   out['evolution'] += [{'kind':'relay','index':i,'group':1} for i in [a,b]];out['targets']['relays']=2
  elif kind=='key':
   if len(free)<2:skipped.append((n,kind));continue
   out['evolution'] += [{'kind':'key','index':free[len(free)//3],'group':1},{'kind':'gate','index':free[-1],'group':1}];out['targets']['gates']=1
  else:
   if not free:skipped.append((n,kind));continue
   m={'kind':kind,'index':free[(n*7)%len(free)]}
   if kind=='balance':m.update(colors=d.get('active_colors',[0,1,2,3,4])[:2],need=3)
   out['evolution'].append(m);out['targets']['shutters' if kind=='shutter' else 'balances']=1
changes={n:d for n,d in changes.items() if d['evolution']}
(root/'data/evolution-levels.json').write_text(json.dumps({'version':1,'levels':changes},indent=2)+'\n')
print('Additive definitions:',len(changes),'mechanics:',sum(len(d['evolution']) for d in changes.values()),'skipped placements:',skipped)
