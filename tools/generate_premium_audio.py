#!/usr/bin/env python3
"""Two original synthesized short effects, no downloaded audio."""
from generate_audio import write
write('rocket_impact',.14,[(0,190,.18),(.012,880,.18),(.03,1760,.1)],.18,.22)
write('double_color',.34,[(0,110,.18),(.025,330,.18),(.05,622,.2),(.075,932,.2),(.1,1566,.16)],.22,.24)
print('PASS: original rocket impact and double-color timbres generated')
