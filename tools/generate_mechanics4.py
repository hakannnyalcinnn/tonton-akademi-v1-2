#!/usr/bin/env python3
"""Original layered vector artwork. No emoji, external assets or fonts."""
from pathlib import Path
import math, wave, struct, random
root=Path(__file__).resolve().parents[1];out=root/'assets/mechanics4';out.mkdir(parents=True,exist_ok=True)
arts=[]
def add(name,body):
 i=len(arts)
 for key in ['metal','wood','energy','glass','leaf']:
  body=body.replace(f'id="{key}"',f'id="{key}{i}"').replace(f'url(#{key})',f'url(#{key}{i})')
 arts.append(body);(out/(name+'.svg')).write_text('<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 256 256">'+body+'</svg>\n')
metal='<linearGradient id="metal" x2=".7" y2="1"><stop stop-color="#f2faff"/><stop offset=".25" stop-color="#b0dce9"/><stop offset=".5" stop-color="#345477"/><stop offset=".72" stop-color="#8fd8e0"/><stop offset="1" stop-color="#e5d9af"/></linearGradient>'
for entry in [True,False]:
 body='<defs>'+metal+'<radialGradient id="energy"><stop stop-color="#070a30"/><stop offset=".55" stop-color="#183064"/><stop offset=".88" stop-color="#3276ad"/><stop offset="1" stop-color="#83ffec"/></radialGradient></defs><ellipse cx="128" cy="219" rx="97" ry="17" fill="#071426" opacity=".6"/><circle cx="128" cy="127" r="106" fill="url(#metal)" stroke="#c7edf4" stroke-width="3"/><circle cx="128" cy="127" r="89" fill="url(#energy)" stroke="#87e9eb" stroke-width="6"/><circle cx="128" cy="127" r="78" fill="none" stroke="#c5a9fb" stroke-width="3" stroke-dasharray="24 20"/><path d="M58 118 Q84 53 151 67 Q196 74 182 125 Q176 158 126 155 Q87 151 107 120 Q121 101 139 118 Q148 135 129 136" fill="none" stroke="#83cef1" stroke-width="7" stroke-linecap="round" opacity=".6"/><path d="M56 57 Q95 22 150 31" fill="none" stroke="#fff" stroke-width="5" stroke-linecap="round"/>'
 for k in range(8):
  angle=k*math.tau/8;x,y=128+99*math.cos(angle),127+99*math.sin(angle)
  body+=f'<path d="M{x-5:.1f} {y:.1f} L{x:.1f} {y-8:.1f} L{x+5:.1f} {y:.1f} L{x:.1f} {y+8:.1f}Z" fill="#befff1" stroke="#20395e" stroke-width="2"/>'
 body+=('<path d="M111 181 H145 M133 170 L145 181 L133 192"' if entry else '<path d="M111 181 H145 M123 170 L111 181 L123 192"')+' fill="none" stroke="#eeffff" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"/>'
 add('portal-entry' if entry else 'portal-exit',body)
