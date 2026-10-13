#!/usr/bin/env python3
"""Original PRIZMA vector artwork. No downloaded art, fonts or symbols."""
from pathlib import Path
import math
ROOT=Path(__file__).resolve().parents[1]/'assets/mechanics'
ROOT.mkdir(parents=True,exist_ok=True)
art=[]
def add(name,body):
    idx=len(art)
    # Gradient IDs are unique inside the atlas to avoid SVG cross-cell references.
    body=body.replace('id="g"',f'id="g{idx}"').replace('url(#g)',f'url(#g{idx})')
    art.append(body)
    (ROOT/(name+'.svg')).write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 256 256">{body}</svg>\n')
shadow='<ellipse cx="129" cy="228" rx="78" ry="15" fill="#050d1d" opacity=".6"/>'
for hp in [2,1]:
    pod=shadow+'''<defs><linearGradient id="g" x2=".7" y2="1"><stop stop-color="#fff4b6"/><stop offset=".24" stop-color="#cde48b"/><stop offset=".6" stop-color="#63844a"/><stop offset="1" stop-color="#203f3c"/></linearGradient></defs><path d="M127 32 C214 67 226 164 180 211 Q129 247 76 210 C27 165 43 73 127 32Z" fill="url(#g)" stroke="#d8e9a3" stroke-width="5"/><path d="M127 38 C119 87 121 160 129 225 M127 42 Q84 87 69 167 M131 47 Q174 90 190 164" fill="none" stroke="#3b6146" stroke-width="5"/><path d="M86 61 Q70 79 63 111" fill="none" stroke="#f8ffdb" stroke-width="7" stroke-linecap="round"/><path d="M127 30 C120 12 148 9 164 24 Q152 42 127 30" fill="#62c99b" stroke="#d4f2b5" stroke-width="3"/><path d="M77 207 Q39 208 40 177 Q61 177 77 207 M178 208 Q218 211 216 177 Q198 178 178 208" fill="#508a5b" stroke="#bcde95" stroke-width="3"/><path d="M123 110 L144 125 L128 146 L111 129Z" fill="#ffd58d" stroke="#fff2c1" stroke-width="3"/>'''
    if hp==1:pod+='''<path d="M126 45 L111 77 L136 101 L116 136 L140 169 L125 210" fill="none" stroke="#173734" stroke-width="10"/><path d="M124 44 L109 77 L134 101 L114 136 L138 169 L123 210" fill="none" stroke="#f3f6b5" stroke-width="3"/><path d="M115 136 L89 142 L76 165 M139 169 L167 176" fill="none" stroke="#20382f" stroke-width="5"/>'''
    add('seed-'+str(hp),pod)
flower=shadow+'<path d="M126 137 Q146 191 122 230" stroke="#85d79e" stroke-width="11" fill="none"/><path d="M136 187 Q170 146 195 168 Q187 205 136 187 M131 206 Q77 213 70 181 Q105 166 131 206" fill="#63c89a" stroke="#c4f2ac" stroke-width="3"/>'
for k in range(6):
    flower+=f'<g transform="rotate({k*60} 128 107)"><path d="M128 113 C67 91 91 18 128 24 C171 28 176 93 128 113" fill="{["#d39cf8","#ab77df"][k%2]}" stroke="#f8deff" stroke-width="4"/><path d="M126 32 Q105 64 128 103" stroke="#ffecff" stroke-width="3" fill="none" opacity=".7"/></g>'
flower+='<circle cx="128" cy="108" r="28" fill="#fbd382" stroke="#fff3c6" stroke-width="5"/><circle cx="120" cy="98" r="7" fill="#fff6d2"/>'
add('flower',flower)
for hp in [2,1]:
    ice='''<defs><linearGradient id="g" x2=".8" y2="1"><stop stop-color="#e7fbff" stop-opacity=".56"/><stop offset=".35" stop-color="#86e5f6" stop-opacity=".19"/><stop offset="1" stop-color="#3a8ec9" stop-opacity=".52"/></linearGradient></defs><path d="M56 18 L204 27 L236 81 L226 206 L167 239 L36 218 L16 164 L25 66Z" fill="url(#g)" stroke="#bcefff" stroke-opacity=".9" stroke-width="6"/><path d="M56 18 L67 42 L25 66 M204 27 L191 48 L236 81 M226 206 L199 193 L167 239 M36 218 L55 190 L16 164" fill="none" stroke="#d7faff" stroke-width="9" opacity=".75"/><path d="M63 39 L188 48 L214 87 M36 75 L28 153" stroke="#fff" stroke-width="5" stroke-linecap="round" fill="none" opacity=".8"/>'''
    if hp==1: ice+='''<path d="M198 43 L164 81 L178 113 L125 132 L107 182 L62 202 M125 132 L78 100 L31 113 M178 113 L210 146 L205 200" fill="none" stroke="#124973" stroke-width="8" opacity=".72"/><path d="M195 42 L161 80 L175 112 L122 131 L104 181 L59 201 M122 131 L75 99 L28 112 M175 112 L207 145 L202 199" fill="none" stroke="#ecfdff" stroke-width="4"/>'''
    add('ice-'+str(hp),ice)
