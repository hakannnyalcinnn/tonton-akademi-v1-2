#!/usr/bin/env python3
"""Bounded real-engine authoring gate. Drafts never enter campaign automatically."""
import argparse,json,subprocess,os,sys
from pathlib import Path
from level_generator import ROOT,generate,difficulty,similarity,RULES
p=argparse.ArgumentParser();p.add_argument('--world',type=int,required=True);p.add_argument('--start',type=int,required=True);p.add_argument('--end',type=int,required=True);p.add_argument('--seeds',type=int,default=3);p.add_argument('--output',type=Path,required=True);p.add_argument('--draft',type=Path);p.add_argument('--timeout',type=int,default=600);a=p.parse_args()
if a.seeds<1 or a.seeds>10:p.error('use 1–10 initial seeds; expand only reviewed risks')
folder=ROOT/'build/generator';folder.mkdir(parents=True,exist_ok=True)
draft=a.draft or folder/f'draft-{a.start}-{a.end}.json'
if not a.draft:draft.write_text(json.dumps(generate(a.world,a.start,a.end),ensure_ascii=False,indent=2)+'\n')
audit=folder/f'audit-{a.start}-{a.end}.json';log=folder/f'audit-{a.start}-{a.end}.log'
with log.open('w') as stream:
 try:run=subprocess.run(['bash','tools/godot.sh','--headless','--audio-driver','Dummy','--script','tests/generator_audit.gd','--',str(draft.resolve()),str(audit.resolve()),'largest,objective,powers,obstacles,lookahead',str(a.seeds)],cwd=ROOT,stdout=stream,stderr=subprocess.STDOUT,timeout=a.timeout)
 except subprocess.TimeoutExpired:sys.exit('TIMEOUT: no candidate accepted; inspect '+str(log))
if run.returncode:sys.exit('Engine audit failed; no candidate accepted. '+str(log))
data=json.loads(audit.read_text());errors=[]
for d,r in zip(data['levels'],data['rows']):
 if int(d['id'])!=int(r['id']):errors.append('audit identity mismatch');continue
 winning=[t for t in r['trials'] if t['won']]
 by_strategy={m:[t for t in r['trials'] if t['strategy']==m] for m in ['largest','objective','powers','obstacles','lookahead']}
 reliable=[m for m,ts in by_strategy.items() if any(t['won'] and t['seed']==int(d['seed']) for t in ts) and sum(t['won'] for t in ts)/len(ts)>=.7]
 if not reliable:errors.append(str(d['id'])+': review layout, goals or moves; no strategy >=70%');continue
 d['generation'].update(status='simulation_reviewed',simulation_strategy=next((m for m in ['objective','lookahead'] if m in reliable),reliable[0]),evidence={'trials':len(r['trials']),'wins':len(winning),'strategies':list(by_strategy),'human_tested':False},difficulty=difficulty(d))
for x,y in zip(data['levels'],data['levels'][1:]):
 score=similarity(x,y)
 if score['score']>RULES['maximum_neighbor_similarity']:errors.append(str(y['id'])+': neighbor similarity exceeds policy')
 y['generation']['neighbor_similarity']=score
if errors:sys.exit('REVIEW REQUIRED (not proof of impossibility): '+ '; '.join(errors))
a.output.parent.mkdir(parents=True,exist_ok=True);a.output.write_text(json.dumps({'version':3,'generator_version':2,'levels':data['levels']},ensure_ascii=False,indent=2)+'\n')
print(f'Accepted {len(data["levels"])} engine-reviewed definitions; human balance and all-seed solvability remain unverified. Log: {log}')
