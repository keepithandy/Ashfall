"""Offline static validation for the portable Crossroads addon.
Run from the package folder with: python assets/crossroads_v03/tests/verify_package.py
Requires trimesh, numpy, Pillow. This does not replace running Godot tests.
"""
from pathlib import Path
import re, sys
import trimesh
from PIL import Image
R=Path(__file__).resolve().parents[3]
A=R/'assets'
V=A/'crossroads_v03'
failures=[]
def check(cond,msg):
    print(('PASS' if cond else 'FAIL'),msg)
    if not cond: failures.append(msg)
for f in sorted(V.rglob('*.tscn')):
    text=f.read_text()
    for path in re.findall(r'path="res://([^"]+)"',text):
        check((R/path).is_file(),f'{f.name} -> {path}')
    check(text.count('[')==text.count(']'),f'{f.name} balanced Godot block notation')
for filename in sorted((V/'geometry').glob('*.glb')):
    scene=trimesh.load(filename,force='scene')
    count=sum(len(mesh.faces) for mesh in scene.geometry.values())
    check(1<=len(scene.geometry)<=3,f'{filename.name} batches to <=3 mesh surfaces ({len(scene.geometry)})')
    check(count>=24,f'{filename.name} actual detailed geometry ({count} triangles)')
    for geom in scene.geometry.values():
        check(hasattr(geom.visual,'uv') and len(geom.visual.uv)==len(geom.vertices),f'{filename.name} UVs match vertices')
for name,width in [('wall_solid_4m',4),('wall_window_4m',4),('wall_doorway_4m',4),('wall_garage_4m',4),('floor_slab_4m',3.98),('roof_panel_4m',4)]:
    s=trimesh.load(V/'geometry'/(name+'_v03.glb'),force='scene')
    extents=s.bounds[1]-s.bounds[0]
    check(abs(extents[0]-width)<0.07,f'{name}: {width}m modular grid dimension')
check('Equipment/PersonnelDoor' in (V/'scenes'/'maintenance_station_v03.tscn').read_text(),'maintenance station has working door reference')
check((A/'crossroads_v02'/'scripts'/'ashfall_steel_door.gd').exists(),'v0.2 hinged door dependency included')
print('OFFLINE VALIDATION:', 'PASS' if not failures else f'{len(failures)} FAILURES')
sys.exit(bool(failures))
