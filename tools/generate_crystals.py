#!/usr/bin/env python3
"""Original PRIZMA vector artwork. No third-party images, fonts or symbols."""
from pathlib import Path
import math
ROOT = Path(__file__).resolve().parents[1] / 'assets' / 'crystals'
ROOT.mkdir(parents=True, exist_ok=True)
COLORS = ['#eb355e', '#259fe9', '#26bb8b', '#f3b936', '#a066e8']
SHAPES = [
 [(128,18),(155,75),(220,83),(176,131),(188,211),(128,177),(68,211),(80,131),(36,83),(101,75)],
 [(128,15),(223,106),(128,231),(33,106)],
 [(80,22),(176,22),(226,128),(176,228),(80,228),(30,128)],
 [(128+99*math.cos(-math.pi/2+i*math.tau/16),128+99*math.sin(-math.pi/2+i*math.tau/16)) for i in range(16)],
 [(128,15),(194,50),(218,116),(194,206),(128,234),(61,206),(38,116),(61,50)]
]
NAMES = ['ruby','sapphire','emerald','sun','amethyst']
def pts(points): return ' '.join(f'{x:.2f},{y:.2f}' for x,y in points)
art = []
for idx,(name,shape,color) in enumerate(zip(NAMES,SHAPES,COLORS)):
    inner = [(128+(x-128)*.62,128+(y-128)*.62) for x,y in shape]
    s = f'''<defs><linearGradient id="body{idx}" x1="0" y1="0" x2=".65" y2="1"><stop stop-color="#fff9ef"/><stop offset=".15" stop-color="{color}"/><stop offset=".66" stop-color="{color}"/><stop offset="1" stop-color="#151538"/></linearGradient><linearGradient id="shine{idx}" x2=".3" y2="1"><stop stop-color="#fff" stop-opacity=".8"/><stop offset=".48" stop-color="#fff" stop-opacity=".03"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></linearGradient></defs>'''
    s += f'<polygon points="{pts(shape)}" fill="#020b21" transform="translate(0 8)" stroke="#020b21" stroke-width="9" stroke-linejoin="round"/>'
    s += f'<polygon points="{pts(shape)}" fill="url(#body{idx})" stroke="{color}" stroke-width="5" stroke-linejoin="round"/>'
    for i in range(len(shape)):
        j=(i+1)%len(shape)
        palette=['#ffffff','#eefaff','#030724',color,'#ffffff','#050928']
        opacity=[.25,.15,.45,.1,.38,.28][i%6]
        s += f'<polygon points="{pts([shape[i],shape[j],inner[j],inner[i]])}" fill="{palette[i%6]}" opacity="{opacity}"/>'
    s += f'<polygon points="{pts(inner)}" fill="url(#body{idx})" stroke="#fff" stroke-opacity=".32" stroke-width="1.6"/>'
    for i in range(len(inner)):
        s += f'<polygon points="{pts([inner[i],inner[(i+1)%len(inner)],(123,112)])}" fill="{["#fff","#fff","#17214c"][i%3]}" opacity="{[.14,.045,.20][i%3]}"/>'
    s += f'<polygon points="{pts(shape)}" fill="url(#shine{idx})"/>'
    if idx==3:
        s += '<circle cx="128" cy="128" r="51" fill="none" stroke="#fff4bf" stroke-width="3" opacity=".6"/>'
        for i in range(12):
            a=i*math.tau/12
            s += f'<path d="M{128+72*math.cos(a):.2f},{128+72*math.sin(a):.2f} L{128+88*math.cos(a):.2f},{128+88*math.sin(a):.2f}" stroke="#fff1ad" stroke-width="4" stroke-linecap="round" opacity=".6"/>'
    if idx==4:
        s += '<path d="M146 62 C102 72 84 139 139 166 C105 168 81 144 83 115 C85 88 106 63 146 62Z" fill="#fff1ff" opacity=".65"/>'
    s += '<path d="M91 63 L96 82 L115 87 L96 92 L91 111 L86 92 L67 87 L86 82Z" fill="#fff" opacity=".88"/>'
    s += '<path d="M152 41 L159 44 M171 53 L183 63" stroke="#fff" stroke-opacity=".64" stroke-width="4" stroke-linecap="round"/>'
    art.append(s)
    (ROOT / (name+'.svg')).write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 256 256">{s}</svg>')
