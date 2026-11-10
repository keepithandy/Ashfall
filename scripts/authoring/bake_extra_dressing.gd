extends SceneTree
func _initialize() -> void:
 var builder=load("res://scripts/authoring/extra_dressing_builder.gd").new()
 builder.prepare_extra_materials()
 DirAccess.make_dir_recursive_absolute("res://scenes/extra_dressing")
 var records:Array[Dictionary]=[]
 for id: String in builder.EXTRA_CATALOG:
  var prop: Node3D=builder.build_extra(id)
  var bb:=AABB();var first:=true
  for child in prop.get_children():
   child.owner=prop
   if child is MeshInstance3D:
    var part: AABB=child.transform*child.get_aabb()
    bb=part if first else bb.merge(part);first=false
  prop.set_meta("approximate_size_metres",bb.size)
  var packed:=PackedScene.new()
  if packed.pack(prop)!=OK or ResourceSaver.save(packed,"res://scenes/extra_dressing/"+id+".tscn")!=OK:
   push_error("Failed to save "+id);quit(1);return
  records.append({"id":id,"title":builder.TITLES[id],"scene":"res://scenes/extra_dressing/"+id+".tscn","approximate_size_metres":str(bb.size),"revision":2})
  prop.free()
 build_gallery(builder)
 var f:=FileAccess.open("res://assets/extra_dressing/catalog.json",FileAccess.WRITE)
 f.store_string(JSON.stringify(records,"\t"))
 print("EXTRA_PROPS_BAKED: ",builder.EXTRA_CATALOG.size()," ordinary scenes + named gallery")
 quit()

func build_gallery(builder: RefCounted) -> void:
 var gallery:=Node3D.new();gallery.name="ExtraDressingGallery"
 gallery.set_script(load("res://scripts/review/extra_dressing_gallery.gd"))
 var displays:=Node3D.new();displays.name="Displays";gallery.add_child(displays);displays.owner=gallery
 var pad_material:=StandardMaterial3D.new();pad_material.albedo_color=Color("303d40");pad_material.roughness=.85
 var short_titles:=["Timber sawhorse","Garden shovel","Corrugated steel","Firewood stack","Woodland mushrooms","Dry meadow grass","Stone scatter"]
 var coords:=[Vector3(-4.2,0,-1.9),Vector3(-1.4,0,-1.9),Vector3(1.4,0,-1.9),Vector3(4.2,0,-1.9),Vector3(-2.8,0,1.8),Vector3(0,0,1.8),Vector3(2.8,0,1.8)]
 var index:=0
 for id: String in builder.EXTRA_CATALOG:
  var cell:=Node3D.new();cell.name=id;cell.position=coords[index];cell.set_meta("title",short_titles[index]);cell.set_meta("id",id)
  displays.add_child(cell);cell.owner=gallery
  var prop:Node3D=load("res://scenes/extra_dressing/"+id+".tscn").instantiate()
  prop.name="WorldAsset";prop.position.y=.14;cell.add_child(prop);prop.owner=gallery
  var pad:=MeshInstance3D.new();pad.name="DisplayPlinth"
  var mesh:=BoxMesh.new();mesh.size=Vector3(2.2,.14,2.05);pad.mesh=mesh;pad.position.y=.07;pad.material_override=pad_material
  cell.add_child(pad);pad.owner=gallery
  var label:=Label3D.new();label.name="GalleryName";label.text="%02d  /  %s"%[index+1,short_titles[index]]
  label.position=Vector3(0,.33,1.08);label.font_size=44;label.pixel_size=.0035;label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;label.no_depth_test=true;label.modulate=Color("e0d9c7");label.outline_size=6
  cell.add_child(label);label.owner=gallery
  var dims:Vector3=prop.get_meta("approximate_size_metres")
  var desc:=Label3D.new();desc.name="GallerySize";desc.text="%.2f × %.2f × %.2f m"%[dims.x,dims.y,dims.z]
  desc.position=Vector3(0,.13,1.15);desc.font_size=32;desc.pixel_size=.0032;desc.billboard=BaseMaterial3D.BILLBOARD_ENABLED;desc.no_depth_test=true;desc.modulate=Color("97b3b1");desc.outline_size=5
  cell.add_child(desc);desc.owner=gallery
  index+=1
 var camera:=Camera3D.new();camera.name="Camera";camera.current=true;gallery.add_child(camera);camera.owner=gallery;camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=8.2;camera.transform=Transform3D(Basis.looking_at(Vector3(0,0.05,0)-Vector3(0,10.6,12.8)),Vector3(0,10.6,12.8))
 var light:=DirectionalLight3D.new();light.name="Key";light.rotation_degrees=Vector3(-48,-28,0);light.light_color=Color("ffe6c6");light.light_energy=1.35;light.shadow_enabled=true;gallery.add_child(light);light.owner=gallery
 var fill:=DirectionalLight3D.new();fill.name="Fill";fill.rotation_degrees=Vector3(-32,135,0);fill.light_color=Color("c4d8e4");fill.light_energy=.55;gallery.add_child(fill);fill.owner=gallery
 var world:=WorldEnvironment.new();world.name="Environment";var env:=Environment.new()
 env.background_mode=Environment.BG_COLOR;env.background_color=Color("1f282d");env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color("bbc9d0");env.ambient_light_energy=.65;env.tonemap_mode=Environment.TONE_MAPPER_FILMIC
 world.environment=env;gallery.add_child(world);world.owner=gallery
 var packed:=PackedScene.new();packed.pack(gallery)
 ResourceSaver.save(packed,"res://scenes/extra_dressing_gallery.tscn")
 gallery.free()


