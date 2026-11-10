extends "res://scripts/authoring/natural_prop_builder.gd"
## Original editable set dressing. Bake into ordinary, unlabeled world scenes.
const EXTRA_CATALOG := {
 "wood_sawhorse": Vector3(1.2,0.82,0.7),
 "garden_shovel": Vector3(0.25,1.25,0.13),
 "scrap_sheet": Vector3(1.3,0.11,0.92),
 "firewood_stack": Vector3(0.98,0.58,0.58),
 "mushroom_cluster": Vector3(0.55,0.20,0.48),
 "dry_grass_tuft": Vector3(0.65,0.64,0.65),
 "stone_scatter": Vector3(1.2,0.20,0.9)
}
const TITLES := {
 "wood_sawhorse":"Weathered timber sawhorse", "garden_shovel":"Worn garden shovel",
 "scrap_sheet":"Bent corrugated steel", "firewood_stack":"Split firewood stack",
 "mushroom_cluster":"Woodland mushrooms", "dry_grass_tuft":"Dry meadow grass",
 "stone_scatter":"Weathered stone scatter"
}
var extra_mats := {}
var dark_metal: Material

func shader_material(id: String, body: String) -> ShaderMaterial:
 var mat := ShaderMaterial.new()
 var sh := Shader.new()
 sh.code = """shader_type spatial;
render_mode cull_disabled;
varying vec3 local_pos;
float hash3(vec3 p){return fract(sin(dot(p,vec3(17.13,83.71,39.17)))*43758.5453);}
float noise3(vec3 p){vec3 i=floor(p);vec3 f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(mix(hash3(i),hash3(i+vec3(1,0,0)),f.x),mix(hash3(i+vec3(0,1,0)),hash3(i+vec3(1,1,0)),f.x),f.y),mix(mix(hash3(i+vec3(0,0,1)),hash3(i+vec3(1,0,1)),f.x),mix(hash3(i+vec3(0,1,1)),hash3(i+vec3(1,1,1)),f.x),f.y),f.z);}
void vertex(){local_pos=VERTEX;}
void fragment(){
""" + body + "\nNORMAL=FRONT_FACING?NORMAL:-NORMAL;\n}"
 mat.shader=sh
 mat.resource_name=id
 var path:="res://assets/extra_dressing/"+id+".tres"
 ResourceSaver.save(mat,path)
 return load(path)