for hp in [3,2,1]:
    rock=shadow+'''<defs><linearGradient id="g" x2=".8" y2="1"><stop stop-color="#b6bcc7"/><stop offset=".36" stop-color="#718899"/><stop offset="1" stop-color="#283a53"/></linearGradient></defs><path d="M61 27 L175 22 L226 68 L239 169 L188 229 L61 227 L20 170 L28 75Z" fill="url(#g)" stroke="#c1cbd2" stroke-width="4"/><path d="M61 27 L76 62 L28 75 M175 22 L169 56 L226 68 M239 169 L199 167 L188 229 M61 227 L77 185 L20 170" fill="none" stroke="#dce6e8" stroke-opacity=".3" stroke-width="6"/><path d="M76 62 L169 56 L199 167 L77 185Z" fill="#526c81" stroke="#89a1b5" stroke-width="3"/><path d="M113 75 L151 113 L131 150 L98 125Z" fill="#85cac9" stroke="#d4e9e3" stroke-width="3"/><path d="M63 42 L112 39 M39 90 L34 134" stroke="#e1e7e8" stroke-width="5" stroke-linecap="round" opacity=".8"/>'''
    if hp<=2:rock+='<path d="M177 27 L151 65 L163 89 L136 113 L164 158 L154 187 L175 224" fill="none" stroke="#172839" stroke-width="8"/><path d="M175 26 L149 64 L161 88" fill="none" stroke="#b5d2d1" stroke-width="2"/>'
    if hp==1:rock+='<path d="M136 113 L103 98 L77 119 L32 109 M164 158 L200 152 L231 180 M77 119 L89 156 L59 221" fill="none" stroke="#112337" stroke-width="11"/><path d="M133 110 L100 95 L74 116 L29 106 M161 155 L197 149" fill="none" stroke="#c3dcdf" stroke-width="3"/>'
    add('stone-'+str(hp),rock)
for k,color in enumerate(['#f77b90','#70cfff','#68ddaa','#f5cd67','#cc9afa']):
    lock=shadow+f'''<defs><linearGradient id="g" x2=".8" y2="1"><stop stop-color="#fff4cd"/><stop offset=".4" stop-color="#dfb56b"/><stop offset="1" stop-color="#70523b"/></linearGradient></defs><path d="M76 106 V72 C76 5 180 5 180 72 V106 H158 V72 C158 36 98 36 98 72 V106Z" fill="url(#g)" stroke="#f1d8a0" stroke-width="4"/><path d="M63 89 L190 89 L217 132 L197 208 L129 239 L57 207 L37 132Z" fill="url(#g)" stroke="#fee4b0" stroke-width="5"/><path d="M128 100 L191 143 L166 204 L93 204 L65 144Z" fill="{color}" stroke="#fff3da" stroke-width="4"/><path d="M128 100 L115 151 L93 204 M128 100 L140 151 L166 204 M65 144 L191 143" fill="none" stroke="#fff" stroke-opacity=".4" stroke-width="3"/><path d="M116 151 A13 13 0 1 1 140 151 L146 184 H110Z" fill="#253344" stroke="#f7e3b4" stroke-width="3"/><path d="M80 122 L101 107" stroke="#fff" stroke-width="6" stroke-linecap="round"/><circle cx="62" cy="174" r="5" fill="#ffe9b7"/><circle cx="195" cy="174" r="5" fill="#ffe9b7"/>'''
    add('lock-'+str(k),lock)
(ROOT/'atlas.svg').write_text('<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">'+''.join(f'<g transform="translate({i%4*256} {i//4*256})">{s}</g>' for i,s in enumerate(art))+'</svg>\n')
print(f'{len(art)} original mechanic states; 1024px shared atlas')
