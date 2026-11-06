extends SceneTree

func _initialize() -> void:
	var builder = load("res://prop_builder.gd").new()
	builder.prepare_materials()
	DirAccess.make_dir_recursive_absolute("res://scenes/props")
	DirAccess.make_dir_recursive_absolute("res://scenes/props_preview")
	var manifest: Array[Dictionary] = []
	for id: String in builder.CATALOG:
		var prop: Node3D = builder.build_prop(id)
		set_owners(prop,prop)
		var preview_path := "res://scenes/props_preview/"+id+".tscn"
		var preview := PackedScene.new()
		preview.pack(prop)
		ResourceSaver.save(preview,preview_path)
		# Text is permitted only in the asset preview. Default scenes are ready
		# to place in the world without floating or attached lettering.
		for label in prop.find_children("*","Label3D",true,false):
			label.free()
		prop.set_meta("world_text_policy","No attached text")
		var path := "res://scenes/props/"+id+".tscn"
		var packed := PackedScene.new()
		var error := packed.pack(prop)
		if error != OK or ResourceSaver.save(packed,path) != OK:
			push_error("PROP_SAVE_FAILED: "+id)
			quit(1)
			return
		manifest.append({"id":id,"name":builder.CATALOG[id][0],"category":builder.CATALOG[id][1],"scene":path,"preview_scene":preview_path,"size_metres":str(builder.bounds),"origin":"bottom centre","collision_shapes":prop.find_children("*","CollisionShape3D",true,false).size()})
		prop.free()
	var manifest_file := FileAccess.open("res://assets/props/catalog.json",FileAccess.WRITE)
	manifest_file.store_string(JSON.stringify(manifest,"\t"))
	manifest_file.close()
	bake_gallery(builder)
	bake_dressing()
	print("PROPS_BAKED: ",manifest.size()," separate editable scenes; shared materials; gallery")
	quit()

func set_owners(node: Node, scene: Node) -> void:
	for child in node.get_children():
		child.owner = scene
		set_owners(child,scene)

func bake_gallery(builder: RefCounted) -> void:
	var gallery := Node3D.new()
	gallery.name = "PropGallery"
	var script = load("res://prop_gallery.gd")
	gallery.set_script(script)
	var displays := Node3D.new()
	displays.name = "Displays"
	gallery.add_child(displays)
	displays.owner = gallery
	var index := 0
	for id: String in builder.CATALOG:
		var display := Node3D.new()
		display.name = id
		display.position = Vector3((index%6-2.5)*2.8,0,-(index/6)*3.0)
		display.set_meta("title",builder.CATALOG[id][0])
		displays.add_child(display)
		display.owner = gallery
		var prop: Node3D = load("res://scenes/props_preview/"+id+".tscn").instantiate()
		prop.position.y = 0.08
		display.add_child(prop)
		prop.owner = gallery
		var base := MeshInstance3D.new()
		base.name = "DisplayBase"
		var cube := BoxMesh.new()
		cube.size = Vector3(2.3,0.08,2.3)
		base.mesh = cube
		base.position.y = 0.04
		base.material_override = builder.plain(Color("414b4e"))
		display.add_child(base)
		base.owner = gallery
		var label := Label3D.new()
		label.name = "Caption"
		label.text = "%02d  %s" % [index+1,builder.CATALOG[id][0]]
		label.position = Vector3(0,0.18,1.12)
		label.font_size = 28
		label.pixel_size = 0.0038
		label.outline_size = 2
		display.add_child(label)
		label.owner = gallery
		index += 1
	var scene := PackedScene.new()
	scene.pack(gallery)
	ResourceSaver.save(scene,"res://scenes/prop_gallery.tscn")
	gallery.free()

func bake_dressing() -> void:
	var dressing := Node3D.new()
	dressing.name = "CheckpointProps"
	# Positions are in the current level's world coordinates. Keep the entrance,
	# medical-supply sight line, road, and extraction terminal unobstructed.
	var placements := [
		["wooden_pallet",Vector3(-15.7,0,10.3),0.12],
		["shipping_crate",Vector3(-15.7,0.144,10.3),0.12],
		["equipment_case",Vector3(-15.7,0.864,10.3),0.1],
		["steel_drum",Vector3(-15.4,0,12.1),0.2],
		["rusted_drum",Vector3(-16.1,0,12.7),-0.3],
		["gas_cylinder",Vector3(-14.5,0,8.2),0],
		["cable_spool",Vector3(-15.4,0,7),0.4],
		["hand_truck",Vector3(-14.2,0,11),PI/2],
		["portable_generator",Vector3(-5.4,0,9.6),0.15],
		["jerrycan",Vector3(-5.85,0,8.9),-0.2],
		["work_light",Vector3(-5.1,0,8.2),-PI/2],
		["traffic_cone",Vector3(-3.9,0,12.5),0],
		["warning_sign",Vector3(-8.3,0,15.3),0.15],
		["wooden_bench",Vector3(-13,0,15.7),0.05],
		["metal_bucket",Vector3(-13.9,0,14.8),0.2],
		["rubble_pile",Vector3(-12.8,0,17.1),0.2],
		["pipe_bundle",Vector3(-15.3,0,5.2),0.15],
		["electrical_cabinet",Vector3(-14.2,0,6.9),-PI/2],
		["concrete_barrier",Vector3(-18.5,0,15.5),0.05],
		["shelving_unit",Vector3(-7.4,0.18,9.6),0],
		["filing_cabinet",Vector3(-7.4,0.18,8.6),0],
		["tool_box",Vector3(-7.5,0.8375,9.6),0],
		["equipment_case",Vector3(-7.4,1.3575,9.6),0],
		["desk_radio",Vector3(-10.5,0.811,10),0.06],
		["enamel_mug",Vector3(-9.4,0.811,10.15),0.3],
		["radiator",Vector3(-11.9,0.18,8.45),PI],
		["wall_fusebox",Vector3(-6.75,1.3,11.5),PI/2],
		["valve_pipe",Vector3(-14.1,0,10.4),0],
		["damaged_fence",Vector3(-19.7,0,13.6),0.2],
		["sandbag_stack",Vector3(7.9,0,15.4),0.1],
		["field_cot",Vector3(10.6,0.16,10),0],
		["worn_mattress",Vector3(10.6,0.61,10),0]
	]
	var index := 0
	for placement in placements:
		var prop: Node3D = load("res://scenes/props/"+placement[0]+".tscn").instantiate()
		prop.name = str(placement[0])+"_"+str(index)
		prop.position = placement[1]
		prop.rotation.y = placement[2]
		dressing.add_child(prop)
		prop.owner = dressing
		index += 1
	var scene := PackedScene.new()
	scene.pack(dressing)
	ResourceSaver.save(scene,"res://scenes/checkpoint_props.tscn")
	dressing.free()
