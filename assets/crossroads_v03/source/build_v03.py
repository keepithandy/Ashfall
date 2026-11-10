"""Ashfall Crossroads v0.3 production-intent modular structures.

Generates GLBs from source geometry, using v0.2 authored PBR texture sets.
Requires: numpy, pillow, trimesh. Import exported GLBs into Blender for art iteration.
4m grid, 3.2m walls, X = wall length, Y = up, Z = normal/front.
Does not touch prior kit assets or saves. Run: python build_v03.py
"""
from pathlib import Path
import math
import numpy as np
import trimesh
from trimesh.visual import TextureVisuals
from trimesh.visual.material import PBRMaterial
from PIL import Image, ImageDraw, ImageFont

ROOT=Path(__file__).resolve().parents[1]
V02=ROOT.parent/'crossroads_v02'
GEO=ROOT/'geometry'; TEX=ROOT/'textures'
GEO.mkdir(exist_ok=True, parents=True)
TEX.mkdir(exist_ok=True, parents=True)
MAT={}
for kind in ('concrete','steel','roof'):
    images=[Image.open(V02/'textures'/f'{kind}_{n}.png').convert('RGB') for n in ('albedo','normal','orm')]
    MAT[kind]=PBRMaterial(name=f'Ashfall_{kind}_PBR',baseColorTexture=images[0],normalTexture=images[1],metallicRoughnessTexture=images[2],occlusionTexture=images[2],baseColorFactor=[255,255,255,255],metallicFactor=1.0,roughnessFactor=1.0)

S=trimesh.Scene()
BUCKETS={}
def mesh_add(name, mesh, kind, scale=.50):
    mesh=mesh.copy()
    mesh.unmerge_vertices()
    uv=np.zeros((len(mesh.vertices),2), dtype=float)
    verts=np.asarray(mesh.vertices)
    # Give each face a planar UV projection in actual meters, avoiding smeared floor UVs.
    for fidx, face in enumerate(mesh.faces):
        axis=int(np.argmax(np.abs(mesh.face_normals[fidx])))
        coords=[0,2] if axis==1 else ([0,1] if axis==2 else [2,1])
        uv[np.asarray(face)]=verts[np.asarray(face)][:,coords]*scale
    mesh.visual=TextureVisuals(uv=uv,material=MAT[kind])
    BUCKETS.setdefault(kind, []).append(mesh)

def chamfered_box(size, center, bevel):
    """Closed 44-triangle chamfered cuboid, with physically visible edge highlights.

    Returns a watertight hard-surface mesh. The bevel stays below 1/4 the
    thinnest dimension to keep thin-sheet hardware in proportion.
    """
    half=np.asarray(size, dtype=float)*.5
    b=min(float(bevel),float(min(half))*.46)
    if b < .0004:
        mesh=trimesh.creation.box(extents=size)
        mesh.apply_translation(center)
        return mesh
    verts=[]; tris=[]
    def tri(a,bb,c):
        # Outward-facing triangle winding, even for negative axes.
        a=np.asarray(a,dtype=float); bb=np.asarray(bb,dtype=float); c=np.asarray(c,dtype=float)
        if np.dot(np.cross(bb-a,c-a),(a+bb+c)/3.) < 0:
            bb,c=c,bb
        offset=len(verts)
        verts.extend([a,bb,c]);tris.append((offset,offset+1,offset+2))
    def quad(a,bb,c,d):
        tri(a,bb,c);tri(a,c,d)
    # Six large faces.
    for axis in range(3):
        u,v=[k for k in range(3) if k!=axis]
        for sign in (-1,1):
            corners=[]
            for cu,cv in ((-1,-1),(1,-1),(1,1),(-1,1)):
                q=np.zeros(3);q[axis]=sign*half[axis]
                q[u]=cu*(half[u]-b);q[v]=cv*(half[v]-b)
                corners.append(q)
            quad(*corners)
    # Twelve bevel strips joining neighboring planar faces.
    for axis_a in range(3):
        for axis_b in range(axis_a+1,3):
            k=next(i for i in range(3) if i!=axis_a and i!=axis_b)
            for sa in (-1,1):
                for sb in (-1,1):
                    strips=[]
                    for end in (-1,1):
                        q1=np.zeros(3);q2=np.zeros(3)
                        q1[axis_a]=sa*half[axis_a];q1[axis_b]=sb*(half[axis_b]-b)
                        q2[axis_a]=sa*(half[axis_a]-b);q2[axis_b]=sb*half[axis_b]
                        q1[k]=q2[k]=end*(half[k]-b)
                        strips.extend((q1,q2))
                    quad(strips[0],strips[1],strips[3],strips[2])
    # Eight triangular corner caps.
    for sx in (-1,1):
        for sy in (-1,1):
            for sz in (-1,1):
                signs=np.array([sx,sy,sz]);points=[]
                for axis in range(3):
                    q=signs*(half-b);q[axis]=signs[axis]*half[axis];points.append(q)
                tri(*points)
    m=trimesh.Trimesh(vertices=np.array(verts)+np.asarray(center),faces=np.array(tris),process=False)
    return m

