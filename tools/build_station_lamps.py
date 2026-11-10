import bpy, math, os
from mathutils import Vector
root=os.getcwd(); out=os.path.join(root,'assets','station_lamps'); os.makedirs(out,exist_ok=True)
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
def mat(n,c,metal=0,emit=0):
 m=bpy.data.materials.new(n); m.diffuse_color=(*c,1); m.use_nodes=True; p=m.node_tree.nodes.get('Principled BSDF'); p.inputs['Base Color'].default_value=(*c,1); p.inputs['Metallic'].default_value=metal; p.inputs['Roughness'].default_value=.65
 if emit: p.inputs['Emission Color'].default_value=(*c,1); p.inputs['Emission Strength'].default_value=emit
 return m
steel=mat('Weathered olive steel',(.115,.15,.13),.7); rust=mat('Oxidized seams',(.23,.095,.035),.4); glass=mat('Warm prismatic diffuser',(.7,.51,.27),.1,1.6); dark=mat('Rubber gasket',(.018,.023,.022))
def finish(o,n,m):
 o.name=n; o.data.materials.append(m)
 for p in o.data.polygons:p.use_smooth=True
 return o
def cyl(n,a,b,r,m):
 d=Vector(b)-Vector(a); bpy.ops.mesh.primitive_cylinder_add(vertices=20,radius=r,depth=d.length,location=(Vector(a)+Vector(b))/2); o=bpy.context.object; o.rotation_euler=d.to_track_quat('Z','Y').to_euler(); return finish(o,n,m)
def ell(n,p,s,m):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=32,ring_count=16,location=p); o=bpy.context.object;o.scale=s; bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);return finish(o,n,m)
cyl('Tapered utility pole',(0,0,.12),(0,0,4.8),.075,steel)
cyl('Ground sleeve',(0,0,0),(0,0,.52),.105,rust)
cyl('Mount collar',(0,0,4.35),(0,0,4.58),.095,rust)
pts=[(0,0,4.45),(.04,0,4.8),(.23,0,5.04),(.55,0,5.15),(1.25,0,5.15)]
for i in range(len(pts)-1):cyl('Swept bracket',pts[i],pts[i+1],.042,steel)
ell('Cast aluminum oval canopy',(1.38,0,5.11),(.57,.25,.16),steel)
ell('Lens retaining gasket',(1.4,0,5.035),(.53,.23,.065),dark)
ell('Prismatic glass bowl',(1.4,0,4.99),(.5,.21,.105),glass)
for i in range(13):
 x=1.0+i*.065; w=.195*math.sqrt(max(0,1-((x-1.4)/.5)**2)); cyl('Glass prism rib',(x,-w,4.955),(x,w,4.955),.006,glass)
for y in [-.23,.23]:cyl('Lens latch',(1.38,y,5.02),(1.38,y,5.13),.018,rust)
for z in [1.0,1.35]:cyl('Service hatch screw',(.075,0,z),(.09,0,z),.014,rust)
ell('Service hatch',(.073,0,1.17),(.025,.055,.23),steel)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(out,'source','street_lamp_1980s.blend'))
bpy.ops.export_scene.gltf(filepath=os.path.join(out,'street_lamp_1980s.glb'),export_format='GLB')

