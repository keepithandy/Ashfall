"""Ashfall Crossroads prop set. Blender 4.5; metres, Z up; GLB exports use Godot Y up."""
import bpy, math, os, random
from mathutils import Vector
random.seed(8724)
ROOT=os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
OUT=os.path.join(ROOT,'assets','crossroads_props')
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)

def mat(name,color,metal=0,rough=.8):
 m=bpy.data.materials.new(name); m.diffuse_color=(*color,1); m.use_nodes=True
 p=m.node_tree.nodes.get('Principled BSDF'); p.inputs['Base Color'].default_value=(*color,1); p.inputs['Metallic'].default_value=metal; p.inputs['Roughness'].default_value=rough; return m
iron=mat('shared_iron',(.28,.30,.28),.65,.6); rust=mat('shared_rust',(.27,.13,.075),.3,.86)
olive=mat('shared_olive',(.21,.27,.18),.35,.75); rubber=mat('shared_rubber',(.035,.04,.035),0,.95)
wood=mat('shared_wood',(.27,.22,.15),0,.9); bark=mat('shared_bark',(.16,.115,.075),0,.95)
endgrain=mat('shared_endgrain',(.39,.32,.22),0,.92); cap=mat('fungus_cap',(.30,.16,.085),0,.78)
gill=mat('fungus_gill',(.50,.44,.34),0,.95); moss=mat('root_moss',(.14,.19,.075),0,.98)
gill_line=mat('fungus_gill_detail',(.28,.23,.16),0,.98)
soil=mat('root_soil',(.11,.085,.055),0,.99)

def box(name,loc,size,material,bevel=.005):
 bpy.ops.mesh.primitive_cube_add(size=1,location=loc); o=bpy.context.object; o.name=name; o.dimensions=size
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True); o.data.materials.append(material)
 if bevel:
  m=o.modifiers.new('soft edges','BEVEL'); m.width=bevel; m.segments=2
  o.modifiers.new('weighted normals','WEIGHTED_NORMAL')
 return o

def cylinder(name,a,b,r1,r2,material,vertices=12):
 a,b=Vector(a),Vector(b); d=b-a
 bpy.ops.mesh.primitive_cone_add(vertices=vertices,radius1=r1,radius2=r2,depth=d.length,location=(a+b)/2)
 o=bpy.context.object; o.name=name; o.rotation_mode='QUATERNION'; o.rotation_quaternion=d.to_track_quat('Z','Y'); o.data.materials.append(material)
 if material in (bark, gill, moss):
  for face in o.data.polygons:
   if len(face.vertices) == 4: face.use_smooth = True
 return o

def beam(name,a,b,width,depth,material):
 a,b=Vector(a),Vector(b); d=b-a; o=box(name,(a+b)/2,(width,depth,d.length),material,.004); o.rotation_mode='QUATERNION'; o.rotation_quaternion=d.to_track_quat('Z','Y'); return o

