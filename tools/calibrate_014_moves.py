#!/usr/bin/env python3
"""New packets only: difficulty margins around actual witnessed completion, never old levels."""
from pathlib import Path
import json,importlib.util
root=Path(__file__).resolve().parents[1];report=json.loads((root/'build/v0140/final-campaign-audit.json').read_text());rows={int(x['id']):x for x in report['rows']};original={int(x['id']):int(x['old_moves']) for x in report['edits']};changes=[]
spec=importlib.util.spec_from_file_location('generator',root/'tools/level_generator.py');g=importlib.util.module_from_spec(spec);spec.loader.exec_module(g)
for start in [251,301,351,401,451]:
 p=root/f'data/levels-{start}-{start+49}.json';doc=json.loads(p.read_text())
 for d in doc['levels']:
  row=rows[d['id']];used=int(row['witness']['used']);margin={'easy':6,'medium':4,'hard':2,'very_hard':1}[d['difficulty']]
  if d['id']%50 in [1,2,3]:margin+=2
  if d['id']%50==0:margin+=5
  previous=d['moves'];d['moves']=min(original.get(d['id'],previous),max(8,used+margin));d['generation']['difficulty']=g.difficulty(d);d['generation']['balance']={'witness_moves':used,'margin':margin,'original_moves':original.get(d['id'],previous),'human_validated':False}
  changes.append(dict(id=d['id'],original=original.get(d['id'],previous),moves=d['moves'],strategy=row['witness']['mode'],winning_moves=used))
 p.write_text(json.dumps(doc,ensure_ascii=False,indent=2)+'\n')
(root/'build/v0140/balance.json').write_text(json.dumps(changes,ensure_ascii=False,indent=2)+'\n')
