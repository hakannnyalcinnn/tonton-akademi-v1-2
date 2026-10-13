#!/usr/bin/env python3
"""Original deterministic crystal-device audio; no sampled external sounds."""
from generate_audio import write
from pathlib import Path
import json,hashlib
specs={
 'floor_crack':(.18,[(0,920,.1),(.012,1830,.08)],.20,.27),
 'giant_break':(.38,[(0,123,.2),(.015,246,.22),(.05,738,.2),(.1,1476,.16)],.23,.28),
 'core_break':(.62,[(i*.055,f,.28) for i,f in enumerate([262,393,524,786,1048,1572])],.22,.12),
 'magnet':(.25,[(i*.016,400+i*123,.09) for i in range(8)],.20,.05),
 'shuffle':(.28,[(i*.027,f,.12) for i,f in enumerate([1046,784,659,880,1174])],.20,.03)}
root=Path(__file__).resolve().parents[1]/'assets/audio'
manifest=[]
for name,(seconds,notes,gain,noise) in specs.items():
 write(name,seconds,notes,gain,noise)
 p=root/(name+'.wav');manifest.append({'file':p.name,'seconds':seconds,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
(root/'canyon-manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