def plate(name,poly,thickness,material):
 # x,z outline extruded across y
 verts=[(x,y,z) for y in (-thickness/2,thickness/2) for x,z in poly]; n=len(poly)
 faces=[tuple(range(n-1,-1,-1)),tuple(range(n,2*n))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
 mesh=bpy.data.meshes.new(name); mesh.from_pydata(verts,[],faces); mesh.update(); o=bpy.data.objects.new(name,mesh); bpy.context.collection.objects.link(o); o.data.materials.append(material)
 m=o.modifiers.new('rolled edges','BEVEL'); m.width=.004; m.segments=2; o.modifiers.new('normals','WEIGHTED_NORMAL'); return o

def organic_tube(name, points, radii, material, seed, seg=14):
 rng=random.Random(seed); points=[Vector(p) for p in points]
 if len(points) > 2:
  refined=[]; refined_r=[]
  for i in range(len(points)-1):
   p0=points[max(i-1,0)]; p1=points[i]; p2=points[i+1]; p3=points[min(i+2,len(points)-1)]
   for j in range(3):
    t=j/3.0; t2=t*t; t3=t2*t
    q=.5*((2*p1)+(-p0+p2)*t+(2*p0-5*p1+4*p2-p3)*t2+(-p0+3*p1-3*p2+p3)*t3)
    refined.append(q); refined_r.append(radii[i]*(1-t)+radii[i+1]*t)
  refined.append(points[-1]); refined_r.append(radii[-1]); points=refined; radii=refined_r
 verts=[]
 for i,p in enumerate(points):
  tangent=(points[min(i+1,len(points)-1)]-points[max(0,i-1)]).normalized()
  ref=Vector((0,0,1)) if abs(tangent.z)<.9 else Vector((1,0,0))
  side=tangent.cross(ref).normalized(); up=tangent.cross(side).normalized()
  for j in range(seg):
   a=j*math.tau/seg; uneven=1+.12*math.sin(3*a+seed*.17+i*.3)+.055*math.sin(7*a+i*.8+seed)
   verts.append(tuple(p+radii[i]*uneven*(side*math.cos(a)+up*math.sin(a))))
 faces=[]
 for i in range(len(points)-1):
  for j in range(seg): faces.append((i*seg+j,i*seg+(j+1)%seg,(i+1)*seg+(j+1)%seg,(i+1)*seg+j))
 faces.extend([tuple(reversed(range(seg))),tuple((len(points)-1)*seg+j for j in range(seg))])
 mesh=bpy.data.meshes.new(name); mesh.from_pydata(verts,[],faces); mesh.update()
 ob=bpy.data.objects.new(name,mesh); bpy.context.collection.objects.link(ob); ob.data.materials.append(material)
 for face in mesh.polygons:
  if len(face.vertices)==4: face.use_smooth=True
 return ob

def jack():
 # Low chassis with raised front and rear pivot cheeks.
 for y in (-.115,.115):
  p=plate('Pressed chassis side',[(-.33,.07),(.28,.07),(.35,.11),(.27,.20),(-.16,.17),(-.33,.13)],.018,olive); p.location.y=y
  box('Raised edge rail',(-.01,y,.165),(.48,.024,.027),rust,.004)
 box('Base cross member',(-.03,0,.078),(.48,.22,.025),iron)
 for x in (-.27,.27):
  for y in (-.14,.14):
   cylinder('Steel road wheel',(x,y-.025,.055),(x,y+.025,.055),.055,.055,iron,20)
   cylinder('Wheel hub',(x,y-.031,.055),(x,y+.031,.055),.018,.018,rust,12)
 for y in (-.068,.068):
  p=plate('Lifting arm', [(-.22,.14),(.20,.28),(.255,.255),(-.15,.105)], .024, olive); p.location.y=y
  cylinder('Arm hinge pin',(-.21,y-.02,.145),(-.21,y+.02,.145),.025,.025,iron)
 cylinder('Saddle post',(.22,0,.255),(.22,0,.32),.033,.033,iron)
 cylinder('Saddle cup',(.22,0,.32),(.22,0,.345),.09,.085,rust,24)
 for i in range(4):
  a=i*math.pi/2; box('Saddle tooth',(.22+.058*math.cos(a),.058*math.sin(a),.35),(.032,.032,.015),iron,.002)
 cylinder('Hydraulic cylinder',(-.24,0,.13),(.08,0,.21),.042,.039,iron,16)
 cylinder('Hydraulic piston',(.07,0,.207),(.18,0,.235),.019,.019,iron,12)
 cylinder('Handle socket',(-.29,0,.14),(-.38,0,.28),.043,.038,rust,14)
 cylinder('Pump handle',(-.37,0,.26),(-.72,0,.96),.020,.017,iron,12)
 cylinder('Rubber hand grip',(-.68,0,.88),(-.76,0,1.04),.025,.025,rubber,12)
 for y in (-.11,.11):
  for x in (-.19,.18): cylinder('Fastener',(x,y-.013,.145),(x,y+.013,.145),.014,.014,iron,8)
 # Grease collars, pump linkage and edge details articulate the mechanism.
 cylinder('Pump pivot axle',(-.27,-.092,.15),(-.27,.092,.15),.022,.022,iron,16)
 for y in (-.056,.056):
  cylinder('Linkage pin',(.095,y-.025,.218),(.095,y+.025,.218),.015,.015,rust,12)
 cylinder('Piston collar',(-.12,0,.16),(-.08,0,.17),.046,.046,rust,16)
 for y in (-.118,.118):
  for x in (-.25,.23):
   cylinder('Chassis rivet',(x,y-.012,.105),(x,y+.012,.105),.009,.009,iron,10)

def trestle():
 for y in (-.095,.095): box('Worktop timber', (0,y,.82),(1.12,.18,.08),wood,.008)
 for x in (-.43,.43):
  for y in (-1,1):
   beam('Splayed timber leg',(x,y*.23,.04),(x*.87,y*.09,.78),.065,.065,wood)
  beam('Horizontal leg brace',(x,-.18,.33),(x,.18,.33),.045,.04,wood)
  for y in (-.11,.11): cylinder('Leg bolt',(x,y-.025,.72),(x,y+.025,.72),.012,.012,iron,8)
 beam('Long diagonal brace',(-.43,-.20,.30),(.43,-.115,.69),.035,.035,wood)
 for x in (-.49,.49):
  box('Steel end strap',(x,0,.86),(.035,.35,.008),rust,.002)
  for y in (-.14,.14): cylinder('Strap countersunk screw',(x,y,.864),(x,y,.869),.008,.008,iron,8)
 # Structural aprons, a rear diagonal brace and shallow worn gouges in the top.
 for y in (-.115,.115): box('Under-top apron',(0,y,.73),(.92,.035,.115),wood,.005)
 beam('Rear diagonal brace',(-.43,.19,.32),(.43,.11,.68),.035,.035,wood)
 for x,y,length in [(-.22,-.12,.19),(.15,.035,.25),(.34,-.045,.12),(-.36,.12,.11)]:
  box('Narrow worn grain cut',(x,y,.861),(length,.003,.002),rust,.0004)

def rootcluster():
 # Uneven, broken crown; roots follow bent paths instead of evenly spaced cones.
 seg=20; zs=[.0,.055,.16,.27,.355]; radii=[.19,.19,.155,.12,.095]; verts=[]
 for row,(z,r) in enumerate(zip(zs,radii)):
  for j in range(seg):
   a=math.tau*j/seg; k=1+.12*math.sin(a*5+.8)+.08*math.sin(a*3-1.4)
   jagged=(.035*math.sin(3*a+.5)+.02*math.sin(7*a)) if row==len(zs)-1 else 0
   verts.append((r*k*math.cos(a)+z*.07,r*k*math.sin(a)+z*.045,z+jagged))
 faces=[]
 for row in range(len(zs)-1):
  for j in range(seg): faces.append((row*seg+j,row*seg+(j+1)%seg,(row+1)*seg+(j+1)%seg,(row+1)*seg+j))
 mesh=bpy.data.meshes.new('Torn crown'); mesh.from_pydata(verts,[],faces); mesh.update()
 ob=bpy.data.objects.new('Torn crown',mesh); bpy.context.collection.objects.link(ob); ob.data.materials.append(bark)
 for f in mesh.polygons: f.use_smooth=True
 # Broken wood is recessed within the ragged bark, with irregular splinters.
 cylinder('Fractured exposed heartwood',(.025,.015,.32),(.026,.015,.35),.076,.068,endgrain,14)
 for i in range(6):
  a=i*math.tau/6+.2; h=.37+[.055,.015,.08,.025,.045,.0][i]
  organic_tube('Torn timber sliver',[(.055*math.cos(a),.055*math.sin(a),.30),(.065*math.cos(a),.065*math.sin(a),h)], [.020,.0015],endgrain,810+i,8)
 angles=[.12,.73,1.75,2.58,3.27,4.17,5.25]
 lengths=[.68,.51,.72,.56,.73,.47,.63]
 for i,(a,length) in enumerate(zip(angles,lengths)):
  d=Vector((math.cos(a),math.sin(a),0)); lateral=Vector((-d.y,d.x,0)); bend=[.05,-.05,.08,-.06,.025,.06,-.04][i]
  pts=[d*.08+Vector((0,0,.16)), d*.20+Vector((0,0,.10)), d*(length*.56)+lateral*bend+Vector((0,0,.05)), d*length+lateral*(bend*1.7)+Vector((0,0,.02))]
  organic_tube('Curved weathered root',pts,[.105,.08,.043,.006],bark,100+i)
  if i in (0,2,4,6):
   branch=[pts[2],pts[2]+d*.13+lateral*(.08 if i%4==0 else -.08)+Vector((0,0,-.017)),pts[2]+d*.23+lateral*(.15 if i%4==0 else -.15)+Vector((0,0,-.027))]
   organic_tube('Root fork',branch,[.036,.019,.003],bark,220+i,10)
 # Broken soil clods conceal root junctions and visually anchor the crown.
 for i,(x,y,sx,sy,sz) in enumerate([(-.15,-.06,.11,.08,.035),(.14,-.05,.09,.08,.03),(.09,.14,.10,.07,.03),(-.10,.16,.07,.08,.025),(.01,-.20,.11,.06,.026)]):
  bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2,radius=1,location=(x,y,sz)); o=bpy.context.object; o.name='Clinging compacted earth'; o.scale=(sx,sy,sz); o.data.materials.append(soil)
  for v in o.data.vertices:
   v.co *= 1+.1*math.sin(v.co.x*11+i)*math.sin(v.co.y*17-i)
 for i,(x,y,z) in enumerate([(-.12,.08,.095),(.13,.05,.11),(-.04,-.15,.07),(.08,-.08,.19)]):
  bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2,radius=1,location=(x,y,z)); o=bpy.context.object; o.name='Irregular moss patch'; o.scale=(.055,.04,.012); o.data.materials.append(moss)


