extends SceneTree

func _initialize() -> void:
	var builder = load("res://scripts/authoring/house_builder.gd").new()
	var house: Node3D = builder.build()
	set_owners(house, house)
	var scene := PackedScene.new()
	var result := scene.pack(house)
	assert(result == OK, "House packing failed")
	DirAccess.make_dir_recursive_absolute("res://scenes")
	result = ResourceSaver.save(scene, "res://scenes/checkpoint_house.tscn")
	assert(result == OK, "House saving failed")
	print("HOUSE_BAKED: ", house.find_children("*", "MeshInstance3D", true, false).size(), " meshes; editable native scene")
	house.free()
	quit()

func set_owners(node: Node, house: Node) -> void:
	for child in node.get_children():
		child.owner = house
		set_owners(child, house)