func prepare_extra_materials() -> void:
 DirAccess.make_dir_recursive_absolute("res://assets/extra_dressing")
 # Each new resource belongs only to this extension; older material files are retained.
 timber=load("res://assets/props/wood.tres")
 dark_metal=shader_material("worn_steel","""
 float n=noise3(local_pos*55.0); float pits=noise3(local_pos*220.0);
 ALBEDO=mix(vec3(0.09,0.10,0.10),vec3(0.24,0.25,0.22),n)*mix(0.8,1.05,pits);
 METALLIC=0.75; ROUGHNESS=0.46+n*0.3;
 """)
 rust=shader_material("oxidized_steel","""
 float n=noise3(local_pos*18.0);float fine=noise3(local_pos*190.0);
 float oxide=smoothstep(0.35,0.62,n);
 ALBEDO=mix(vec3(0.065,0.078,0.073),mix(vec3(0.085,0.035,0.014),vec3(0.18,0.075,0.024),fine),oxide);
 METALLIC=mix(0.75,0.06,oxide);ROUGHNESS=mix(0.48,0.96,oxide);
 """)
 bark=shader_material("rough_bark","""
 vec3 p=local_pos;float n=noise3(p*vec3(37.0,18.0,4.0));float ridges=noise3(p*vec3(155.0,90.0,7.0));
 ALBEDO=mix(vec3(0.035,0.026,0.016),vec3(0.13,0.098,0.062),n)*mix(0.65,1.12,ridges);
 ROUGHNESS=0.99;
 """)
 endgrain=shader_material("cut_endgrain","""
 vec2 p=(UV-vec2(0.5))*2.0;float a=atan(p.y,p.x);float r=length(p);
 float rings=sin((r+sin(a*4.0)*0.025)*95.0);float fleck=noise3(vec3(p*100.0,0));
 ALBEDO=mix(vec3(0.13,0.077,0.035),vec3(0.32,0.22,0.11),rings*0.12+0.6)*mix(0.86,1.05,fleck);
 float crack=step(0.998,cos(a*7.0+sin(r*3.0)*0.4))*smoothstep(0.1,0.8,r);
 ALBEDO*=1.0-crack*0.7;ROUGHNESS=0.96;
 """)
 extra_mats.cap=shader_material("mushroom_cap","""
 float n=noise3(local_pos*90.0);float speck=noise3(local_pos*700.0);
 ALBEDO=mix(vec3(0.16,0.085,0.045),vec3(0.40,0.27,0.15),n)*mix(0.87,1.12,speck);ROUGHNESS=0.8;
 """)
 extra_mats.stem=shader_material("mushroom_stem","""
 float fibre=noise3(local_pos*vec3(480.0,25.0,480.0));
 ALBEDO=mix(vec3(0.22,0.16,0.095),vec3(0.43,0.35,0.22),fibre);ROUGHNESS=0.92;
 """)
 extra_mats.stone=shader_material("stone_surface","""
 float broad=noise3(local_pos*17.0);float grain=noise3(local_pos*280.0);
 ALBEDO=mix(vec3(0.085,0.09,0.08),vec3(0.21,0.20,0.17),broad)*mix(0.85,1.12,grain)*COLOR.rgb;
 float dirt=1.0-smoothstep(0.0,0.055,local_pos.y);ALBEDO=mix(ALBEDO,ALBEDO*vec3(0.64,0.58,0.48),dirt*0.6);
 ROUGHNESS=0.95;
 """)
 var grass_shader:=Shader.new()
 grass_shader.code="""shader_type spatial;
render_mode cull_disabled, specular_disabled;
void vertex(){vec3 w=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;float sway=sin(TIME*1.15+w.x*1.8+w.z*1.1);VERTEX.x+=sway*UV.y*UV.y*0.018;VERTEX.z+=cos(TIME*0.8+w.z)*UV.y*UV.y*0.008;}
void fragment(){float veins=sin(UV.x*27.0)*0.025;ALBEDO=mix(vec3(0.15,0.15,0.075),vec3(0.40,0.33,0.16),UV.y)*COLOR.rgb+veins;ROUGHNESS=0.96;NORMAL=FRONT_FACING?NORMAL:-NORMAL;BACKLIGHT=ALBEDO*0.18;}
"""
 var gm:=ShaderMaterial.new();gm.shader=grass_shader;gm.resource_name="dry_grass"
 ResourceSaver.save(gm,"res://assets/extra_dressing/dry_grass.tres")
 extra_mats.grass=load("res://assets/extra_dressing/dry_grass.tres")

func pipe(label: String, start: Vector3, end: Vector3, radius_value: float, mat: Material, parent: Node3D = null) -> MeshInstance3D:
 if parent == null:parent=root
 var node:=MeshInstance3D.new();node.name=label
 var shape:=CylinderMesh.new();shape.top_radius=radius_value;shape.bottom_radius=radius_value;shape.height=start.distance_to(end);shape.radial_segments=12;shape.rings=0
 node.mesh=shape;node.material_override=mat;node.position=(start+end)*.5;node.quaternion=Quaternion(Vector3.UP,(end-start).normalized());parent.add_child(node)
 return node

func add_mesh(label: String, surface: SurfaceTool, mat: Material) -> MeshInstance3D:
 surface.generate_normals()
 var node:=MeshInstance3D.new();node.name=label;node.mesh=surface.commit();node.material_override=mat;root.add_child(node)
 return node

func emit_triangle(st: SurfaceTool,a: Vector3,bb: Vector3,c: Vector3,ua: Vector2=Vector2.ZERO,ub: Vector2=Vector2.ZERO,uc: Vector2=Vector2.ZERO) -> void:
 st.set_uv(ua);st.add_vertex(a);st.set_uv(ub);st.add_vertex(bb);st.set_uv(uc);st.add_vertex(c)

func quad_patch(st: SurfaceTool,a: Vector3,bb: Vector3,c: Vector3,d: Vector3) -> void:
 emit_triangle(st,a,bb,c,Vector2(0,0),Vector2(1,0),Vector2(1,1))
 emit_triangle(st,a,c,d,Vector2(0,0),Vector2(1,1),Vector2(0,1))

func metal_fixing(at: Vector3) -> void:
 pipe("Washer",at,at+Vector3(0,0,.003),.012,dark_metal)
 var head:=pipe("HexBolt",at+Vector3(0,0,.003),at+Vector3(0,0,.012),.0075,dark_metal)
 (head.mesh as CylinderMesh).radial_segments=6

