"""Rebuild original Ashfall Crossroads v0.2 mesh/texture assets.
Run from any working directory: python generate_v02.py
Requires: numpy, pillow, scipy, trimesh, shapely
This is an independent, non-destructive art addon. Existing v0.1 files are not modified.
"""
from __future__ import annotations
from pathlib import Path
import math
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont
from scipy.ndimage import gaussian_filter
import trimesh
from trimesh.visual import TextureVisuals
from trimesh.visual.material import PBRMaterial
from shapely.geometry import Polygon
from shapely.ops import triangulate

ROOT=Path(__file__).resolve().parents[1]
TEXTURES=ROOT/'textures'
GEOM=ROOT/'geometry'
for d in [TEXTURES,GEOM]: d.mkdir(parents=True,exist_ok=True)
RNG=np.random.default_rng(22)
S=1024

def noise(scale:int):
    grid=RNG.random((max(4,S//scale),max(4,S//scale)),dtype=np.float32)
    from PIL import Image
    m=Image.fromarray((grid*255).astype('uint8'),'L').resize((S,S),Image.Resampling.BICUBIC)
    return np.asarray(m,dtype=np.float32)/255

def fnoise():
    return (.32*noise(260)+.24*noise(130)+.18*noise(64)+.13*noise(26)+.08*noise(7)+.05*RNG.random((S,S))).astype(np.float32)

def norm(arr):
    a=np.asarray(arr,dtype=np.float32)
    return np.clip((a-np.quantile(a,.01))/(np.quantile(a,.99)-np.quantile(a,.01)+1e-6),0,1)

def maps(kind):
    n=norm(fnoise()); mid=norm(fnoise()); micro=RNG.random((S,S))
    yy,xx=np.mgrid[0:S,0:S]
    if kind=='concrete':
        weather=norm(.55*n+.2*mid+.25*noise(28))
        tint=np.stack([127-36*weather,125-34*weather,116-33*weather],axis=-1)
        stains=(norm(.75*noise(220)+.25*noise(85))>.82).astype(float)
        vertical=gaussian_filter(stains,sigma=(45,2))
        tint-=vertical[:,:,None]*np.array([32,28,24])
        speck=(micro>.986); tint[speck]=np.array([58,55,48]);
        h=.7*n+.25*mid+.05*micro
        rough=np.clip(.83+.12*(n-.5),.6,.99)
        metal=np.zeros((S,S),dtype=float)
    elif kind=='steel':
        rust_score=norm(.45*n+.4*noise(120)+.15*noise(15))
        rust=(rust_score>.65).astype(float)
        rust=gaussian_filter(rust,1)
        patina=norm(noise(180)*.7+noise(30)*.3)
        paint=np.stack([66+22*patina,76+23*patina,77+21*patina],axis=-1)
        ox=np.stack([104+45*mid,56+35*mid,34+20*mid],axis=-1)
        tint=paint*(1-rust[:,:,None])+ox*rust[:,:,None]
        # gentle vertical drips from corrosion
        streak=gaussian_filter(rust,sigma=(30,1))
        tint-=streak[:,:,None]*np.array([8,12,12])
        h=.35*n+.12*mid+.45*rust+.08*micro
        rough=np.clip(.53+.38*rust+.12*patina,.35,.97)
        metal=.72*(1-rust)+.02*rust
    else:
        rust_score=norm(.52*noise(130)+.28*n+.2*noise(12))
        rust=gaussian_filter((rust_score>.72).astype(float),1.25)
        paint=np.stack([64+18*mid,71+19*mid,68+18*mid],axis=-1)
        oxide=np.stack([112+23*mid,59+25*mid,39+16*mid],axis=-1)
        tint=paint*(1-rust[:,:,None])+oxide*rust[:,:,None]
        # Subtle linear rolling marks; real corrugation remains mesh geometry.
        roll=np.sin(xx*2*np.pi/94)*.08
        h=.44*n+.22*mid+.28*rust+roll+.06*micro
        rough=np.clip(.6+.33*rust+.1*mid,.44,.99)
        metal=.67*(1-rust)+.02*rust
    tint=np.clip(tint+((micro-.5)*11)[:,:,None],0,255).astype('uint8')
    height=np.asarray(h,dtype=np.float32)
    dy,dx=np.gradient(gaussian_filter(height,.65))
    strength=2.2 if kind=='concrete' else 1.3
    nx=-strength*dx; ny=-strength*dy; nz=np.ones_like(nx)
    leng=np.sqrt(nx*nx+ny*ny+nz*nz)
    normals=np.stack([nx/leng,ny/leng,nz/leng],axis=-1)
    normals=np.uint8(np.clip((normals*.5+.5)*255,0,255))
    orm=np.stack([np.full_like(rough,255.),rough*255,metal*255],axis=-1).astype('uint8')
    def save(suffix,img):
        Image.fromarray(img,'RGB').save(TEXTURES/f'{kind}_{suffix}.png',optimize=True)
    save('albedo',tint);save('normal',normals);save('orm',orm)
    print(f'Created {kind} texture set')

for kind in ['concrete','steel','roof']:
    maps(kind)

MATS={}
for kind in ['concrete','steel','roof']:
    base=Image.open(TEXTURES/f'{kind}_albedo.png').convert('RGB')
    normal=Image.open(TEXTURES/f'{kind}_normal.png').convert('RGB')
    orm=Image.open(TEXTURES/f'{kind}_orm.png').convert('RGB')
    MATS[kind]=PBRMaterial(name=f'ashfall_v02_{kind}',baseColorTexture=base,normalTexture=normal,metallicRoughnessTexture=orm,occlusionTexture=orm,baseColorFactor=[255,255,255,255],metallicFactor=1.0,roughnessFactor=1.0)

scene=trimesh.Scene()

def add_mesh(name,mesh,kind,uv=None):
    if uv is None:
        v=np.asarray(mesh.vertices)
        uv=np.column_stack((v[:,0]*.4, v[:,1]*.4))
    mesh.visual=TextureVisuals(uv=np.asarray(uv,dtype=float),material=MATS[kind])
    scene.add_geometry(mesh,node_name=name,geom_name=name)

def box(name, extents,center,kind='steel'):
    mesh=trimesh.creation.box(extents=extents)
    mesh.apply_translation(center)
    add_mesh(name,mesh,kind)

def rod(name, pt1, pt2, radius=.011, kind='steel', sections=10):
    a=np.array(pt1,dtype=float);b=np.array(pt2,dtype=float)
    vec=b-a
    mesh=trimesh.creation.cylinder(radius=radius,height=np.linalg.norm(vec),sections=sections)
    rot=trimesh.geometry.align_vectors([0,0,1],vec/np.linalg.norm(vec))
    mesh.apply_transform(rot)
    mesh.apply_translation((a+b)/2)
    add_mesh(name,mesh,kind)

# Wall 4m wide x 3.2m high x .24m thick, local origin center-bottom.
# The top-right region is genuinely missing; notch follows an irregular fractured edge.
outline=[(-2,0),(2,0),(2,1.67),(1.88,1.76),(1.78,1.93),(1.83,2.05),(1.64,2.2),(1.57,2.42),(1.38,2.48),(1.5,2.69),(1.34,2.79),(1.18,2.87),(1.03,3.2),(-2,3.2)]
p=Polygon(outline)
triangles=[]
for tri in triangulate(p):
    if p.covers(tri.representative_point()) and p.covers(tri):
        points=list(tri.exterior.coords)[:3]
        triangles.append(points)
verts=[];faces=[];uv=[]
for t in triangles:
    for z,reverse in [(.12,False),(-.12,True)]:
        start=len(verts)
        pts=t[::-1] if reverse else t
        for x,y in pts:
            verts.append((x,y,z))
            uv.append(((x+2)*.45,y*.45))
        faces.append([start,start+1,start+2])
for i in range(len(outline)):
    x,y=outline[i]; X,Y=outline[(i+1)%len(outline)]
    st=len(verts)
    verts.extend([(x,y,-.12),(X,Y,-.12),(X,Y,.12),(x,y,.12)])
    ulen=math.hypot(X-x,Y-y)*.5
    uv.extend([(0,0),(ulen,0),(ulen,.12),(0,.12)])
    faces.extend([[st,st+1,st+2],[st,st+2,st+3]])
wall=trimesh.Trimesh(vertices=np.array(verts),faces=np.array(faces),process=False)
add_mesh('DamagedConcreteStructuralCore',wall,'concrete',uv=uv)
# Exposed rusty reinforcement ends extend beyond fractured concrete.
for ind,(x,y1,y2) in enumerate([(1.35,1.22,3.05),(1.72,1.05,2.56),(1.94,.72,2.07)]):
    rod(f'ExposedRebarVertical_{ind}',(x,y1,.018),(x,y2,.018),radius=.012,sections=10)
for ind,(y,x1,x2) in enumerate([(1.9,.9,2.09),(2.32,.65,1.81)]):
    rod(f'ExposedRebarHorizontal_{ind}',(x1,y,.012),(x2,y,.012),radius=.01,sections=10)
# Fracture cracks etched as thin dark lines at the front surface. Geometry is tiny but visible close up.
for j,pts in enumerate([
 [(-1.85,2.82),(-1.53,2.68),(-1.42,2.37),(-1.15,2.29)],
 [(-.9,3.09),(-.69,2.87),(-.63,2.56),(-.47,2.42),(-.38,2.02)],
 [(.88,3.15),(.71,2.91),(.58,2.84),(.63,2.58),(.49,2.39)],
 [(1.82,1.78),(1.55,1.65),(1.39,1.72),(1.19,1.6),(.97,1.42)],
 [(.75,.91),(.59,1.07),(.43,1.06),(.27,1.18)],
 [(-1.3,.65),(-1.18,.92),(-.94,1.03),(-.85,1.21)],
]):
    for k in range(len(pts)-1):
        a,b=pts[k:k+2]
        rod(f'Crack_{j}_{k}',(a[0],a[1],.129),(b[0],b[1],.129),radius=.0039,kind='concrete',sections=5)
# Rusty fastener caps embedded near some surviving edge.
for j,(x,y) in enumerate([(-1.81,.21),(-1.81,3.02),(.8,.22),(.93,2.76)]):
    rod(f'RecessFastener_{j}',(x,y,.131),(x,y,.149),radius=.021,sections=10)
scene.export(GEOM/'damaged_wall_4m_v02.glb')
print('Created damaged wall GLB')

# Door leaf: finished hard-surface details and PBR texture, original shape.
scene=trimesh.Scene()
box('DoorCore',(1.19,2.36,.07),(.61,1.19,0),'steel')
for x in [.055,1.165]:
    box(f'EdgeChannel_{x}',(.038,2.34,.125),(x,1.19,0),'steel')
for y in [.06,2.32]:
    box(f'HorizontalFold_{y}',(1.16,.042,.122),(.61,y,0),'steel')
# Recessed pressings and stiffeners.
for x in [.2,.62,1.04]:
    box(f'VerticalRib_{x}',(.033,1.61,.019),(x,1.32,-.047),'roof')
for y in [.42,1.65,2.08]:
    box(f'Bracing_{y}',(1.0,.032,.023),(.61,y,-.052),'roof')
box('SteelKickPlate',(1.03,.41,.009),(.61,.30,.045),'roof')
box('HandleBacking',(.16,.26,.018),(1.04,1.10,.049),'roof')
rod('HandleStem',(1.04,1.1,.053),(1.04,1.1,.131),.025)
rod('HandleGrip',(.91,1.1,.136),(1.10,1.1,.136),.021)
for j,y in enumerate([.28,1.16,2.06]):
    rod(f'HingePin_{j}',(.012,y-.07,0),(.012,y+.07,0),.021)
    box(f'HingeLeaf_{j}',(.095,.14,.018),(.06,y,-.069))
for j,(x,y) in enumerate([(.1,.19),(1.12,.19),(.1,2.20),(1.12,2.20),(.96,.99)]):
    rod(f'Rivet_{j}',(x,y,.042),(x,y,.065),.009,sections=8)
# Upper ventilation slots made from individual raised perforated backing strips.
box('VentBacking',(.84,.24,.016),(.59,1.92,.049),'roof')
for j in range(9):
    x=.24+j*.087
    box(f'VentSeparator_{j}',(.012,.17,.018),(x,1.92,.06),'steel')
scene.export(GEOM/'steel_door_leaf_v02.glb')
print('Created steel door leaf GLB')

for path in sorted(list(TEXTURES.glob('*.png'))+list(GEOM.glob('*.glb'))):
    print(path.relative_to(ROOT), round(path.stat().st_size/1024), 'KB')
