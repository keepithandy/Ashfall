import bpy, math, os, tempfile
from mathutils import Vector
ROOT=os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
OUT=os.path.join(ROOT,'assets','crossroads_kit')
os.makedirs(OUT,exist_ok=True)
tempfile.tempdir = os.path.join(ROOT, 'tmp_export')
os.makedirs(tempfile.tempdir, exist_ok=True)
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
for m in list(bpy.data.materials): bpy.data.materials.remove(m)

def textured(name,folder,metal=0):
 m=bpy.data.materials.new(name); m.use_nodes=True
 n=m.node_tree.nodes; links=m.node_tree.links; p=n.get('Principled BSDF')
 p.inputs['Metallic'].default_value=metal
 for kind in ('albedo','roughness','normal'):
  tex=n.new('ShaderNodeTexImage'); tex.image=bpy.data.images.load(os.path.join(ROOT,'assets','materials',folder,kind+'.jpg'),check_existing=True)
  if kind!='albedo': tex.image.colorspace_settings.name='Non-Color'
  if kind=='albedo': links.new(tex.outputs['Color'],p.inputs['Base Color'])
  elif kind=='roughness': links.new(tex.outputs['Color'],p.inputs['Roughness'])
  else:
   nm=n.new('ShaderNodeNormalMap'); nm.inputs['Strength'].default_value=.65; links.new(tex.outputs['Color'],nm.inputs['Color']); links.new(nm.outputs['Normal'],p.inputs['Normal'])
 return m
concrete=textured('Concrete worn','concrete_floor_worn_001')
plaster=textured('Aged plaster and masonry','grey_plaster')
metal=textured('Corroded sheet steel','rusty_corrugated_iron',.65)
def solid(name,col,metallic,rough):
 m=bpy.data.materials.new(name); m.diffuse_color=(*col,1); m.use_nodes=True; p=m.node_tree.nodes.get('Principled BSDF'); p.inputs['Base Color'].default_value=(*col,1); p.inputs['Metallic'].default_value=metallic; p.inputs['Roughness'].default_value=rough; return m
paint=solid('Oxidised blue grey enamel',(.11,.16,.16),.55,.68)
dark=solid('Blackened steel',(.055,.06,.055),.7,.65)

def box(name, loc, size, mat, bevel=.012):
 bpy.ops.mesh.primitive_cube_add(size=1, location=loc); o=bpy.context.object; o.name=name; o.dimensions=size; bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 if bevel:
  mod=o.modifiers.new('Soft manufactured edges','BEVEL'); mod.width=bevel; mod.segments=2
  mod=o.modifiers.new('Weighted corners','WEIGHTED_NORMAL'); mod.keep_sharp=True
 o.data.materials.append(mat)
 bpy.context.view_layer.objects.active=o; bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='SELECT'); bpy.ops.uv.cube_project(cube_size=2.0); bpy.ops.object.mode_set(mode='OBJECT')
 return o

def bolt(name,loc):
 bpy.ops.mesh.primitive_cylinder_add(vertices=8,radius=.018,depth=.013,location=loc,rotation=(math.pi/2,0,0)); o=bpy.context.object; o.name=name; o.data.materials.append(dark)

def standard_wall(kind):
 # X runs from 0 to 4, Z is height, Y is wall thickness.
 if kind=='solid': box('Masonry infill',(2,0,1.6),(4,.24,3.2),plaster)
 elif kind=='window':
  for x,w in ((.575,1.15),(3.425,1.15)): box('Window masonry pier',(x,0,1.6),(w,.24,3.2),plaster)
  box('Window sill masonry',(2,0,.48),(1.7,.24,.96),plaster)
  box('Window lintel',(2,0,2.66),(1.7,.24,1.08),plaster)
  for x in (1.16,2.84): box('Steel window jamb',(x,-.145,1.55),(.055,.07,1.22),paint,.006)
  for z in (.98,2.12): box('Steel window rail',(2,-.145,z),(1.72,.07,.055),paint,.006)
  box('Window centre mullion',(2,-.15,1.55),(.045,.065,1.14),paint,.004)
  box('Window horizontal mullion',(2,-.15,1.55),(1.65,.065,.045),paint,.004)
  box('Projecting concrete sill',(2,-.02,.96),(1.82,.42,.09),concrete,.008)
 elif kind=='doorway':
  for x in (.3375,3.6625): box('Door masonry pier',(x,0,1.6),(.675,.24,3.2),plaster)
  # opening 2.65m wide? piers should define 1.3m opening
  # replace piers with intended spans
  for o in [o for o in bpy.context.selected_objects if False]: pass
  # Above piers are corrected below by explicit dimensions in caller.
  box('Door lintel',(2,0,2.8),(2.65,.24,.8),plaster)
 for x in (.14,3.86): box('Cast concrete edge pier',(x,.005,1.6),(.28,.30,3.2),concrete,.012)
 box('Foundation band',(2,-.135,.16),(3.72,.055,.32),concrete,.007)
 box('Upper concrete ring beam',(2,-.135,3.06),(3.72,.055,.25),concrete,.007)

