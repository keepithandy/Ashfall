extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var player: CharacterBody3D = CharacterBody3D.new()
	player.set_script(load("res://scripts/runtime/player.gd"))
	root.add_child(player)
	player.set_physics_process(false)
	player.active=true
	var character: Node3D = player.body_model
	character.floor_ik_enabled=false
	for i in range(50):await physics_frame
	for finger in ["index","middle","ring","pinky","thumb"]:
		var controller: HeldItemController=character.held_items
		var goal: Vector3=controller.item.to_global(controller.active_grip.contact_targets[finger])
		var actual: Vector3=controller.contact_positions[finger]
		print("ACTUAL_GRIP ",finger," error_mm=",goal.distance_to(actual)*1000," goal=",goal," actual=",actual)
	var skeleton: Skeleton3D=character.skeleton
	for bone in ["hand.R","index1.R","index3.R"]:
		print("BONE_REST ",bone," ",skeleton.get_bone_global_rest(skeleton.find_bone(bone)))
	print("ITEM_ATTACH ",character.held_items.item.transform)
	print("ITEM_X_AXIS ",character.held_items.item.transform.basis.x)
	print("SERIALIZATION ",var_to_str(Transform3D(Basis(Vector3(1,2,3),Vector3(4,5,6),Vector3(7,8,10)),Vector3.ZERO)))
	character.pose_modifier.active=false
	character.animation_tree.active=false
	skeleton.reset_bone_poses()
	await process_frame
	await process_frame
	print("REST_ITEM_FORWARD ",-character.held_items.item.global_basis.z," expected ",character.held_items.active_grip.aim_forward)
	print("REST_ITEM_CENTER ",character.held_items.item.global_position)
	quit()