func sawhorse() -> void:
 b("ChamferedTopBeam",Vector3(0,.77,0),Vector3(1.2,.10,.13),timber,.009)
 for x in [-.43,.43]:
  for side in [-1,1]:
   var start:=Vector3(x,.715,side*.045);var end:=Vector3(x,.037,side*.315)
   var leg:=b("SplayedTimberLeg",(start+end)*.5,Vector3(.072,start.distance_to(end)+.04,.072),timber,.004)
   leg.quaternion=Quaternion(Vector3.UP,(end-start).normalized())
   var cs:=CollisionShape3D.new();var bs:=BoxShape3D.new();bs.size=Vector3(.078,start.distance_to(end),.078);cs.shape=bs;cs.transform=leg.transform;root.add_child(cs)
   b("GalvanizedLegBracket",Vector3(x,.71,side*.086),Vector3(.13,.18,.012),rust,.002)
   for yy in [.66,.75]: metal_fixing(Vector3(x,yy,side*.098))
  b("CrossTie",Vector3(x,.30,0),Vector3(.045,.065,.46),timber,.003)
 beam("LongitudinalDiagonal",Vector3(-.43,.23,-.18),Vector3(.43,.64,-.10),.04,timber)
 collision_box(Vector3(0,.77,0),Vector3(1.2,.1,.13))

func shovel() -> void:
 # Curved, pointed spade built as a thin shell instead of a rectangular blade.
 var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
 var widths:=[.012,.075,.115,.122,.115,.075]
 for j in range(5):
  for i in range(12):
   var pts:Array[Vector3]=[]
   for ij in [Vector2i(i,j),Vector2i(i+1,j),Vector2i(i+1,j+1),Vector2i(i,j+1)]:
    var u:=float(ij.x)/12.0*2.0-1.0;var y:=.006+float(ij.y)*.049
    pts.append(Vector3(u*widths[ij.y],y,.04*u*u+.012*sin(y*13.0)))
   quad_patch(st,pts[0],pts[1],pts[2],pts[3])
 add_mesh("CurvedSpadeBlade",st,rust)
 # Polished cutting edge follows the lower two rows of the blade.
 for side in [-1,1]:
  pipe("WornCuttingLip",Vector3(side*.012,.006,0.038),Vector3(side*.075,.055,.043),.0025,dark_metal)
  pipe("FoldedShoulder",Vector3(side*.03,.251,.01),Vector3(side*.115,.211,.042),.007,dark_metal)
 pipe("SteelSocket",Vector3(0,.19,.016),Vector3(0,.39,.016),.025,rust)
 for y in [.24,.34]: metal_fixing(Vector3(0,y,.039))
 pipe("AshWoodShaft",Vector3(0,.29,.016),Vector3(.012,1.05,.016),.018,timber)
 for x in [-.063,.063]:
  pipe("DGripSide",Vector3(.012,1.015,.016),Vector3(x,1.125,.016),.012,dark_metal)
  pipe("DGripUpright",Vector3(x,1.125,.016),Vector3(x,1.22,.016),.012,dark_metal)
 pipe("RoundedWoodGrip",Vector3(-.063,1.22,.016),Vector3(.063,1.22,.016),.019,timber)
 collision_box(Vector3(0,.13,.026),Vector3(.245,.26,.07))
 collision_box(Vector3(.006,.74,.016),Vector3(.05,.92,.06))

func sheet_height(x: float,z: float) -> float:
 return .036+.022*sin((x+.65)*TAU/.145)+pow(maxf(0.0,(x-.38)/.27),2.0)*.035+sin(z*8.0)*.004

func sheet() -> void:
 var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
 for j in range(16):
  for i in range(144):
   var pts:Array[Vector3]=[]
   for ij in [Vector2i(i,j),Vector2i(i+1,j),Vector2i(i+1,j+1),Vector2i(i,j+1)]:
    var x:=-.65+float(ij.x)/144.0*1.3;var z:=-.46+float(ij.y)/16.0*.92
    pts.append(Vector3(x,sheet_height(x,z),z))
   quad_patch(st,pts[0],pts[1],pts[2],pts[3])
 add_mesh("ContinuousBentCorrugation",st,rust)
 var edge:=SurfaceTool.new();edge.begin(Mesh.PRIMITIVE_TRIANGLES)
 for z in [-.46,.46]:
  for i in range(72):
   var x:=-.65+float(i)/72.0*1.3;var nx:=x+1.3/72.0
   var a:=Vector3(x,sheet_height(x,z),z);var bb:=Vector3(nx,sheet_height(nx,z),z)
   quad_patch(edge,a,bb,bb-Vector3.UP*.002,a-Vector3.UP*.002)
 add_mesh("ThinCutSheetEdges",edge,dark_metal)
 for x in [-.50,.23]:
  for z in [-.34,.34]:
   var y:=sheet_height(x,z)
   pipe("OldRoofingFastener",Vector3(x,y,z),Vector3(x,y+.006,z),.009,dark_metal)
 collision_box(Vector3(0,.045,0),Vector3(1.3,.09,.92))