def export_asset(name, fn):
 bpy.ops.object.select_all(action='DESELECT'); before=set(bpy.context.scene.objects); fn(); objs=[o for o in bpy.context.scene.objects if o not in before]
 col=bpy.data.collections.new(name); bpy.context.scene.collection.children.link(col)
 for o in objs:
  for c in list(o.users_collection): c.objects.unlink(o)
  col.objects.link(o); o.select_set(True)
 bpy.ops.export_scene.gltf(filepath=os.path.join(OUT,name+'.glb'),export_format='GLB',use_selection=True,export_apply=True)
 for o in objs: o.select_set(False)

def floor():
 box('Reinforced concrete floor slab',(2,2,-.10),(4,4,.2),concrete,.012)
 # subtle joint cover avoids extending beyond footprint
 for x in (1.98,): box('Saw cut joint',(x,2,.001),(.012,3.98,.003),dark,0)

def wallsolid(): standard_wall('solid')
def wallwindow(): standard_wall('window')
def walldoor():
 # 1.30 m clear opening, height 2.4 m
 for x in (.675,3.325): box('Masonry door pier',(x,0,1.6),(1.35,.24,3.2),plaster)
 box('Door lintel',(2,0,2.8),(1.3,.24,.8),plaster)
 for x in (1.36,2.64): box('Steel door frame jamb',(x,-.005,1.2),(.07,.31,2.4),paint,.006)
 box('Steel door frame head',(2,-.005,2.37),(1.35,.31,.07),paint,.006)
 for x in (.14,3.86): box('Cast concrete edge pier',(x,.005,1.6),(.28,.30,3.2),concrete)
 box('Foundation left',(.75,-.135,.16),(1.20,.055,.32),concrete,.007); box('Foundation right',(3.25,-.135,.16),(1.20,.055,.32),concrete,.007)
 box('Upper concrete ring beam',(2,-.135,3.06),(3.72,.055,.25),concrete,.007)

def corner():
 box('Corner pier',(0,0,1.6),(.30,.30,3.2),concrete)
 # short return pieces, dimensions designed for centerline intersections
 box('X return',(.57,0,1.6),(.84,.24,3.2),plaster)
 box('Y return',(0,.57,1.6),(.24,.84,3.2),plaster)
 for x,y,sx,sy in ((.57,-.14,.84,.05),(-.14,.57,.05,.84)):
  box('Corner concrete base',(x,y,.16),(sx,sy,.32),concrete,.006)
  box('Corner ring beam',(x,y,3.06),(sx,sy,.25),concrete,.006)

def roof():
 box('Roof concrete deck',(2,2,-.09),(4,4,.18),concrete,.01)
 # thin physical standing corrugations; independent sheet beneath them
 box('Weathered steel roofing',(2,2,.014),(3.98,3.98,.028),metal,.003)
 for i in range(21):
  x=.095+i*.19; box('Raised standing seam %02d'%i,(x,2,.045),(.035,3.98,.05),metal,.009)
 for y in (.12,3.88): box('Roof edge flashing',(2,y,.06),(4,.05,.09),paint,.005)

def door():
 # hinge at local origin; upright mesh fits into 1.3m doorway
 box('Pressed steel leaf',(.60,0,1.17),(1.19,.07,2.32),paint,.015)
 for x in (.075,1.125): box('Perimeter stile',(x,-.045,1.17),(.10,.045,2.25),metal,.009)
 for z in (.08,1.17,2.25): box('Pressed horizontal reinforcement',(.60,-.045,z),(1.06,.04,.08),metal,.008)
 for z in (.24,1.93):
  box('Recessed door field',(.60,-.041,z),( .85,.018,.32),dark,.01)
  for x in (.18,1.02): bolt('Riveted panel fastener',(x,-.065,z))
 for z in (.25,1.15,2.05):
  bpy.ops.mesh.primitive_cylinder_add(vertices=12,radius=.035,depth=.18,location=(.02,0,z)); bpy.context.object.name='Hinge barrel'; bpy.context.object.data.materials.append(metal)
 box('Lock plate',(1.04,-.075,1.02),(.12,.025,.23),dark,.008)
 box('Lever handle',(.96,-.105,1.06),(.18,.04,.035),metal,.008)
 for z in (.12,2.20):
  for x in (.15,.38,.61,.84,1.07): bolt('Edge rivet',(x,-.074,z))

def wall2():
 box('Two metre masonry infill',(1,0,1.6),(2,.24,3.2),plaster)
 for x in (.14,1.86): box('Cast concrete edge pier',(x,.005,1.6),(.28,.30,3.2),concrete)
 box('Foundation band',(1,-.135,.16),(1.72,.055,.32),concrete,.007)
 box('Upper ring beam',(1,-.135,3.06),(1.72,.055,.25),concrete,.007)

for n,f in [('wall_solid_2m',wall2),('floor_4m',floor),('wall_solid_4m',wallsolid),('wall_window_4m',wallwindow),('wall_door_4m',walldoor),('corner_1m',corner),('roof_4m',roof),('metal_door',door)]: export_asset(n,f)
# Pack source images so the editable file remains self contained.
bpy.ops.file.pack_all(); bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT,'source','crossroads_kit.blend'))



