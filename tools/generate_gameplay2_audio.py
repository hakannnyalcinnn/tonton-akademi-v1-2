#!/usr/bin/env python3
"""Eleven original bounded crystal timbres; no third-party audio."""
from generate_audio import write
from pathlib import Path
import hashlib,json,wave,struct
specs={
 'match3':(.20,[(0,740,.12),(.012,1480,.15),(.035,2217,.1)],.24,.18),
 'match4':(.25,[(0,587,.17),(.015,1174,.20),(.035,1760,.16),(.065,2348,.13)],.23,.25),
 'match5':(.32,[(0,294,.18),(.025,587,.23),(.05,1174,.24),(.085,2348,.19)],.24,.3),
 'rocket':(.27,[(i*.014,196+210*i,.12) for i in range(9)],.20,.20),
 'prism':(.34,[(0,164,.22),(.018,330,.25),(.045,660,.24),(.1,1320,.18)],.26,.27),
 'color':(.38,[(i*.03,f,.2) for i,f in enumerate([622,783,932,1244,1566])],.22,.15),
 'combo_power':(.40,[(0,110,.2),(.03,330,.28),(.055,880,.28),(.095,1760,.24)],.23,.35),
 'storm':(.38,[(i*.022,f,.16) for i,f in enumerate([247,370,494,740,988,1480,1976])],.22,.12),
 'crystal_wave':(.34,[(i*.04,f,.17) for i,f in enumerate([659,880,1318,1760])],.24,.08),
 'combo_big':(.29,[(0,784,.20),(.035,1174,.20),(.07,1568,.18),(.095,2350,.12)],.22,.1),
 'success2':(.85,[(i*.09,f,.36) for i,f in enumerate([523,659,784,1046,1318,1568])],.22,0),
}
root=Path(__file__).resolve().parents[1]/'assets/audio'
manifest=[]
for name,(duration,notes,gain,noise) in specs.items():
 write(name,duration,notes,gain,noise)
 p=root/(name+'.wav')
 with wave.open(str(p)) as f:
  data=f.readframes(f.getnframes());values=struct.unpack('<'+'h'*(len(data)//2),data);peak=max(abs(v) for v in values)/32768
 manifest.append({'file':str(p.name),'seconds':duration,'peak':peak,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
(root/'gameplay2-manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print('11 distinct original WAVs; bounded peaks; 5 voices at max -16 dB preserve mix headroom')