# Original large power silhouettes: horizontal/vertical arcane rockets, prism and chromatic core.
rocket='<path d="M28 128 L79 99 L79 113 L187 113 L187 88 L234 128 L187 168 L187 143 L79 143 L79 157Z" fill="#dffcff" stroke="#329cb8" stroke-width="5" stroke-linejoin="round"/><path d="M88 122 L181 122" stroke="#fff" stroke-width="6"/><path d="M83 149 L69 176 L118 149" fill="#62dce1"/><path d="M53 120 L19 114 M53 137 L11 145" stroke="#ffd786" stroke-width="6" stroke-linecap="round"/>'
prism='<defs><linearGradient id="prism" x2=".9" y2="1"><stop stop-color="#fff"/><stop offset=".35" stop-color="#cc7dfa"/><stop offset=".7" stop-color="#46e4dc"/><stop offset="1" stop-color="#23548f"/></linearGradient></defs><path d="M128 15 L229 169 L128 236 L27 169Z" fill="url(#prism)" stroke="#f9edff" stroke-width="5"/><path d="M128 15 L128 236 M27 169 L229 169 M128 15 L87 169 L128 236 M128 15 L169 169 L128 236" fill="none" stroke="#fff" stroke-opacity=".55" stroke-width="3"/>'
core='<defs><radialGradient id="core"><stop stop-color="#fff"/><stop offset=".22" stop-color="#fde7ff"/><stop offset=".56" stop-color="#bd80fa"/><stop offset="1" stop-color="#302154"/></radialGradient></defs><circle cx="128" cy="128" r="91" fill="url(#core)" stroke="#e1c3ff" stroke-width="4"/>'
for i,color in enumerate(COLORS):
    a=-math.pi/2+i*math.tau/5
    core+=f'<circle cx="{128+66*math.cos(a):.2f}" cy="{128+66*math.sin(a):.2f}" r="21" fill="{color}" stroke="#fff" stroke-opacity=".7" stroke-width="3"/>'
core+='<path d="M128 97 L139 116 L160 128 L139 139 L128 160 L117 139 L97 128 L117 117Z" fill="#fff"/><ellipse cx="128" cy="128" rx="107" ry="40" fill="none" stroke="#fbe5ff" stroke-opacity=".75" stroke-width="3" transform="rotate(-26 128 128)"/>'
art.extend([rocket,'<g transform="rotate(-90 128 128)">'+rocket+'</g>',prism,core])
(ROOT/'atlas.svg').write_text('<svg xmlns="http://www.w3.org/2000/svg" width="768" height="768" viewBox="0 0 768 768">'+''.join(f'<g transform="translate({(i%3)*256} {(i//3)*256})">{item}</g>' for i,item in enumerate(art))+'</svg>')
(ROOT/'glow.svg').write_text('<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128"><defs><radialGradient id="g"><stop stop-color="#fff" stop-opacity=".6"/><stop offset=".42" stop-color="#fff" stop-opacity=".3"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></radialGradient></defs><circle cx="64" cy="64" r="64" fill="url(#g)"/></svg>')
print('Five original faceted jewels, four power silhouettes, one shared atlas and glow generated')
# Static board decoration is baked once at import, avoiding dozens of rounded
# panel/border draw calls every frame. Coordinates exactly match the 8x9 grid.
frame = '''<defs><linearGradient id="rim" x2=".7" y2="1"><stop stop-color="#e8d3a7"/><stop offset=".3" stop-color="#a69272"/><stop offset=".7" stop-color="#4d6677"/><stop offset="1" stop-color="#dab887"/></linearGradient><linearGradient id="well" x2="0" y2="1"><stop stop-color="#091629"/><stop offset=".7" stop-color="#0f2339"/><stop offset="1" stop-color="#1d3749"/></linearGradient><linearGradient id="edge" x2=".2" y2="1"><stop stop-color="#81a6b6" stop-opacity=".36"/><stop offset="1" stop-color="#375164" stop-opacity=".28"/></linearGradient></defs><rect x="1" y="1" width="498" height="558" rx="24" fill="#162a40" stroke="url(#rim)" stroke-width="2"/><rect x="5" y="5" width="490" height="550" rx="19" fill="#0a152a" stroke="#526d7c" stroke-width="1"/>'''
for i in range(72):
    x, y = 12 + i % 8 * 60, 12 + i // 8 * 60
    frame += f'<rect x="{x}" y="{y}" width="56" height="56" rx="11" fill="url(#well)" stroke="url(#edge)" stroke-width="1"/><path d="M{x+8} {y+54} H{x+48}" stroke="#000" stroke-opacity=".4" stroke-width="1"/>'
for x,y in [(7,7),(493,7),(7,553),(493,553)]:
    frame += f'<path d="M{x} {y-5} L{x+5} {y} L{x} {y+5} L{x-5} {y}Z" fill="#f5d593"/>'
(ROOT/'board-frame.svg').write_text('<svg xmlns="http://www.w3.org/2000/svg" width="1000" height="1120" viewBox="0 0 500 560">'+frame+'</svg>')
