extends SceneTree
## Exercise the actual player adapter, animation blend tree and skeleton constraints.
var errors := 0
var player: CharacterBody3D
var character: Node3D

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		errors += 1
		push_error("CHARACTER_FAIL: " + message)

func settle(frames: int = 8) -> void:
	for i in range(frames):
		await physics_frame
		await process_frame

func present(velocity: Vector3, crouch: bool = false, grounded: bool = true, retract: float = 0.0) -> void:
	player.velocity = velocity
	character.animate_motion(1.0/30.0, velocity.length()/6.4, 0.5, crouch, grounded, Vector2.ZERO, true, retract)

func run() -> void:
	var stage := Node3D.new()
	root.add_child(stage)
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(12,0.2,12)
	shape.shape = box
	ground.add_child(shape)
	ground.position.y = -0.1
	stage.add_child(ground)
	player = CharacterBody3D.new()
	player.set_script(load("res://scripts/runtime/player.gd"))
	stage.add_child(player)
	player.set_physics_process(false)
	player.active = true
	character = player.body_model
	var skel: Skeleton3D = character.skeleton
	check(skel.get_bone_count() == 58, "Full humanoid skeleton must import the hand socket and forearm twist support")
	for bone in ["head","pelvis","spine","chest","thigh.R","shin.L","foot.R","hand.L","index3.R","thumb3.L","item.R"]:
		check(skel.find_bone(bone) >= 0, "Missing deform bone: " + bone)
	for part in ["MaleMannequinBody","Head"]:
		var mesh: MeshInstance3D = character.model.find_child(part, true, false)
		check(is_instance_valid(mesh) and mesh.skin != null, "Missing skinned body component: " + part)
	check(character.held_items!=null and character.held_items.active_grip.item_id==&"flashlight","Default held flashlight did not equip")
	check(character.animator.get_animation_list().size() >= 9, "Locomotion clips were lost on export")
	check(player.camera.get_cull_mask_value(1) and not player.camera.get_cull_mask_value(2), "First-person head exclusion must preserve the body")
	check(character.shadows.size() == 3, "Mannequin head and eyes must preserve the whole shadow")
	for clothing in ["Jacket","Trousers","Boots","Hair","Gloves","Satchel","Equipment"]:
		check(character.model.find_child(clothing,true,false)==null,"Dressed character asset is still being used: "+clothing)
	var head_mesh: MeshInstance3D = character.model.find_child("Head",true,false)
	var body_mesh: MeshInstance3D = character.model.find_child("MaleMannequinBody",true,false)
	check(head_mesh.mesh.get_surface_count()>0 and body_mesh.mesh.get_surface_count()>0,"First-person head partition lost the body or head")
	var original: Node3D = load("res://assets/characters/mannequin_player/mannequin_player.glb").instantiate()
	var original_body: MeshInstance3D = original.find_child("MaleMannequinBody",true,false)
	var original_indices := 0
	var partitioned_indices := 0
	for surface in range(original_body.mesh.get_surface_count()):
		original_indices += original_body.mesh.surface_get_array_index_len(surface)
	for mesh in [body_mesh,head_mesh]:
		for surface in range(mesh.mesh.get_surface_count()):
			partitioned_indices += mesh.mesh.surface_get_array_index_len(surface)
	check(original_indices==partitioned_indices,"First-person head visibility removed or duplicated source triangles")
	original.free()
	check(not is_instance_valid(player.find_child("FirstPersonHands",true,false)), "Old camera arms must not be duplicated")
	present(Vector3.ZERO)
	await settle()
	var camera_start: Transform3D = player.camera.transform
	var light_start: Vector3 = player.torch.global_position
	var head_start := skel.get_bone_global_pose(skel.find_bone("head")).origin
	check((-player.torch.global_basis.z).dot(-player.camera.global_basis.z)>0.98, "Held beam does not follow aim")
	check(player.torch.global_position.distance_to(player.camera.global_position)<0.8, "Held item escaped the player's reach")
	present(Vector3(0,0,-3.5))
	await settle(10)
	var leg_start := skel.get_bone_pose_rotation(skel.find_bone("thigh.L"))
	await settle(12)
	check(leg_start.angle_to(skel.get_bone_pose_rotation(skel.find_bone("thigh.L")))>0.02, "Walk blend is not animating the legs")
	for i in range(12):
		present(Vector3.ZERO,true)
		await settle(1)
	var head_crouched := skel.get_bone_global_pose(skel.find_bone("head")).origin
	check(head_crouched.y < head_start.y-0.35, "Crouch did not lower the articulated body")
	var shin_index := skel.find_bone("shin.L")
	check(skel.get_bone_pose_rotation(shin_index).angle_to(skel.get_bone_rest(shin_index).basis.get_rotation_quaternion())>0.8, "Crouch is scaling the body instead of bending the knee")
	check(player.camera.transform.is_equal_approx(camera_start), "Body presentation moved the stable camera")
	for i in range(12):
		present(Vector3.ZERO)
		await settle(1)
	player.camera.rotation.x = -0.9
	await settle()
	check((-player.torch.global_basis.z).dot(-player.camera.global_basis.z)>0.98, "Downward aim lost the hand-mounted beam")
	player.camera.rotation.x = 0
	present(Vector3.ZERO,false,true,0.6)
	await settle()
	check(player.torch.global_position.z > light_start.z+0.12, "Near-wall pose did not retract the real arm")
	check((-player.torch.global_basis.z).y < -0.2, "Near-wall pose did not lower the light")
	# Raise the ground under the right foot; the leg must adapt within its safe reach.
	var step := StaticBody3D.new()
	var step_shape := CollisionShape3D.new()
	var step_box := BoxShape3D.new()
	step_box.size = Vector3(0.18,0.08,0.35)
	step_shape.shape = step_box
	step.add_child(step_shape)
	var rest_ankle := skel.get_bone_global_rest(skel.find_bone("foot.R")).origin
	step.position = Vector3(rest_ankle.x,0.04,rest_ankle.z)
	stage.add_child(step)
	present(Vector3.ZERO)
	await settle(8)
	var ankle: Vector3 = character.pose_modifier.foot_contacts.get("R", Vector3.ZERO)
	print("CHARACTER_FOOT_SAMPLE: ",ankle)
	check(absf(ankle.y-rest_ankle.y-0.08)<0.02, "Foot constraint did not adapt to the raised surface")
	player.active = false
	await settle(2)
	var frozen := skel.get_bone_pose_rotation(skel.find_bone("chest"))
	var frozen_light: Transform3D = player.torch.global_transform
	await settle(8)
	check(not character.animation_tree.active and skel.get_bone_pose_rotation(skel.find_bone("chest")).is_equal_approx(frozen), "Character keeps animating while paused")
	check(player.torch.global_transform.is_equal_approx(frozen_light), "Pausing resets the held arm or flashlight")
	print("FULL_BODY_CHARACTER_CHECK: failures=",errors)
	stage.queue_free()
	await process_frame
	quit(1 if errors else 0)
