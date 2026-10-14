#!/usr/bin/env python3
"""Reproduce original v0.12.3-r2 feedback tones; no third-party recordings."""
from generate_audio import write

TONES = [
    ('touch', .08, [(0,960,.07)], .08),
    ('swap_motion', .16, [(0,410,.10),(.045,615,.10)], .10),
    ('swap_accept', .12, [(0,740,.09),(.025,1110,.07)], .10),
    ('fall_group', .15, [(0,380,.12),(.04,285,.10)], .07),
    ('land_group', .11, [(0,180,.09),(.02,540,.06)], .08),
    ('preview_open', .17, [(0,550,.10),(.05,825,.11)], .10),
    ('panel_close', .13, [(0,660,.08),(.04,440,.08)], .08),
    ('locked', .14, [(0,260,.12),(.035,240,.08)], .08),
    ('booster_select', .15, [(0,880,.10),(.035,1320,.09)], .10),
]
if __name__ == '__main__':
    for name, duration, notes, gain in TONES:
        write(name, duration, notes, gain)
    print('9 original motion/interface WAV assets generated')
