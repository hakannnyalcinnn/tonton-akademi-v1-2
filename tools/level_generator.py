#!/usr/bin/env python3
"""PRIZMA Level Generator 2.0: reproducible authored templates, not runtime RNG cheats."""
import argparse,copy,hashlib,json,random
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
RULES=json.loads((ROOT/'data/generator-templates.json').read_text())
CATALOG=json.loads((ROOT/'data/mechanic-catalog.json').read_text())
def shape(name,variant):
 patterns={
 'open':[], 'corner-cut':[0,1,6,7,8,15,56,63,64,65,70,71],
 'islands':[3,4,11,12,59,60,67,68], 'window':[27,28,35,36],
 'hourglass':[16,23,24,31,40,47,48,55], 'staircase':[0,1,2,8,9,16,55,62,63,69,70,71],
 'cross':[0,1,6,7,8,9,14,15,56,57,62,63,64,65,70,71],
 'wings':[i for i in range(72) if i%8 in [3,4] and i//8 not in [3,4,5]],
 'corridor':[24,25,30,31,32,33,38,39], 'terraces':[0,7,8,15,16,23,48,55,56,63,64,71]}
 holes=patterns[name]
 if variant%2:holes=[i//8*8+7-i%8 for i in holes]
 if variant%3==2:holes=[(8-i//8)*8+i%8 for i in holes]
 return sorted(set(holes))
def recipes(number,world):
 worlds=json.loads((ROOT/'data/campaign.json').read_text())['worlds']
 metadata=next((w for w in worlds if w['id']==world),{})
 offset=number-metadata.get('start',(world-1)*50+1)+1
 plan=RULES['world_plans'][metadata.get('generation_plan',metadata.get('theme',RULES['default_plan']))]
 for segment in plan:
  if segment['start']<=offset<=segment['end']:return segment['recipes'][(offset-segment['start'])%len(segment['recipes'])]
 raise ValueError('No design segment for this world offset')
def features(d):
 specs=d.get('mechanics',[])+d.get('canyon',[])
 return {'shape':set(d.get('holes',[])), 'placements':{(s['kind'],int(s['index'])) for s in specs}, 'mechanics':set(d.get('recipe',[])), 'targets':set(d['targets']), 'colors':set(d['active_colors']), 'opportunities':set(d.get('powers',{}))}
def similarity(a,b):
 fa,fb=features(a),features(b);parts={}
 for name,weight in RULES['similarity_weights'].items():
  x,y=fa[name],fb[name];parts[name]=len(x&y)/len(x|y) if x|y else 1.0
 return {'score':sum(parts[k]*RULES['similarity_weights'][k] for k in parts),'parts':parts}
def difficulty(d):
 hp=sum({'stone':3,'seed':2,'ice':2,'pin':2,'crate':2}.get(s['kind'],1) for s in d.get('mechanics',[]))
 hp+=sum({'floor':2,'giant':3,'magnet':1,'core':5}[s['kind']] for s in d.get('canyon',[]))
 parts={'goals':len(d['targets'])*4,'durability':hp*2,'restricted_cells':len(d['holes'])*.8,'colors':(len(d['active_colors'])-3)*6,'interaction':max(0,len(d['recipe'])-1)*5,'stages':len(d.get('objective_stages',[]))*3,'move_pressure':d['targets'].get('total',0)/d['moves']}
 return {'score':round(sum(parts.values()),2),'parts':parts}
def build(number,world,seed,revision=0):
 rng=random.Random(seed+revision*7919)
 category=RULES['difficulty_wave'][(number-1)%10]
 if number in [151,155,161,171,181,186,201,211,221,231]:category='easy'
 kinds=recipes(number,world)
 if len(kinds)>1 and sorted(kinds) not in [sorted(c) for c in CATALOG['reviewed_combinations']]:raise ValueError('Unreviewed combination')
 for k in kinds:
  if number<next(e['first_level'] for e in CATALOG['mechanics'] if e['kind']==k):raise ValueError('Mechanic used before tutorial unlock')
 template=RULES['templates'][(number+revision*3)%len(RULES['templates'])]
 if any(k in kinds for k in ['giant','core']):template=['open','corner-cut','terraces'][(number+revision)%3]
 palette=list(range(4 if number%4==0 else 5))
 holes=shape(template,number+revision)
 taken=set(holes);mechanics=[];canyon=[];targets={'total':{'easy':70,'medium':100,'hard':125,'very_hard':155}[category]+(number%7)*3}
 def position(kind):
  candidates=[i for i in range(9,63) if i not in taken]
  if kind in ['giant','core']:candidates=[i for i in candidates if i%8<7 and i<64 and not taken.intersection([i,i+1,i+8,i+9])]
  else:candidates=[i for i in candidates if sum(j not in taken for j in [i-1,i+1,i-8,i+8] if 0<=j<72 and abs(j%8-i%8)+abs(j//8-i//8)==1)>=2]
  if not candidates:raise ValueError('Template cannot hold recipe')
  i=rng.choice(candidates);taken.update([i,i+1,i+8,i+9] if kind in ['giant','core'] else [i]);return i
 for kind in kinds:
  if kind in ['portal','conveyor']:continue
  i=position(kind);s={'kind':kind,'index':i}
  if kind=='dual':s['colors']=[0,1]
  if kind=='chameleon':s.update(sequence=[0,1,2,3],period=2)
  if kind=='lock':s.update(color=number%len(palette),required=12+(number%4))
  if kind=='fountain':s['color']=number%len(palette)
  if kind=='seal':s['sequence']=[number%len(palette),(number+1)%len(palette)]
  if kind=='mirror':s['orientation']='/' if number%2 else '\\'
  if kind=='core':s['shields']=[12,12,10,10]
  (canyon if kind in ['floor','giant','magnet','core'] else mechanics).append(s)
  if kind=='chameleon':
   extra={'kind':kind,'index':position(kind),'sequence':[1,2,3,0],'period':2};mechanics.append(extra)
  objective={'seed':'flowers','ice':'ice','stone':'stones','lock':'locks','dual':'duals','chameleon':'shifts','bridge':'bridges','pin':'pins','vine':'vines','crate':'crates','mirror':'mirrors','fountain':'fountains','bubble':'bubbles','seal':'seals','floor':'floors','giant':'giants','magnet':'magnets','core':'cores'}[kind]
  targets[objective]=2 if kind in ['ice','fountain','chameleon','magnet'] else 1
  if kind=='core':targets.update({f'shield{c}':s['shields'][c] for c in range(4)})
 # Device routes are non-overlapping playable cells; rectangular loops have adjacency at every step.
 rails=[];portals=[]
 if 'conveyor' in kinds:
  possible=[]
  for y in range(1,7):
   for x in range(1,5):
    loop=[y*8+x,y*8+x+1,y*8+x+2,(y+1)*8+x+2,(y+1)*8+x+1,(y+1)*8+x]
    if not taken.intersection(loop):possible.append(loop)
  if not possible:raise ValueError('No safe rail loop')
  route=rng.choice(possible);rails=[{'cells':route,'loop':True}];taken.update(route);targets['conveyors']=6+(number%5)
 if 'portal' in kinds:
  available=[i for i in range(72) if i not in taken]
  entry=rng.choice(available);available.remove(entry)
  # Exit near a gravity edge keeps transfer opportunities without guaranteeing a win.
  exits=[i for i in available if i//8 in [0,8] or i%8 in [0,7]]
  exit=rng.choice(exits or available);portals=[{'entry':entry,'exit':exit}];taken.update([entry,exit])
  # Portal supports the puzzle; no arbitrary transfer goal if this layout cannot guarantee access.
 layout=[]
 for i in range(72):
  choices=[c for c in palette if not(i%8>=2 and layout[i-1]==layout[i-2]==c) and not(i>=16 and layout[i-8]==layout[i-16]==c)]
  layout.append(rng.choice(choices))
 powers={}
 if 'mirror' in kinds:
  m=next(s for s in mechanics if s['kind']=='mirror');j=m['index']//8*8
  if j in taken:j=m['index']//8*8+7
  if j not in taken:powers[str(j)]='rocket_h'
 if 'core' in kinds:
  free=[i for i in range(72) if i not in taken];powers[str(free[0])]='rocket_h';powers[str(free[-1])]='prism'
 moves={'easy':23,'medium':23,'hard':24,'very_hard':26}[category]
 d=dict(definition_version=3,id=number,world_id=world,theme=next((w['theme'] for w in json.loads((ROOT/'data/campaign.json').read_text())['worlds'] if w['id']==world),RULES['default_plan']),seed=seed,layout=layout,active_colors=palette,shape=template,holes=holes,mechanics=mechanics,canyon=canyon,portals=portals,conveyors=rails,recipe=kinds,powers=powers,moves=moves,targets=targets,stars=[0,5000,8500],gravity=True,resonance=True,initial_gravity='down',automatic_storm=True,crystal_wave=True,difficulty=category,name=('Gökyüzü Bulmacası' if world==4 else 'Lav Bulmacası'),tutorial=next(e.get('hint','Hedef ikonlarına dokun.') for e in CATALOG['mechanics'] if e['kind']==kinds[0]),generation={'version':2,'seed':seed,'revision':revision,'template':template,'status':'draft'})
 if number%10==0 and number not in [160,170,180,210,220,230,240]:
  first={k:max(1,v//2) for k,v in targets.items() if k!='cores'}
  d['objective_stages']=[first,targets.copy()]
 if number==200:d.update(name='Bulut Krallığı Finali',moves=28)
 if number==250:d.update(name='Lav Kristalleri Finali',moves=32)
 d['generation']['difficulty']=difficulty(d)
 return d

def generate(world,start,end):
 rows=[]
 for n in range(start,end+1):
  for revision in range(RULES['maximum_revisions']):
   try:d=build(n,world,110000+n*101,revision)
   except ValueError:continue
   score=similarity(rows[-1],d) if rows else {'score':0,'parts':{}}
   if score['score']<=RULES['maximum_neighbor_similarity']:break
  else:raise RuntimeError(f'No sufficiently diverse candidate for {n}')
  d['generation']['neighbor_similarity']=score
  rows.append(d)
 return {'version':3,'generator_version':2,'levels':rows}
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--world',type=int,required=True);p.add_argument('--start',type=int,required=True);p.add_argument('--end',type=int,required=True);p.add_argument('--output',type=Path,required=True);a=p.parse_args()
 data=generate(a.world,a.start,a.end);a.output.parent.mkdir(parents=True,exist_ok=True);a.output.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n');print(f'Generated {len(data["levels"])} DRAFT definitions; real-engine audit required')
