#!/usr/bin/env python3
"""Original short offline reward, rescue and boss cues; no third-party samples."""
from generate_audio import write
specs={
'rescue':(.42,[(0,659,.16),(.08,988,.2),(.15,1318,.23)],.20,.02),
'boss_hit':(.18,[(0,196,.14),(.02,784,.12)],.22,.17),
'boss_win':(.55,[(i*.065,f,.24) for i,f in enumerate([392,523,659,784,1046])],.20,.08),
'chest':(.45,[(0,262,.2),(.05,523,.23),(.16,1046,.22)],.19,.12),
'star_award':(.20,[(0,880,.13),(.035,1760,.15)],.16,.01),
'world_unlock':(.62,[(i*.075,f,.23) for i,f in enumerate([440,554,659,880,1108,1318])],.17,.03)}
for name,(duration,notes,gain,noise) in specs.items():write(name,duration,notes,gain,noise)
print(f'{len(specs)} original short cues generated')
