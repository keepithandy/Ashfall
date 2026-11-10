extends SkeletonModifier3D
## Post-animation constraints. Never moves the physics capsule or the camera.
var character: Node3D
var indices: Dictionary = {}
var grip := 0.0
var foot_contacts: Dictionary = {}

func index(name: String) -> int:
	if not indices.has(name):
		indices[name] = get_skeleton().find_bone(name)
	return indices[name]

func _process_modification_with_delta(delta: float) -> void:
	if not is_instance_valid(character) or not is_instance_valid(character.view_camera):
		return
	var skel := get_skeleton()
	var camera: Camera3D = character.view_camera
	var skeleton_from_world := skel.global_transform.affine_inverse()
	var camera_forward := (skel.global_basis.inverse() * -camera.global_basis.z).normalized()
	var pitch := asin(clampf(camera_forward.y, -1, 1))
	for pair in [["neck", 0.35], ["head", 0.90]]:
		var bone_index := index(pair[0])
		var pose := skel.get_bone_global_pose(bone_index)
		var wanted := Basis(Vector3.RIGHT, pitch) * skel.get_bone_global_rest(bone_index).basis
		var weight: float = character.character_profile.get("neck_aim_weight",pair[1]) if pair[0]=="neck" else pair[1]
		pose.basis = pose.basis.slerp(wanted, weight)
		skel.set_bone_global_pose(bone_index, pose)
	if character.held_items == null or (character.held_items.aim_profile != null and character.held_items.arm_weight>0.001):
		apply_hand_aim(delta,skel,camera,skeleton_from_world,camera_forward)
	if character.held_items != null:
		var pose_delta := delta
		if character.player.get_script()!=null and not character.player.active:
			pose_delta = 0.0
		character.held_items.advance_pose(pose_delta)
		character.held_items.apply_finger_pose()
	# World contacts only affect the legs. Swing feet keep their authored lift.
	if character.grounded and character.floor_ik_enabled:
		for side in ["R", "L"]:
			fit_foot(side)
	# Small, bounded satchel motion stays on its bone instead of moving the torso.
	var bag_index := index("satchel")
	if bag_index>=0:
		var bag_pose := skel.get_bone_pose_rotation(bag_index)
		skel.set_bone_pose_rotation(bag_index, bag_pose * Quaternion(Vector3.FORWARD, sin(character.motion_phase) * character.speed_ratio * 0.04))

func apply_hand_aim(delta: float, skel: Skeleton3D, camera: Camera3D, skeleton_from_world: Transform3D, camera_forward: Vector3) -> void:
	var arm_before: Dictionary = {}
	for name in ["upper_arm.R","forearm.R","forearm_twist.R","hand.R"]:
		if index(name)>=0:arm_before[index(name)]=skel.get_bone_pose_rotation(index(name))
	# Target the real wrist in body space, with a physical reach limit at the shoulder.
	var reach: float = 0.31 - character.wall_retraction * 0.32
	var drop: float = character.character_profile.get("hand_drop",0.24)
	var horizontal := 0.205
	if character.held_items != null:
		var offset: Vector3 = character.held_items.aim_hand_offset
		horizontal = offset.x
		drop = -offset.y
		reach = -offset.z-character.wall_retraction*0.32
	# Lower the wrist with a retracted item so the downward orientation is
	# supported by the forearm instead of folding sharply at the wrist.
	drop += character.wall_retraction*0.20
	if character.held_items != null:
		drop += character.held_items.lower_amount*0.30
	var hand_world: Vector3 = camera.global_position + camera.global_basis.x * horizontal - camera.global_basis.y * drop - camera.global_basis.z * reach
	# A diagonal reach query also catches corners beside the camera's center ray.
	if character.floor_ik_enabled:
		var reach_query := PhysicsRayQueryParameters3D.create(camera.global_position, hand_world-camera.global_basis.z*0.16)
		reach_query.exclude = [character.player.get_rid()]
		reach_query.collision_mask = character.player.collision_mask
		var reach_hit := skel.get_world_3d().direct_space_state.intersect_ray(reach_query)
		if not reach_hit.is_empty():
			var ray_direction := (hand_world-camera.global_position).normalized()
			hand_world = camera.global_position + ray_direction*maxf(0.06,camera.global_position.distance_to(reach_hit.position)-0.18)
	var wrist_target: Vector3 = skeleton_from_world * hand_world
	var pole := skeleton_from_world * (camera.global_position + character.global_basis.x * 0.46 - Vector3.UP * 0.34 + character.global_basis.z * 0.16)
	if character.held_items != null:
		var elbow: Vector3 = character.held_items.aim_elbow_offset
		pole = skeleton_from_world*(camera.global_position+character.global_basis*elbow)
	solve_limb("upper_arm.R", "forearm.R", "hand.R", wrist_target, pole)
	var hand_index := index("hand.R")
	var hand_pose := skel.get_bone_global_pose(hand_index)
	var rest_hand := skel.get_bone_global_rest(hand_index)
	var direction := camera_forward
	# Near a wall, rotate the light downward as well as retracting the arm.
	direction = direction.rotated(Vector3.RIGHT, -character.wall_retraction * 0.75)
	if character.held_items != null or character.character_profile.has("hand_forward"):
		var source_forward: Vector3 = character.held_items.aim_frame.x if character.held_items != null else character.profile_vector("hand_forward").normalized()
		var source_up: Vector3 = character.held_items.aim_frame.y if character.held_items != null else character.profile_vector("hand_up").normalized()
		var up := (skel.global_basis.inverse()*camera.global_basis.y).normalized()
		up = (up-direction*direction.dot(up)).normalized()
		var source_frame := Basis(source_forward,source_up,source_forward.cross(source_up))
		var target_frame := Basis(direction,up,direction.cross(up))
		hand_pose.basis = target_frame*source_frame.inverse()*rest_hand.basis
	else:
		hand_pose.basis = Basis(Quaternion(Vector3.FORWARD, direction)) * rest_hand.basis
	var twist_index := index("forearm_twist.R")
	if twist_index>=0:
		var forearm_index := index("forearm.R")
		var forearm := skel.get_bone_global_pose(forearm_index)
		var rest_forearm := skel.get_bone_global_rest(forearm_index)
		var aligned := hand_pose.basis*rest_hand.basis.inverse()*rest_forearm.basis
		aligned = Basis(Quaternion(aligned.y.normalized(),forearm.basis.y.normalized()))*aligned
		var twist := skel.get_bone_global_pose(twist_index)
		twist.basis = aligned*rest_forearm.basis.inverse()*skel.get_bone_global_rest(twist_index).basis
		skel.set_bone_global_pose(twist_index,twist)
		hand_pose.origin = skel.get_bone_global_pose(hand_index).origin
	skel.set_bone_global_pose(hand_index, hand_pose)
	if character.held_items != null:
		for bone_index in arm_before:
			var after := skel.get_bone_pose_rotation(bone_index)
			skel.set_bone_pose_rotation(bone_index,Quaternion(arm_before[bone_index]).slerp(after,character.held_items.arm_weight))
		return
	grip = move_toward(grip, 1, delta * 8)
	for finger in ["index", "middle", "ring", "pinky", "thumb"]:
		for joint in range(1, 4):
			var finger_name: String = finger + str(joint) + ".R"
			var finger_index := index(finger_name)
			if character.character_profile.has("grip_rotations"):
				var values: Array = character.character_profile.grip_rotations[finger_name]
				var fitted := Quaternion(values[0],values[1],values[2],values[3]).normalized()
				var local_rest := skel.get_bone_rest(finger_index).basis.get_rotation_quaternion()
				skel.set_bone_pose_rotation(finger_index,local_rest*Quaternion.IDENTITY.slerp(fitted,grip))
				continue
			var rest := skel.get_bone_global_rest(finger_index)
			var curl := (0.45 if finger == "thumb" else (0.65 if joint == 1 else 0.85)) * grip
			var axis := rest.basis.inverse() * Vector3.RIGHT
			skel.set_bone_pose_rotation(finger_index, skel.get_bone_rest(finger_index).basis.get_rotation_quaternion()*Quaternion(axis.normalized(), curl))