def cube(name, size, pos, kind='concrete'):
    # True small chamfers on most metal items make highlights read under real light.
    # Structural concrete keeps its square silhouette for precise modular snapping.
    if kind in ('steel','roof'):
        mesh=chamfered_box(size,pos,.010)
    else:
        mesh=trimesh.creation.box(extents=size)
        mesh.apply_translation(pos)
    mesh_add(name,mesh,kind)

def rod(name,a,b,radius=.012,kind='steel',sections=10):
    a=np.array(a,dtype=float); b=np.array(b,dtype=float)
    direction=b-a; length=np.linalg.norm(direction)
    if length < 1e-6: return
    mesh=trimesh.creation.cylinder(radius=radius,height=length,sections=sections)
    rot=trimesh.geometry.align_vectors([0,0,1],direction/length)
    mesh.apply_transform(rot)
    mesh.apply_translation((a+b)/2)
    mesh_add(name,mesh,kind)

def reset():
    global S, BUCKETS
    S=trimesh.Scene()
    BUCKETS={}

def export(filename):
    # Merge parts sharing one material: few mesh surfaces and draw calls.
    for kind, parts in BUCKETS.items():
        merged=trimesh.util.concatenate(parts)
        S.add_geometry(merged, geom_name=f"{kind}_combined", node_name=f"{kind}_combined")
    out=GEO/filename
    S.export(out)
    extents=S.bounds[1]-S.bounds[0]
    print(filename, '|',len(S.geometry),'submeshes | extents',np.round(extents,3))

# All standard walls center at X=0, front at +Z, from Y=0 to 3.2m.
# Surface detail is intentional and sparse, rather than random noise geometry.
def wall_edges(seed=0, include_pipes=False):
    # Thin cast-in corner ties, recess caps and periodic anchor fasteners
    for side,x in enumerate((-1.95,1.95)):
        cube(f'CastEndChannel_{side}',(.06,3.18,.018),(x,1.6,.132),'roof')
        for level,y in enumerate((.26,1.58,2.96)):
            rod(f'ConcreteTie_{side}_{level}',(x,y,.138),(x,y,.158),.024,'steel',12)
    cube('FoundationSkirting',(3.96,.12,.046),(0,.09,.143),'steel')
    cube('UpperConcreteEdge',(3.96,.064,.025),(0,3.135,.135),'concrete')
    if include_pipes:
        for x in (-.8,-.68):
            rod('UtilityConduit_'+str(x),(x,.45,.153),(x,2.91,.153),.018,'steel',12)
        cube('JunctionEnclosure',(.28,.34,.12),(-.74,1.65,.205),'steel')
        for level,y in enumerate((.63,1.47,2.42)):
            cube(f'PipeBracket_{level}',(.29,.05,.08),(-.74,y,.17),'roof')

def panel_bolts(label,w,h,z,y0=0):
    for ix,x in enumerate((-w/2+.10,w/2-.10)):
        for iy,y in enumerate((y0+.13,y0+h-.13)):
            rod(f'{label}_fastener_{ix}_{iy}',(x,y,z),(x,y,z+.012),.015,'steel',8)

