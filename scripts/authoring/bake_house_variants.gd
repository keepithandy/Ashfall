extends SceneTree
func _initialize() -> void:
	var builder = load("res://scripts/authoring/house_variants_builder.gd").new()
	for i in range(3):
		var house: Node3D = builder.build_variant(i)
		own(house,house)
		var packed := PackedScene.new()
		assert(packed.pack(house)==OK)
		assert(ResourceSaver.save(packed,"res://scenes/houses/"+["ochre_workers_house","green_longhouse","white_garden_house"][i]+".tscn")==OK)
		house.free()
	print("Three house variants baked")
	quit()
func own(node: Node, scene: Node) -> void:
	for child in node.get_children():
		child.owner=scene
		own(child,scene)