func solve_limb(upper_name: String, lower_name: String, end_name: String, target: Vector3, pole: Vector3) -> void:
	var skel := get_skeleton()
	var upper_index := index(upper_name)
	var lower_index := index(lower_name)
	var end_index := index(end_name)
	var upper := skel.get_bone_global_pose(upper_index)
	var lower := skel.get_bone_global_pose(lower_index)
	var end := skel.get_bone_global_pose(end_index)
	var a := upper.origin.distance_to(lower.origin)
	var b := lower.origin.distance_to(end.origin)
	var offset := target - upper.origin
	var distance := clampf(offset.length(), absf(a-b) + 0.002, a+b-0.002)
	var direction := offset.normalized()
	var bend := pole - upper.origin
	bend = (bend - direction * bend.dot(direction)).normalized()
	if bend.length_squared() < 0.1:
		bend = direction.cross(Vector3.RIGHT).normalized()
	var along := (a*a - b*b + distance*distance) / (2*distance)
	var elbow := upper.origin + direction*along + bend*sqrt(maxf(0, a*a-along*along))
	upper.basis = Basis(Quaternion((lower.origin-upper.origin).normalized(), (elbow-upper.origin).normalized())) * upper.basis
	skel.set_bone_global_pose(upper_index, upper)
	lower = skel.get_bone_global_pose(lower_index)
	end = skel.get_bone_global_pose(end_index)
	var end_target := upper.origin + direction*distance
	lower.basis = Basis(Quaternion((end.origin-lower.origin).normalized(), (end_target-lower.origin).normalized())) * lower.basis
	skel.set_bone_global_pose(lower_index, lower)

func fit_foot(side: String) -> void:
	var skel := get_skeleton()
	var foot_index := index("foot." + side)
	var foot := skel.get_bone_global_pose(foot_index)
	var foot_basis := foot.basis
	var world := skel.global_transform * foot.origin
	var ankle_height := skel.get_bone_global_rest(foot_index).origin.y
	var query := PhysicsRayQueryParameters3D.create(world + Vector3.UP*0.22, world - Vector3.UP*0.30)
	query.collision_mask = character.player.collision_mask
	query.exclude = [character.player.get_rid()]
	var hit := skel.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return
	var lift := maxf(0, world.y - character.player.global_position.y - ankle_height)
	var contact := 1.0 - clampf(lift / 0.16, 0, 1)
	var correction := clampf(hit.position.y + ankle_height - world.y, -0.12, 0.12) * contact
	var target := foot.origin + skel.global_basis.inverse() * Vector3.UP * correction
	var pole := foot.origin + Vector3.FORWARD * 0.4 + Vector3.UP * 0.1
	solve_limb("thigh." + side, "shin." + side, "foot." + side, target, pole)
	foot = skel.get_bone_global_pose(foot_index)
	var normal := (skel.global_basis.inverse() * Vector3(hit.normal)).normalized()
	foot.basis = Basis(Quaternion(Vector3.UP, normal).slerp(Quaternion.IDENTITY, 1-contact)) * foot_basis
	skel.set_bone_global_pose(foot_index, foot)
	# Modifier poses are restored outside Skeleton3D's modification signal. Cache
	# the solved contact here for diagnostics rather than reading a reverted pose.
	foot_contacts[side] = skel.global_transform * skel.get_bone_global_pose(foot_index).origin