body='<defs><linearGradient id="leaf" x2="1" y2="1"><stop stop-color="#d4fca6"/><stop offset=".4" stop-color="#64cd80"/><stop offset="1" stop-color="#173f4c"/></linearGradient></defs><path d="M36 26 Q66 81 40 123 Q14 181 58 220 Q137 252 213 206 Q241 157 210 118 Q182 82 216 33" fill="none" stroke="#183f35" stroke-width="19"/><path d="M36 26 Q66 81 40 123 Q14 181 58 220 Q137 252 213 206 Q241 157 210 118 Q182 82 216 33" fill="none" stroke="url(#leaf)" stroke-width="12"/><path d="M43 46 Q84 5 104 24 Q100 58 46 64 M43 118 Q8 88 9 68 Q43 69 56 105 M59 218 Q62 176 92 172 Q118 194 72 230 M186 221 Q149 191 152 174 Q193 174 209 204 M210 117 Q173 99 169 71 Q206 63 224 104 M216 40 Q185 12 155 24 Q162 62 211 60" fill="url(#leaf)" stroke="#b1e0a1" stroke-width="2"/><path d="M42 147 L28 143 L35 160 M212 166 L227 158 L221 178 M93 232 L104 244 L119 235" fill="#99d9a0" stroke="#214d43" stroke-width="2"/><path d="M44 57 L93 30 M205 49 L165 29 M78 211 L88 182 M179 181 L201 211" stroke="#e5f0ad" stroke-width="2" fill="none"/>'
add('vine',body)
for hp in [2,1]:
 body='<defs>'+metal+'<linearGradient id="wood" x2=".6" y2="1"><stop stop-color="#c5a273"/><stop offset=".5" stop-color="#684459"/><stop offset="1" stop-color="#273342"/></linearGradient><linearGradient id="energy"><stop stop-color="#fff0a5"/><stop offset=".5" stop-color="#fba360"/><stop offset="1" stop-color="#d967d8"/></linearGradient></defs><ellipse cx="128" cy="225" rx="96" ry="17" fill="#050f23" opacity=".6"/><path d="M31 123 Q24 40 125 31 Q222 40 226 121 L218 213 L126 234 L36 214Z" fill="url(#wood)" stroke="#cfb293" stroke-width="5"/><path d="M31 123 L126 149 L226 121 L218 213 L126 234 L36 214Z" fill="#152737" opacity=".35"/><path d="M56 48 Q82 32 90 38 L87 137 L91 226 L68 221 L67 132Z M168 36 L192 47 L185 133 L183 221 L160 228 L160 140Z" fill="url(#metal)" stroke="#ead8b2" stroke-width="3"/><path d="M31 123 L126 149 L226 121 M36 210 L126 230 L218 210" fill="none" stroke="url(#metal)" stroke-width="8"/><path d="M114 140 L136 140 L147 153 L147 180 L125 194 L106 177 L105 155Z" fill="url(#metal)" stroke="#eddab0" stroke-width="3"/><path d="M125 147 L137 163 L125 180 L113 163Z" fill="url(#energy)" stroke="#fff0ba" stroke-width="2"/><path d="M42 85 L59 78 M98 70 L141 57 M100 199 L126 205 M198 168 L213 164" stroke="#d0b5a0" stroke-width="3" opacity=".6"/><circle cx="76" cy="157" r="4" fill="#e3d6b5"/><circle cx="173" cy="157" r="4" fill="#e3d6b5"/>'
 if hp==1:body+='<path d="M44 112 L72 102 L98 128 L114 116 M144 82 L156 99 L144 117 M173 194 L192 185 L209 199" fill="none" stroke="#251626" stroke-width="10"/><path d="M44 112 L72 102 L98 128 L114 116 M144 82 L156 99 L144 117 M173 194 L192 185 L209 199" fill="none" stroke="url(#energy)" stroke-width="4"/>'
 add('crate-'+str(hp),body)
for slash in [True,False]:
 body='<defs>'+metal+'<linearGradient id="glass" x1="0" y1="1" x2="1" y2="0"><stop stop-color="#152855"/><stop offset=".3" stop-color="#ba96f0"/><stop offset=".45" stop-color="#d9faff"/><stop offset=".55" stop-color="#65a2c3"/><stop offset=".8" stop-color="#345581"/><stop offset="1" stop-color="#ddf5ff"/></linearGradient></defs><ellipse cx="128" cy="222" rx="82" ry="13" fill="#060e25" opacity=".65"/><path d="M48 35 H207 L222 49 V208 L204 224 H48 L31 209 V51Z" fill="#142642" stroke="url(#metal)" stroke-width="10"/>'
 a,b=('M60 197 L185 62','M46 198 L183 43 L211 62 L75 216Z') if slash else ('M60 62 L185 197','M46 62 L75 43 L211 198 L183 216Z')
 body+=f'<path d="{b}" fill="url(#glass)" stroke="#c5dfff" stroke-width="5"/><path d="{a}" stroke="#fff" stroke-opacity=".8" stroke-width="4"/><path d="M45 66 V48 H67 M188 211 H208 V188" fill="none" stroke="#f6edcc" stroke-width="5"/><circle cx="46" cy="208" r="5" fill="#b79bea"/><circle cx="208" cy="48" r="5" fill="#adfff4"/>'
 add('mirror-slash' if slash else 'mirror-backslash',body)
(out/'atlas.svg').write_text('<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="512" viewBox="0 0 1024 512">'+''.join(f'<g transform="translate({i%4*256} {i//4*256})">{a}</g>' for i,a in enumerate(arts))+'</svg>\n')
# Four distinct short original synthesized sounds, conservatively normalized.
for key,duration,frequencies in [('portal',.29,[420,630,840]),('vine',.19,[340,510]),('crate',.26,[95,160,280]),('mirror',.13,[1500,2250])]:
 rng=random.Random(key);rate=22050;values=[]
 for i in range(int(rate*duration)):
  t=i/rate;env=min(1,t/.009)*math.exp(-t/(duration*.27));value=sum(math.sin(math.tau*f*(t+.2*t*t))* .12 for f in frequencies)
  value+=(rng.random()*2-1)*(.13 if key=='crate' else .025)*math.exp(-t/.025)
  values.append(int(max(-.7,min(.7,value*env))*32767))
 with wave.open(str(root/'assets/audio'/f'{key}.wav'),'wb') as wav:
  wav.setparams((1,2,rate,0,'NONE','not compressed'));wav.writeframes(struct.pack('<'+'h'*len(values),*values))
print('7 original device/obstacle states, atlas and 4 original sound effects')