def cap_mesh(name,x,y,z,r,variant):
 # Unequal, softly domed caps with a rolled edge and a distinct underside.
 seg=32; profile=[(0,.38),(.18,.37),(.43,.33),(.67,.23),(.86,.11),(1.0,0),(.94,-.045),(.18,-.06)]
 verts=[]
 for ri,(rad,h) in enumerate(profile):
  for j in range(seg):
   a=j*math.tau/seg; variation=1+.065*math.sin(a*3+variant*.7)+.035*math.sin(a*7+variant)
   hvar=.025*math.sin(a*4+variant) if ri>2 else .01*math.sin(a*3+variant)
   verts.append((x+r*rad*variation*math.cos(a),y+r*rad*variation*math.sin(a),z+r*(h+hvar*rad)))
 faces=[]
 for j in range(len(profile)-1):
  for i in range(seg): faces.append((j*seg+i,j*seg+(i+1)%seg,(j+1)*seg+(i+1)%seg,(j+1)*seg+i))
 mesh=bpy.data.meshes.new(name); mesh.from_pydata(verts,[],[tuple(reversed(face)) for face in faces]); mesh.update()
 o=bpy.data.objects.new(name,mesh); bpy.context.collection.objects.link(o); o.data.materials.append(cap); o.data.materials.append(gill)
 for poly in mesh.polygons: poly.material_index=1 if poly.index//seg>=5 else 0; poly.use_smooth=True
 # Fine radial ribs sit below the underside; no flat bright disk from below.
 gv=[]; gf=[]
 for j in range(32):
  a=math.tau*j/32; half=.012; inner=.20*r; outer=.89*r
  for radius,angle in ((inner,a-half),(outer,a-half*.55),(outer,a+half*.55),(inner,a+half)):
   gv.append((x+radius*math.cos(angle),y+radius*math.sin(angle),z-.062*r))
  k=j*4; gf.append((k,k+3,k+2,k+1))
 gm=bpy.data.meshes.new('Fine radial gills'); gm.from_pydata(gv,[],gf); gm.update()
 go=bpy.data.objects.new('Fine radial gills',gm); bpy.context.collection.objects.link(go); go.data.materials.append(gill_line)
 return o

