#!/usr/bin/env python3
"""Index original generated atlases without editing pixels; regions preserve alpha."""
from pathlib import Path
import json
import numpy as np
from PIL import Image
from scipy import ndimage
ROOT=Path(__file__).resolve().parents[1]/'assets/casual'
GRIDS={'gems':(3,3),'mechanics':(4,4),'traits':(5,4),'devices':(4,2),'ui':(3,2),'decor':(4,2),'advanced':(4,2)}
result={}
for name,(cols,rows) in GRIDS.items():
 path=ROOT/(name+'.png')
 if not path.exists():continue
 im=Image.open(path).convert('RGBA');alpha=np.asarray(im)[:,:,3]
 labels,num=ndimage.label(alpha>112)
 objects=ndimage.find_objects(labels);regions=[None]*(cols*rows);groups=[[] for _ in regions]
 for i,sl in enumerate(objects,1):
  if sl is None:continue
  yy,xx=sl;area=np.count_nonzero(labels[sl]==i)
  if area<160:continue
  x=(xx.start+xx.stop)/2;y=(yy.start+yy.stop)/2
  col=min(cols-1,int(x/im.width*cols));row=min(rows-1,int(y/im.height*rows))
  groups[row*cols+col].append((area,xx.start,yy.start,xx.stop,yy.stop))
 for i,parts in enumerate(groups):
  assert parts,(name,i,'no isolated sprite found')
  biggest=max(p[0] for p in parts);parts=[p for p in parts if p[0]>=biggest*.005]
  x=max(0,min(p[1] for p in parts)-3);y=max(0,min(p[2] for p in parts)-3)
  right=min(im.width,max(p[3] for p in parts)+3);bottom=min(im.height,max(p[4] for p in parts)+3)
  regions[i]=[x,y,right-x,bottom-y]
 result[name]={'size':[im.width,im.height],'grid':[cols,rows],'regions':regions}
 print(name,len(regions),'regions',im.size)
(ROOT/'regions.json').write_text(json.dumps(result,indent=2)+'\n')