func split_log(center: Vector3, radius: float, length: float, phase: float, split: bool) -> void:
 var points:Array[Vector2]=[]
 var count:=12
 for j in range(count):
  var angle:=phase+TAU*float(j)/count
  var rad:=radius*(1.0+.08*sin(j*2.7+phase))
  # Squared split face across upper third of selected logs.
  points.append(Vector2(sin(angle)*rad,minf(cos(angle)*rad,radius*.20) if split else cos(angle)*rad))
 var shell:=SurfaceTool.new();shell.begin(Mesh.PRIMITIVE_TRIANGLES)
 var ends:=SurfaceTool.new();ends.begin(Mesh.PRIMITIVE_TRIANGLES)
 for j in range(count):
  var k:=(j+1)%count
  var a:=center+Vector3(points[j].x,points[j].y,-length*.5)
  var bb:=center+Vector3(points[k].x,points[k].y,-length*.5)
  var c:=center+Vector3(points[k].x+.012,points[k].y,length*.5)
  var d:=center+Vector3(points[j].x+.012,points[j].y,length*.5)
  quad_patch(shell,a,bb,c,d)
  var uvj:=points[j]/(radius*2.0)+Vector2(.5,.5);var uvk:=points[k]/(radius*2.0)+Vector2(.5,.5)
  emit_triangle(ends,center+Vector3(0,0,-length*.5),bb,a,Vector2(.5,.5),uvk,uvj)
  emit_triangle(ends,center+Vector3(.012,0,length*.5),d,c,Vector2(.5,.5),uvj,uvk)
 add_mesh("IrregularBarkShell",shell,bark)
 add_mesh("CutFacesWithGrowthRings",ends,endgrain)
 if split:
  b("ExposedSplitWood",center+Vector3(.005,radius*.205,0),Vector3(radius*1.65,.004,length*.98),timber,.001)

func firewood() -> void:
 for row in range(3):
  var count:=4-row
  for i in range(count):
   var radius:=.095+rng.randf_range(-.009,.009)
   var center:=Vector3((i-float(count-1)*.5)*.205,.102+row*.173,rng.randf_range(-.02,.02))
   split_log(center,radius,.50+rng.randf_range(-.05,.05),rng.randf()*TAU,row==2 or i%3==0)
 collision_box(Vector3(0,.26,0),Vector3(.83,.52,.59))

func mushrooms() -> void:
 for i in range(9):
  var angle:=i*2.399;var distance:=.025+i*.024
  var x:=sin(angle)*distance;var z:=cos(angle)*distance
  var h:=rng.randf_range(.068,.16);var radius:=rng.randf_range(.028,.061)
  var base:=Vector3(x,0,z);var neck:=Vector3(x+.008,h,z-.005)
  pipe("CurvingStemBase",base,base.lerp(neck,.45)+Vector3(.004,0,0),.007,extra_mats.stem)
  pipe("CurvingStemUpper",base.lerp(neck,.45)+Vector3(.004,0,0),neck,.006,extra_mats.stem)
  var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
  var profile:=[Vector2(0,.54),Vector2(.30,.51),Vector2(.65,.34),Vector2(.90,.12),Vector2(1,0),Vector2(.96,-.055),Vector2(.45,-.10),Vector2(0,-.08)]
  for j in range(profile.size()-1):
   for k in range(32):
    var pts:Array[Vector3]=[]
    for ind in [Vector2i(k,j),Vector2i(k+1,j),Vector2i(k+1,j+1),Vector2i(k,j+1)]:
     var a:=float(ind.x)*TAU/32.0;var pr:Vector2=profile[ind.y]
     var rr:=pr.x*radius*(1.0+.025*sin(a*5.0+i))
     pts.append(neck+Vector3(cos(a)*rr,pr.y*radius,sin(a)*rr))
    quad_patch(st,pts[0],pts[1],pts[2],pts[3])
  add_mesh("OrganicCapWithRolledLip",st,extra_mats.cap)
  var gills:=SurfaceTool.new();gills.begin(Mesh.PRIMITIVE_TRIANGLES)
  for k in range(24):
   var a:=k*TAU/24.0
   var start:=neck+Vector3(cos(a)*radius*.2,-radius*.09,sin(a)*radius*.2)
   var end:=neck+Vector3(cos(a)*radius*.9,-radius*.04,sin(a)*radius*.9)
   emit_triangle(gills,start,end,start.lerp(end,.5)-Vector3.UP*.0015)
  add_mesh("UndersideGills",gills,extra_mats.stem)