def mushrooms():
 spots=[(-.16,-.06,.12,.060),(-.05,.04,.20,.09),(.09,-.02,.16,.075),(.18,.09,.105,.05),(.01,-.12,.09,.045),(-.15,.14,.105,.045),(.12,-.13,.075,.038)]
 for i,(x,y,h,r) in enumerate(spots):
  leanx=.008*math.sin(i*2.1); leany=.006*math.cos(i*1.7)
  organic_tube('Slightly curved stem',[(x,y,.004),(x+leanx*.15,y+leany*.2,h*.2),(x+leanx*.7,y+leany*.7,h*.68),(x+leanx,y+leany,h)], [r*.19,r*.16,r*.14,r*.12],gill,400+i,12)
  cap_mesh('Uneven mushroom cap',x+leanx,y+leany,h,r,i)
  cylinder('Fragile stem ring',(x+leanx*.75,y+leany*.75,h*.72),(x+leanx*.78,y+leany*.78,h*.735),r*.19,r*.16,gill,12)


def export(name,fn):
 bpy.ops.object.select_all(action='DESELECT'); before=set(bpy.context.scene.objects); fn(); objects=[o for o in bpy.context.scene.objects if o not in before]
 if name in ('work_trestle','exposed_roots'):
  offset={'work_trestle':.0343,'exposed_roots':0}[name]
  for o in objects: o.location.z -= offset
 col=bpy.data.collections.new(name); bpy.context.scene.collection.children.link(col)
 for o in objects:
  for c in list(o.users_collection): c.objects.unlink(o)
  col.objects.link(o)
 # Duplicate and merge by material to reduce draw calls while retaining original pieces in the blend.
 copies=[]
 for o in objects:
  cp=o.copy(); cp.data=o.data.copy(); bpy.context.scene.collection.objects.link(cp); copies.append(cp)
 bpy.ops.object.select_all(action='DESELECT')
 for cp in copies: cp.select_set(True)
 bpy.context.view_layer.objects.active=copies[0]
 # Apply modifiers before joining, so bevels and weighted normals survive.
 for cp in copies:
  bpy.context.view_layer.objects.active=cp
  for modifier in list(cp.modifiers): bpy.ops.object.modifier_apply(modifier=modifier.name)
 bpy.context.view_layer.objects.active=copies[0]; bpy.ops.object.join()
 joined=bpy.context.object; joined.name=name+'_mesh'
 bpy.ops.export_scene.gltf(filepath=os.path.join(OUT,name+'.glb'),export_format='GLB',use_selection=True,export_apply=True)
 bpy.data.objects.remove(joined,do_unlink=True)
for name,fn in [('hydraulic_jack',jack),('work_trestle',trestle),('exposed_roots',rootcluster),('mushroom_cluster',mushrooms)]: export(name,fn)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT,'source','crossroads_props.blend'))


