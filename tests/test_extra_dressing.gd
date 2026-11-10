extends SceneTree
var failures:=0
var measured:Array[Dictionary]=[]
func check(ok: bool,message: String) -> void:
 if not ok:failures+=1;push_error(message)
func _initialize() -> void:call_deferred("run")
func mesh_bounds(node: Node3D) -> AABB:
 var bb:=AABB();var first:=true
 for mesh in node.find_children("*","MeshInstance3D",true,false):
  var part: AABB=mesh.transform*mesh.get_aabb()
  bb=part if first else bb.merge(part);first=false
 return bb
func run() -> void:
 var ids=["wood_sawhorse","garden_shovel","scrap_sheet","firewood_stack","mushroom_cluster","dry_grass_tuft","stone_scatter"]
 for id in ids:
  var scene=load("res://scenes/extra_dressing/"+id+".tscn")
  check(scene is PackedScene,"Missing world scene "+id)
  if scene==null:continue
  var n:Node3D=scene.instantiate();root.add_child(n)
  check(n.transform==Transform3D.IDENTITY,"Non-default world origin/scale "+id)
  check(n.find_children("*","Label3D",true,false).is_empty(),"World scene contains text "+id)
  check(n.find_children("*","Camera3D",true,false).is_empty(),"World scene contains gallery camera "+id)
  var mesh_nodes=n.find_children("*","MeshInstance3D",true,false)
  check(not mesh_nodes.is_empty(),"No visible geometry "+id)
  check(mesh_nodes.size()<=5,"Excessive mesh count "+id)
  var triangles:=0
  for mesh in mesh_nodes:
   check(mesh.material_override!=null,"Missing material "+id)
   for surface in range(mesh.mesh.get_surface_count()):
    var arrays=mesh.mesh.surface_get_arrays(surface)
    var verts:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
    var indices:PackedInt32Array=arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX]!=null else PackedInt32Array()
    triangles+=int((indices.size() if not indices.is_empty() else verts.size())/3)
    check(arrays[Mesh.ARRAY_NORMAL]!=null,"Missing surface normals "+id)
    for v in verts:check(v.is_finite(),"Invalid vertex "+id)
  var shapes=n.find_children("*","CollisionShape3D",true,false)
  if id in ids.slice(0,4):check(not shapes.is_empty(),"No prop collision "+id)
  else:check(shapes.is_empty(),"Small foliage has blocking collision "+id)
  var bb:=mesh_bounds(n)
  check(bb.position.y>=-.012,"Geometry sinks below origin "+id)
  check(bb.size.x>.01 and bb.size.y>.01 and bb.size.z>.01,"Degenerate bounds "+id)
  check(triangles<25000,"Excessive triangle count "+id)
  measured.append({"id":id,"meshes":mesh_nodes.size(),"triangles":triangles,"bounds_m":str(bb.size),"collision_shapes":shapes.size()})
  print("CHECKED ",id," / ",triangles," triangles / ",mesh_nodes.size()," surfaces / bounds ",bb.size)
  n.free()
 # Physical clearance beneath sawhorse, with a blocking top surface.
 var trestle=load("res://scenes/extra_dressing/wood_sawhorse.tscn").instantiate()
 root.add_child(trestle)
 await physics_frame
 await physics_frame
 var space=trestle.get_world_3d().direct_space_state
 check(space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(0,.10,1),Vector3(0,.10,-1))).is_empty(),"Sawhorse blocks clearance between legs")
 check(not space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(0,1,0),Vector3(0,.6,0))).is_empty(),"Sawhorse top does not collide")
 trestle.free()
 var gallery=load("res://scenes/extra_dressing_gallery.tscn").instantiate()
 root.add_child(gallery)
 await process_frame
 check(gallery.get_node("Displays").get_child_count()==7,"Gallery does not contain seven displays")
 check(gallery.find_children("*","Label3D",true,false).size()==14,"Gallery name and size labels missing")
 for i in range(7):
  var cell=gallery.get_node("Displays").get_child(i)
  var prop=cell.get_node("WorldAsset")
  check(prop.scene_file_path=="res://scenes/extra_dressing/"+ids[i]+".tscn","Gallery uses a separate asset copy")
  check(prop.scale==Vector3.ONE,"Gallery asset changed world scale")
  gallery.focus_asset(i)
  check(gallery.selected_index==i,"Gallery focus failed")
  check(gallery.get_node("Camera").position.is_finite(),"Invalid focused camera")
 var key:=InputEventKey.new();key.pressed=true;key.keycode=KEY_2;gallery._unhandled_input(key)
 check(gallery.selected_index==1,"Number key selection failed")
 var old_distance:float=gallery.distance
 var wheel:=InputEventMouseButton.new();wheel.pressed=true;wheel.button_index=MOUSE_BUTTON_WHEEL_UP;gallery._unhandled_input(wheel)
 check(gallery.distance<old_distance,"Gallery zoom failed")
 gallery.show_overview()
 check(gallery.selected_index==-1,"Overview control failed")
 for cell in gallery.get_node("Displays").get_children():check(cell.visible,"Overview hides an asset")
 gallery.free()
 var f:=FileAccess.open("res://assets/extra_dressing/validation.json",FileAccess.WRITE)
 f.store_string(JSON.stringify({"failures":failures,"assets":measured},"\t"))
 print("RESULT: ",failures," failure(s)")
 quit(1 if failures else 0)