reset()
cube('ConcreteMass',(4,3.2,.24),(0,1.6,0))
wall_edges(include_pipes=True)
for x in [-1.35,1.1]:
    cube(f'PatchPlate_{x}',(.36,.45,.015),(x,.47,.13),'concrete')
for y in (2.72,2.85):
    cube(f'WaterlineRecess_{y}',(1.75,.012,.009),(.65,y,.129),'roof')
export('wall_solid_4m_v03.glb')

# Window frame opening +/-0.80 x and 0.90..2.25 y.
reset()
cube('PierLeft',(1.2,3.2,.24),(-1.4,1.6,0));cube('PierRight',(1.2,3.2,.24),(1.4,1.6,0))
cube('LowerWindowWall',(1.6,.9,.24),(0,.45,0));cube('Lintel',(1.6,.95,.24),(0,2.725,0))
for i,(size,pos) in enumerate([
    ((.075,1.38,.08),(-.82,1.575,.13)),((.075,1.38,.08),(.82,1.575,.13)),
    ((1.72,.055,.075),(0,.876,.14)),((1.72,.075,.082),(0,2.28,.14)),
    ((.050,1.34,.054),(0,1.57,.15))]):
    cube(f'OuterWindowFrame_{i}',size,pos,'steel')
cube('ExteriorSill',(1.94,.075,.26),(0,.86,.22),'concrete')
cube('TopDripLip',(1.85,.038,.13),(0,2.32,.195),'steel')
for x in (-1.91,1.91):
    for y in (.26,2.92):
        rod(f'WindowTie_{x}_{y}',(x,y,.135),(x,y,.152),.022,'steel',10)
export('wall_window_4m_v03.glb')

# Door: centered opening width 1.4 m, height 2.5 m (fits v0.2 door leaf).
reset()
cube('DoorPierLeft',(1.30,3.2,.24),(-1.35,1.6,0))
cube('DoorPierRight',(1.30,3.2,.24),(1.35,1.6,0))
cube('DoorHeader',(1.4,.7,.24),(0,2.85,0))
for side,x in enumerate((-.69,.69)):
    cube(f'DoorFrameJamb_{side}',(.056,2.48,.12),(x,1.24,.125),'steel')
    for y in (.28,1.13,2.12):
        rod(f'JambFastener_{side}_{y}',(x,y,.20),(x,y,.222),.018,'steel',10)
cube('DoorTopFrame',(1.44,.068,.13),(0,2.47,.125),'steel')
cube('DoorThreshold',(1.35,.032,.22),(0,.016,.095),'roof')
# Do not place continuous skirting across the opening: the existing door must clear it.
for side,x in enumerate((-1.95,1.95)):
    cube(f'PierTie_{side}',(.055,3.18,.024),(x,1.6,.132),'roof')
export('wall_doorway_4m_v03.glb')

# Garage: architectural 4m wall with built-in closed slatted shutter, 3.1m x 2.65m.
reset()
cube('GaragePierLeft',(.47,3.2,.24),(-1.765,1.6,0))
cube('GaragePierRight',(.47,3.2,.24),(1.765,1.6,0))
cube('GarageLintel',(3.06,.53,.24),(0,2.935,0))
cube('ClosedSteelShutter',(3.06,2.66,.063),(0,1.33,.05),'roof')
for n in range(18):
    y=.135+n*.137
    cube(f'ShutterRoll_{n}',(3.03,.045,.035),(0,y,.103),'steel')
for side,x in enumerate((-1.552,1.552)):
    cube(f'Track_{side}',(.075,2.7,.09),(x,1.35,.135),'steel')
    for y in (.3,.9,1.5,2.1,2.57):
        rod(f'ShutterRivet_{side}_{y}',(x,y,.191),(x,y,.207),.016,'roof',10)
