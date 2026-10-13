#!/usr/bin/env python3
"""Original dual/chameleon/bridge crystals and metallic pin artwork, vector sources."""
from pathlib import Path
import math
ROOT=Path(__file__).resolve().parents[1]/'assets/mechanics2';ROOT.mkdir(parents=True,exist_ok=True)
COLORS=['#ef5879','#59c7f5','#46d69e','#f7cf65','#ba85ed']
art=[]
shadow='<ellipse cx="128" cy="226" rx="83" ry="13" fill="#050c1c" opacity=".55"/>'
def add(name,body):
 idx=len(art)
 for key in ['a','b','metal']:
  body=body.replace(f'id="{key}"',f'id="{key}{idx}"').replace(f'url(#{key})',f'url(#{key}{idx})')
 art.append(body)
 (ROOT/(name+'.svg')).write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 256 256">{body}</svg>\n')
def grad(name,color):return f'<linearGradient id="{name}" x2=".8" y2="1"><stop stop-color="#fff8eb"/><stop offset=".27" stop-color="{color}"/><stop offset=".67" stop-color="{color}"/><stop offset="1" stop-color="#152846"/></linearGradient>'
for a in range(5):
 for b in range(a+1,5):
  body=shadow+'<defs>'+grad('a',COLORS[a])+grad('b',COLORS[b])+'</defs>'
  body+='''<path d="M128 13 L204 48 L236 125 L204 207 L128 239 L48 203 L19 125 L52 48Z" fill="url(#a)" stroke="#f4e4ce" stroke-width="5"/><path d="M128 13 L204 48 L236 125 L204 207 L128 239 L105 143Z" fill="url(#b)"/><path d="M52 48 L128 13 L204 48 L183 86 L74 88Z" fill="#fff" opacity=".15"/><path d="M19 125 L52 48 L74 88 L60 140 L48 203Z" fill="#fff" opacity=".2"/><path d="M204 48 L236 125 L204 207 L183 166 L196 121 L183 86Z" fill="#071d37" opacity=".25"/><path d="M48 203 L128 239 L204 207 L183 166 L113 197 L60 140Z" fill="#182039" opacity=".28"/><path d="M52 48 L74 88 L19 125 M74 88 L128 13 M74 88 L183 86 L204 48 M183 86 L196 121 L236 125 M196 121 L183 166 L204 207 M183 166 L113 197 L128 239 M113 197 L60 140 L48 203 M60 140 L74 88 M74 88 L183 166" fill="none" stroke="#fff" stroke-opacity=".45" stroke-width="3"/><path d="M128 13 L105 143 L128 239" fill="none" stroke="#fff6de" stroke-width="5"/><path d="M63 52 L83 39 M40 92 L35 117" fill="none" stroke="#fff" stroke-width="6" stroke-linecap="round"/><path d="M126 96 L142 118 L126 141 L108 120Z" fill="#fff" opacity=".48"/>'''
  add(f'dual-{a}-{b}',body)
for c in range(5):
 body=shadow+'<defs>'+grad('a',COLORS[c])+'''<linearGradient id="metal" x2=".9" y2="1"><stop stop-color="#fff9d2"/><stop offset=".3" stop-color="#d6eaf4"/><stop offset=".66" stop-color="#6a81a1"/><stop offset="1" stop-color="#f2d9a1"/></linearGradient></defs>'''
 body+='''<path d="M128 20 L200 52 L228 123 L200 202 L128 233 L53 202 L25 124 L53 52Z" fill="url(#a)" stroke="#f8e6ff" stroke-width="5"/><path d="M128 20 L155 91 L228 123 L159 156 L128 233 L95 158 L25 124 L96 92Z" fill="#fff" opacity=".17"/><path d="M128 20 L128 233 M25 124 L228 123 M53 52 L159 156 L53 202 M200 52 L95 158 L200 202" fill="none" stroke="#fff" stroke-opacity=".42" stroke-width="3"/><path d="M52 42 L128 11 L204 42 L239 125 L209 205 L128 247 L44 208 L11 125Z" fill="none" stroke="url(#metal)" stroke-width="8"/><path d="M43 60 L28 97 M56 214 L95 230 M212 174 L225 139" stroke="#eef8ff" stroke-width="5" stroke-linecap="round"/><path d="M101 10 L113 39 L128 49 L143 39 L155 10 L144 17 L128 7 L112 17Z" fill="url(#metal)" stroke="#fff2c9" stroke-width="2"/><path d="M45 65 L69 47" stroke="#fff" stroke-width="7" stroke-linecap="round"/>'''
 add('chameleon-'+str(c),body)