func grass() -> void:
 var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
 for i in range(64):
  var angle:=i*2.399;var height:=rng.randf_range(.20,.62)
  var extent:=rng.randf_range(.09,.29);var width:=rng.randf_range(.004,.009)
  var base:=Vector3(sin(angle)*rng.randf_range(0,.045),0,cos(angle)*rng.randf_range(0,.045))
  var side:=Vector3(cos(angle),0,-sin(angle))
  var tint:=Color(rng.randf_range(.84,1.15),rng.randf_range(.88,1.10),rng.randf_range(.86,1.04))
  st.set_color(tint)
  for j in range(7):
   var points:Array[Vector3]=[]
   var uvs:Array[Vector2]=[]
   for ij in [Vector2i(0,j),Vector2i(1,j),Vector2i(1,j+1),Vector2i(0,j+1)]:
    var t:=float(ij.y)/7.0
    var mid:=base+Vector3(sin(angle)*extent*t*t,height*(t-.13*t*t*t),cos(angle)*extent*t*t)
    var pos:=mid+side*(float(ij.x)*2.0-1.0)*width*(1.0-t)*(.8+.2*sin(t*PI))
    points.append(pos);uvs.append(Vector2(float(ij.x),t))
   emit_triangle(st,points[0],points[1],points[2],uvs[0],uvs[1],uvs[2])
   emit_triangle(st,points[0],points[2],points[3],uvs[0],uvs[2],uvs[3])
 add_mesh("CurvedTaperedBlades",st,extra_mats.grass)
 for i in range(6):
  var a:=i*2.399;var top:=Vector3(sin(a)*.08,.42+float(i)*.025,cos(a)*.08)
  pipe("DrySeedStem",Vector3.ZERO,top,.0015,rust)
  for j in range(5):
   var at:=top-Vector3.UP*(j*.012)
   pipe("SeedHead",at,at+Vector3(.012*sin(a+j),.007,.012*cos(a+j)),.0018,rust)

func rocks() -> void:
 for i in range(11):
  var angle:=i*2.399;var dist:=.08+float(i)*.046
  var sphere:=SphereMesh.new();sphere.radius=.065+float(i%4)*.022;sphere.height=sphere.radius*1.5;sphere.radial_segments=14;sphere.rings=7
  var arrays:=sphere.surface_get_arrays(0)
  var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
  var minimum:=100.0
  for v in range(vertices.size()):
   var p:=vertices[v]
   var distortion:=1.0+.18*sin(p.x*41+i)*cos(p.z*33+i*.7)+.1*sin(p.y*72+i)
   p*=distortion;p.x*=1.15;p.z*=.80;p.y*=.82
   vertices[v]=p;minimum=minf(minimum,p.y)
  var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
  var indices:PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
  for idx in indices:
   var v:=vertices[idx];v.y-=minimum
   st.set_color(Color.WHITE.darkened(.07*float(i%4)))
   st.set_uv(Vector2(v.x,v.z));st.add_vertex(v+Vector3(sin(angle)*dist,0,cos(angle)*dist))
  add_mesh("IrregularGroundedStone",st,extra_mats.stone)

func build_extra(id: String) -> Node3D:
 root=StaticBody3D.new() if id in ["wood_sawhorse","garden_shovel","scrap_sheet","firewood_stack"] else Node3D.new()
 root.name=id.to_pascal_case();rng.seed=hash(id)
 match id:
  "wood_sawhorse":sawhorse()
  "garden_shovel":shovel()
  "scrap_sheet":sheet()
  "firewood_stack":firewood()
  "mushroom_cluster":mushrooms()
  "dry_grass_tuft":grass()
  "stone_scatter":rocks()
 merge_meshes()
 for child in root.get_children():
  if child is MeshInstance3D:
   child.name="Surface_"+str(child.get_index())
 root.set_meta("prop_id",id)
 root.set_meta("display_name",TITLES[id])
 root.set_meta("approximate_size_metres",EXTRA_CATALOG[id])
 root.set_meta("world_text_policy","No attached text")
 root.set_meta("asset_revision",2)
 return root