cube('ShutterBottomLock',(3.09,.105,.12),(0,.066,.13),'steel')
cube('LatchHousing',(.27,.14,.07),(.0,1.18,.13),'steel')
rod('LatchHandle',(-.14,1.18,.175),(.14,1.18,.175),.025,'steel')
export('wall_garage_4m_v03.glb')

# Floor: 4x4 meter structural slab top at y=0, thickness 0.22 m.
reset()
cube('MainSlab',(3.98,.22,3.98),(0,-.11,0),'concrete')
for x in (-1.94,1.94):
    cube(f'EdgeReinforcement_{x}',(.035,.16,3.90),(x,-.11,0),'roof')
for z in (-1.94,1.94):
    cube(f'ExpansionJointEdge_{z}',(3.9,.012,.024),(0,.002,z),'steel')
for n,(x,z) in enumerate([(-1.12,-1.04),(1.05,-1.48),(-.38,1.28)]):
    cube(f'CastRepairStrip_{n}',(.48,.006,.17),(x,.003,z),'roof')
export('floor_slab_4m_v03.glb')

# Roof: profiled corrugated sheet over beams. Coordinates centered in XZ.
reset()
cube('RoofUnderlay',(4,.058,4),(0,.0,0),'roof')
for i,x in enumerate(np.arange(-1.96,2.0,.245)):
    cube(f'CorrugatedCrown_{i}',(.086,.063,4.0),(float(x),.058,0),'roof')
    for z in (-1.78,0,1.78):
        rod(f'RoofScrew_{i}_{z}',(float(x),.094,float(z)),(float(x),.106,float(z)),.012,'steel',8)
for z in (-1.96,1.96):
    cube(f'EdgeFlashing_{z}',(4,.055,.077),(0,.063,z),'steel')
for x in (-1.84,1.84):
    cube(f'Purlin_{x}',(.10,.16,4),(x,-.11,0),'steel')
export('roof_panel_4m_v03.glb')

# Steel workbench: 2.2m x 0.75m, with lower storage rack and drawers.
reset()
cube('WornWorktop',(2.18,.075,.76),(0,.93,0),'roof')
for x in (-1.02,1.02):
    for z in (-.31,.31):
        cube(f'BenchLeg_{x}_{z}',(.065,.88,.065),(x,.44,z),'steel')
for y in (.19,.81):
    for z in (-.31,.31):
        cube(f'CrossBrace_{y}_{z}',(2.12,.035,.046),(0,y,z),'steel')
cube('LowerShelf',(2.06,.025,.64),(0,.23,0),'roof')
for x in (-.72,0,.72):
    cube(f'StorageDrawer_{x}',(.65,.30,.52),(x,.72,-.025),'steel')
    cube(f'DrawerPull_{x}',(.31,.02,.036),(x,.69,.261),'roof')
for i,x in enumerate((-1.02,1.02)):
    for z in (-.31,.31):
        cube(f'BenchFoot_{i}_{z}',(.12,.04,.12),(x,.021,z),'steel')
export('industrial_workbench_v03.glb')

# An exterior electrical cabinet: mounting rail, reinforced shell, handle and cable conduits.
reset()
cube('Enclosure',(0.75,1.26,.28),(0,1.25,0),'steel')
cube('FrontDoor',(.7,1.2,.028),(0,1.25,.154),'roof')
for x in (-.32,.32):
    cube(f'OuterLip_{x}',(.03,1.25,.07),(x,1.25,.183),'steel')
for y in (.68,1.85):
    cube(f'OuterSeal_{y}',(.7,.028,.062),(0,y,.185),'steel')
cube('LatchBacking',(.06,.13,.03),(.24,1.22,.194),'steel')
rod('LatchLever',(.24,1.22,.22),(.13,1.22,.22),.018,'steel')
for x in (-.23,.23):
    rod(f'Cable_{x}',(x,.0,-.01),(x,.61,-.01),.022,'roof')
for x in (-.32,.32):
    for y in (.69,1.80):
        rod(f'WallBolt_{x}_{y}',(x,y,.20),(x,y,.22),.013,'steel',8)
export('electrical_cabinet_v03.glb')

print('Completed modular kit mesh export.')
