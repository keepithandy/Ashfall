extends SceneTree
func _initialize() -> void:
	var script=load("res://village_house_builder.gd")
	if not script.can_instantiate():
		quit(1)
		return
	var builder=script.new()
	var house: Node3D=builder.build_cottage()
	set_owners(house,house)
	DirAccess.make_dir_recursive_absolute("res://scenes/houses")
	var packed:=PackedScene.new()
	packed.pack(house)
	ResourceSaver.save(packed,"res://scenes/houses/blue_porch_cottage.tscn")
	house.free()
	var village:=Node3D.new()
	village.name="VillageLayout"
	var cottage: Node3D=load("res://scenes/houses/blue_porch_cottage.tscn").instantiate()
	cottage.name="FirstVillageCottage"
	cottage.position=Vector3(-46,0,8)
	village.add_child(cottage)
	cottage.owner=village
	var ground_mat: Material=builder.plain(Color("524b3d"))
	for data in [Vector4(-46,20,30,2.7),Vector4(-46,16,2.3,9),Vector4(-60,5,2.7,31)]:
		var path:=MeshInstance3D.new()
		path.name="VillageDirtLane"
		var shape:=BoxMesh.new()
		shape.size=Vector3(data.z,0.02,data.w)
		path.mesh=shape
		path.position=Vector3(data.x,-0.006,data.y)
		path.material_override=ground_mat
		village.add_child(path)
		path.owner=village
	for at in [Vector3(-51,0,15),Vector3(-41,0,15)]:
		for i in range(4):
			var post:=MeshInstance3D.new()
			var cube:=BoxMesh.new()
			cube.size=Vector3(0.1,0.9,0.1)
			post.mesh=cube
			post.position=at+Vector3(0,0.45,i*0.75)
			post.material_override=builder.timber
			village.add_child(post)
			post.owner=village
	var scene:=PackedScene.new()
	for data in [["FutureHousePlot_B",Vector3(-63,0,8)],["FutureHousePlot_C",Vector3(-46,0,-10)]]:
		var plot:=Marker3D.new()
		plot.name=data[0]
		plot.position=data[1]
		village.add_child(plot)
		plot.owner=village
	scene.pack(village)
	ResourceSaver.save(scene,"res://scenes/village_layout.tscn")
	village.free()
	print("VILLAGE_HOUSE_BAKED: distinct cottage, two rooms, porch, village lane, text-free")
	quit()
func set_owners(node: Node,scene: Node) -> void:
	for child in node.get_children():
		child.owner=scene
		if child.scene_file_path.is_empty():
			set_owners(child,scene)
