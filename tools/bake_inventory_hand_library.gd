extends SceneTree
func _initialize() -> void:
	var scene: Node=load("res://assets/characters/inventory_hands/inventory_hand_poses.glb").instantiate()
	var animator: AnimationPlayer=scene.find_children("*","AnimationPlayer",true,false)[0]
	var library := AnimationLibrary.new()
	for name in animator.get_animation_list():
		var short_name := String(name).get_slice("/",String(name).get_slice_count("/")-1)
		if short_name in ["Hand_bandage","Hand_batteries","Hand_water_bottle","Hand_antiseptic","Hand_detector","Hand_field_radio"]:
			library.add_animation(short_name,animator.get_animation(name).duplicate())
	assert(library.get_animation_list().size()==6)
	assert(ResourceSaver.save(library,"res://assets/characters/inventory_hands/hand_poses.res")==OK)
	scene.free()
	print("INVENTORY_HAND_LIBRARY_BAKED: 6 poses")
	quit()
