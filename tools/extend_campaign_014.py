#!/usr/bin/env python3
"""Author only 251–500. Existing packets are never rewritten. Outputs remain drafts until audited."""
import json,importlib.util
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def save(path,data):path.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')
import sys
FORCE="--force-drafts" in sys.argv
worlds=[(6,'Ayışığı Korusu','moon','#a9a8f5','garden',1,[['seed','dual'],['fountain','dual'],['seal','dual'],['seed','ice']]),(7,'Mercan Sarayı','palace','#ffb1cf','ocean',2,[['dual','ice'],['bubble','portal'],['conveyor','portal'],['seed','ice']]),(8,'Yıldız Çölü','desert','#f5c777','canyon',3,[['mirror','stone'],['pin','bridge'],['conveyor','stone'],['chameleon','lock']]),(9,'Aurora Vadisi','aurora','#8ee6e1','cloud',4,[['bubble','portal'],['giant','ice'],['magnet','portal'],['bridge','floor']]),(10,'Zümrüt Harabeleri','ruins','#7ce0aa','garden',1,[['core','stone'],['magnet','conveyor','portal'],['bridge','floor'],['fountain','seal']])]
manifest=json.loads((ROOT/'data/campaign.json').read_text());rules=json.loads((ROOT/'data/generator-templates.json').read_text())
manifest['capacity']={'levels':10000,'worlds':200,'levels_per_world':50,'published_levels':500}
for wid,title,theme,accent,decor,cid,recipes in worlds:
 start=(wid-1)*50+1;end=wid*50
 if not any(w['id']==wid for w in manifest['worlds']):manifest['worlds'].append(dict(id=wid,start=start,end=end,title=title,theme=theme,art=f'res://assets/casual/terrain-{theme}.png',map_style=theme,decor_style=decor,decor_world=cid,generation_plan=theme,accent=accent,reward=title+' Madalyası',reward_id=f'world-{wid}-medal',success_text=title+' ışıldıyor!'))
 path=f'res://data/levels-{start}-{end}.json'
 if not any(p['path']==path for p in manifest['packages']):manifest['packages'].append(dict(path=path,start=start,end=end))
 rules['world_plans'][theme]=[dict(start=1,end=10,recipes=recipes[:2]),dict(start=11,end=30,recipes=recipes),dict(start=31,end=49,recipes=list(reversed(recipes))),dict(start=50,end=50,recipes=[['core','stone']] if wid==10 else [recipes[-1]])]
save(ROOT/'data/campaign.json',manifest);save(ROOT/'data/generator-templates.json',rules)
spec=importlib.util.spec_from_file_location('generator',ROOT/'tools/level_generator.py');g=importlib.util.module_from_spec(spec);spec.loader.exec_module(g)
for wid,title,theme,accent,decor,cid,recipes in worlds:
 start=(wid-1)*50+1;end=wid*50
 existing=ROOT/f'data/levels-{start}-{end}.json'
 if existing.exists() and not FORCE and any(d.get("generation",{}).get("status")=="simulation_reviewed" for d in json.loads(existing.read_text())["levels"]):raise SystemExit("Refusing to overwrite reviewed levels; use --force-drafts for explicit re-authoring")
 doc=g.generate(wid,start,end)
 for d in doc['levels']:
  d['name']=title+(' Finali' if d['id']==end else ' · '+str(d['id']-start+1))
  if d['id']%10==0:
   d['showcase']=True
   if not d.get('objective_stages'):d['objective_stages']=[{k:max(1,v//2) for k,v in d['targets'].items()},dict(d['targets'])]
  if d['id']==end:d['moves']=32 if wid==10 else 28
  d['generation']['authoring_revision']='v0.14.0';d['generation']['human_tested']=False
 save(ROOT/f'data/levels-{start}-{end}.json',doc)
print('Created 250 draft levels in five 50-level packets; first 250 untouched')
