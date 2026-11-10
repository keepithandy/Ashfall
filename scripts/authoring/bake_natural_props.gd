extends SceneTree

func _initialize() -> void:
	var script = load("res://scripts/authoring/natural_prop_builder.gd")
	if not script.can_instantiate():
		quit(1)
		return
	var builder = script.new()
	builder.prepare_natural_materials()
	DirAccess.make_dir_recursive_absolute("res://scenes/nature")
	var manifest: Array[Dictionary] = []
	for id: String in builder.NATURAL_CATALOG:
		var prop: Node3D = builder.build_natural(id)
		set_owners(prop,prop)
		var scene := PackedScene.new()
		scene.pack(prop)
		var path := "res://scenes/nature/"+id+".tscn"
		if ResourceSaver.save(scene,path) != OK:
			push_error("Could not save natural prop: "+id)
			quit(1)
			return
		manifest.append({"id":id,"scene":path,"size_metres":str(builder.NATURAL_CATALOG[id]),"meshes":prop.find_children("*","MeshInstance3D",true,false).size()})
		prop.free()
	var file := FileAccess.open("res://assets/nature/catalog.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest,"\t"))
	file.close()
	build_landscaping()
	build_service_yards()
	build_gallery()
	print("NATURE_BAKED: ",manifest.size()," reusable text-free scenes; material-merged meshes; landscaping and yard scenes")
	quit()

func set_owners(node: Node, scene: Node) -> void:
	for child in node.get_children():
		child.owner = scene
		set_owners(child,scene)

func place(parent: Node3D, folder: String, id: String, at: Vector3, yaw: float = 0, scale_value: float = 1) -> void:
	var prop: Node3D = load(folder+id+".tscn").instantiate()
	prop.name = id+"_"+str(parent.get_child_count())
	prop.position = at
	prop.rotation.y = yaw
	prop.scale = Vector3.ONE*scale_value
	parent.add_child(prop)
	prop.owner = parent

func save_scene(root: Node3D, path: String) -> void:
	var scene := PackedScene.new()
	scene.pack(root)
	ResourceSaver.save(scene,path)
	root.free()

func build_landscaping() -> void:
	var root := Node3D.new()
	root.name = "NaturalLandmarks"
	var folder := "res://scenes/nature/"
	var rng := RandomNumberGenerator.new()
	rng.seed = 90941
	# Distinct natural clusters rather than an even scatter across every surface.
	var clusters := [
		Vector3(-17,0,18),Vector3(17,0,23),Vector3(-27,0,4),Vector3(25,0,-12),
		Vector3(-24,0,-23),Vector3(-21,0,-36),Vector3(26,0,-46),Vector3(13,0,-48)
	]
	for center in clusters:
		place(root,folder,"mossy_boulder",center,rng.randf_range(0,TAU),rng.randf_range(0.8,1.4))
		place(root,folder,"tree_stump",center+Vector3(1.7,0,0.7),rng.randf_range(0,TAU))
		place(root,folder,"fallen_log",center+Vector3(-1.4,0,-1.7),rng.randf_range(0,TAU))
		place(root,folder,"dead_branch_pile",center+Vector3(-2,0,1),rng.randf_range(0,TAU))
		for i in range(9):
			var at: Vector3 = center+Vector3(rng.randf_range(-3.3,3.3),0,rng.randf_range(-3.3,3.3))
			# Keep the station and the right checkpoint house free of planting.
			if Rect2(-15.5,-38,13.2,14).has_point(Vector2(at.x,at.z)) or Rect2(6,7.4,8.5,7.8).has_point(Vector2(at.x,at.z)):
				continue
			place(root,folder,"fern_clump" if i%3 else "low_shrub",at,rng.randf_range(0,TAU),rng.randf_range(0.65,1.15))
	for z in [-16.9,-13,-9,-5,-2.8]:
		place(root,folder,"reed_clump",Vector3(-24.2,0,z),rng.randf_range(0,TAU))
		place(root,folder,"reed_clump",Vector3(-12.3,0,z),rng.randf_range(0,TAU),0.8)
	for i in range(14):
		var x := -28.8 if i%2==0 else 28.8
		place(root,folder,"dry_bramble",Vector3(x,0,26-i*5.6),rng.randf_range(0,TAU),rng.randf_range(0.7,1.2))
	for at in [Vector3(-26,0,-31),Vector3(27,0,-18),Vector3(23,0,23),Vector3(-23,0,24)]:
		place(root,folder,"bare_tree",at,rng.randf_range(0,TAU),rng.randf_range(0.9,1.2))
	# Replace the old cone trees with a shared, branched pine mesh and bare snags.
	for i in range(140):
		var x := rng.randf_range(-75,75)
		var z := rng.randf_range(-85,58)
		if absf(x)<35 and z > -58 and z<36:
			continue
		place(root,folder,"bare_tree" if i%7==0 else "forest_pine",Vector3(x,0,z),rng.randf_range(0,TAU),rng.randf_range(0.8,1.65))
	save_scene(root,"res://scenes/natural_landmarks.tscn")

func build_service_yards() -> void:
	var root := Node3D.new()
	root.name = "PerimeterDressing"
	var placements := [
		["wooden_pallet",Vector3(-17.3,0,-29),0.2],
		["shipping_crate",Vector3(-17.3,0.144,-29),0.2],
		["equipment_case",Vector3(-17.3,0.864,-29),0.2],
		["portable_generator",Vector3(-17.3,0,-33),PI/2],
		["gas_cylinder",Vector3(-16.5,0,-35),0],
		["steel_drum",Vector3(-19,0,-30.6),0.1],
		["rusted_drum",Vector3(-19.7,0,-31.2),0],
		["wall_fusebox",Vector3(-15.3,1.1,-28),-PI/2],
		["work_light",Vector3(-5,0,-23.5),-0.7],
		["jerrycan",Vector3(-16.6,0,-32.2),0.2],
		["steel_drum",Vector3(10,0,-7),0.2],
		["rusted_drum",Vector3(10.65,0,-7.3),0],
		["wooden_pallet",Vector3(9.7,0,-9.4),0.1],
		["shipping_crate",Vector3(9.7,0.144,-9.4),0.1],
		["tool_box",Vector3(9.7,0.864,-9.4),0],
		["pipe_bundle",Vector3(22,0,-5),0.2],
		["cable_spool",Vector3(22,0,-10),0.1],
		["hand_truck",Vector3(20.3,0,-3),0.3],
		["traffic_cone",Vector3(11,0,-2.5),0],
		["electrical_cabinet",Vector3(26.5,0,-34),0.2],
		["valve_pipe",Vector3(27,0,-39),0],
		["pipe_bundle",Vector3(27,0,-37),PI/2],
		["damaged_fence",Vector3(18,0,-43.8),0],
		["damaged_fence",Vector3(20,0,-43.8),0],
		["damaged_fence",Vector3(22,0,-43.8),0],
		["damaged_fence",Vector3(24,0,-43.8),0],
		["wooden_bench",Vector3(15.5,0,15.8),0],
		["wooden_pallet",Vector3(17.4,0,17),0.1],
		["shipping_crate",Vector3(17.4,0.144,17),0.1],
		["rusted_drum",Vector3(17.2,0,15.3),0.2],
		["rubble_pile",Vector3(-29,0,-42),0],
		["rubble_pile",Vector3(27,0,2),0.2],
		["rubble_pile",Vector3(-20.3,0,-26),0.4]
	]
	for p in placements:
		place(root,"res://scenes/props/",p[0],p[1],p[2])
	save_scene(root,"res://scenes/perimeter_dressing.tscn")

func build_gallery() -> void:
	var gallery := Node3D.new()
	gallery.name = "NaturalPropGallery"
	gallery.set_script(load("res://scripts/review/prop_gallery.gd"))
	var displays := Node3D.new()
	displays.name = "Displays"
	gallery.add_child(displays)
	displays.owner = gallery
	var builder = load("res://scripts/authoring/natural_prop_builder.gd").new()
	var index := 0
	for id: String in builder.NATURAL_CATALOG:
		var display := Node3D.new()
		display.name = id
		display.position = Vector3((index%6-2.5)*2.8,0,-(index/6)*3)
		display.set_meta("title",id.replace("_"," ").capitalize())
		displays.add_child(display)
		display.owner = gallery
		var prop: Node3D = load("res://scenes/nature/"+id+".tscn").instantiate()
		prop.position.y = 0.08
		if id in ["forest_pine","bare_tree"]:
			prop.scale = Vector3.ONE*0.24
		display.add_child(prop)
		prop.owner = gallery
		var label := Label3D.new()
		label.name = "Caption"
		label.text = id.replace("_"," ").capitalize()+ (" (display at 24%)" if id in ["forest_pine","bare_tree"] else "")
		label.font_size = 24
		label.pixel_size = 0.0035
		label.position = Vector3(0,0.16,1.12)
		display.add_child(label)
		label.owner = gallery
		index += 1
	var scene := PackedScene.new()
	scene.pack(gallery)
	ResourceSaver.save(scene,"res://scenes/natural_gallery.tscn")
	gallery.free()