body=shadow+'<defs>'+grad('a','#b9c8fb')+'</defs><path d="M128 12 L226 80 L223 182 L128 240 L31 180 L28 78Z" fill="url(#a)" stroke="#fff3da" stroke-width="5"/>'
for k,color in enumerate(COLORS):
 angle=-math.pi/2+k*math.tau/5;nxt=angle+math.tau/5
 x,y=128+99*math.cos(angle),126+99*math.sin(angle);xx,yy=128+99*math.cos(nxt),126+99*math.sin(nxt)
 body+=f'<path d="M128 126 L{x:.2f} {y:.2f} L{xx:.2f} {yy:.2f}Z" fill="{color}" stroke="#fff" stroke-opacity=".6" stroke-width="3"/>'
body+='''<path d="M128 47 L189 139 L128 202 L67 139Z" fill="#e8fbff" fill-opacity=".7" stroke="#fff" stroke-width="4"/><path d="M128 47 L128 202 M67 139 L189 139 M128 47 L104 139 L128 202 M128 47 L150 139 L128 202" stroke="#fff" stroke-width="3" fill="none"/><path d="M128 91 L145 121 L170 136 L143 149 L128 178 L113 149 L86 136 L112 121Z" fill="#fff"/><path d="M47 86 L62 65" stroke="#fff" stroke-width="6" stroke-linecap="round"/>'''
add('bridge',body)
for hp in [2,1]:
 body='''<defs><linearGradient id="metal" x2=".8" y2="1"><stop stop-color="#fff4bc"/><stop offset=".23" stop-color="#c9e2eb"/><stop offset=".45" stop-color="#b5915c"/><stop offset=".7" stop-color="#425b7b"/><stop offset="1" stop-color="#f2d79e"/></linearGradient></defs><path d="M35 32 H78 L72 56 H56 V74 L31 82Z M178 32 H221 L225 80 L200 74 V56 H183Z M31 177 L57 183 V202 H76 L81 226 H35Z M201 181 L225 176 L220 226 H178 L184 201 H201Z" fill="url(#metal)" stroke="#e4d8ad" stroke-width="4"/><path d="M46 47 L211 212 M210 47 L46 210" stroke="#90c9ed" stroke-opacity=".35" stroke-width="3"/><circle cx="45" cy="45" r="9" fill="#5d708a" stroke="#fff0b5" stroke-width="3"/><circle cx="212" cy="45" r="9" fill="#5d708a" stroke="#fff0b5" stroke-width="3"/><circle cx="45" cy="212" r="9" fill="#5d708a" stroke="#fff0b5" stroke-width="3"/><circle cx="212" cy="212" r="9" fill="#5d708a" stroke="#fff0b5" stroke-width="3"/><path d="M63 59 L82 83 M194 60 L177 82 M62 195 L82 174 M194 192 L177 174" stroke="#fff1b8" stroke-width="7" stroke-linecap="round"/>'''
 if hp==1:body+='''<path d="M32 53 L46 65 L40 74 M195 208 L202 222 M213 32 L202 48 L214 60" stroke="#172c45" stroke-width="7" fill="none"/><path d="M34 51 L48 63 M211 30 L200 46" stroke="#fff" stroke-width="2"/><path d="M190 70 L201 81 L191 92 M64 180 L53 169 L64 158" fill="none" stroke="#f7d989" stroke-width="4"/>'''
 add('pin-'+str(hp),body)
(ROOT/'atlas.svg').write_text('<svg xmlns="http://www.w3.org/2000/svg" width="1280" height="1024" viewBox="0 0 1280 1024">'+''.join(f'<g transform="translate({i%5*256} {i//5*256})">{item}</g>' for i,item in enumerate(art))+'</svg>\n')
medal='''<defs><linearGradient id="g" x2=".7" y2="1"><stop stop-color="#fff5cb"/><stop offset=".35" stop-color="#edc266"/><stop offset=".7" stop-color="#926240"/><stop offset="1" stop-color="#f4d691"/></linearGradient></defs><path d="M62 22 L106 15 L119 114 L73 107Z M146 17 L192 23 L179 111 L131 115Z" fill="#64cda6" stroke="#d1eacc" stroke-width="4"/><circle cx="128" cy="147" r="87" fill="url(#g)" stroke="#fff2c6" stroke-width="6"/><circle cx="128" cy="147" r="70" fill="#314e4f" stroke="#f1d59a" stroke-width="4"/><path d="M128 95 L145 131 L181 147 L145 163 L128 202 L111 163 L75 147 L111 131Z" fill="#b4edd8" stroke="#fef3d1" stroke-width="4"/><path d="M58 127 Q41 161 83 192 M199 128 Q216 163 174 193" fill="none" stroke="#e0c078" stroke-width="6"/><path d="M55 145 L42 137 M61 171 L47 172 M67 186 L62 202 M204 145 L218 136 M199 171 L214 174 M187 188 L193 203" stroke="#f2d89e" stroke-width="7" stroke-linecap="round"/>'''
(ROOT/'garden-medal.svg').write_text('<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 256 256">'+medal+'</svg>\n')
print(len(art),'original trait/pin atlas states and garden medal')
