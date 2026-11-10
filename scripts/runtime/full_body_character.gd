extends Node3D
## One world-space body, one deform skeleton, and one hand-mounted item.
## The movement controller owns collision and camera; this node only presents it.

const PoseModifier = preload("res://scripts/runtime/scavenger_pose_modifier.gd")
const HeldItems = preload("res://scripts/runtime/held_item_controller.gd")
@export var default_held_item: HandGripProfile
var held_items: HeldItemController
@export var model_path: NodePath = ^"Scavenger"
@export_file("*.json") var character_profile_path := ""
@export var split_continuous_head := false
var character_profile: Dictionary = {}
var model: Node3D
var skeleton: Skeleton3D
var animator: AnimationPlayer
var animation_tree: AnimationTree
var pose_modifier: SkeletonModifier3D
var player: CharacterBody3D
var view_camera: Camera3D
var torch: SpotLight3D
var item_socket: BoneAttachment3D
var local_velocity := Vector3.ZERO
var speed_ratio := 0.0
var is_crouching := false
var grounded := true
var wall_retraction := 0.0
var wall_retraction_target := 0.0
var motion_phase := 0.0
var look_sway := Vector2.ZERO
var stance_blend := 0.0
var air_blend := 0.0
var first_person := true
var floor_ik_enabled := true
var shadows: Array[MeshInstance3D] = []
var lens_material: StandardMaterial3D
var hand_pose_node: AnimationNodeAnimation
var hand_pose_weight := 0.0
var hand_transition: AnimationNodeTransition
var hand_pose_states: Dictionary = {}
var hand_pose_nodes: Dictionary = {}
var requested_hand_clip: StringName = &""

func build(camera: Camera3D, controller: CharacterBody3D) -> SpotLight3D:
	player = controller
	view_camera = camera
	model = get_node(model_path)
	if not character_profile_path.is_empty():
		character_profile = JSON.parse_string(FileAccess.get_file_as_string(character_profile_path))
	skeleton = model.find_children("*", "Skeleton3D", true, false)[0]
	animator = model.find_children("*", "AnimationPlayer", true, false)[0]
	if ResourceLoader.exists("res://assets/characters/inventory_hands/hand_poses.res"):
		var library: AnimationLibrary=load("res://assets/characters/inventory_hands/hand_poses.res")
		animator.add_animation_library(&"Inventory",library.duplicate())
	if split_continuous_head:
		split_head_for_first_person()
	configure_visibility()
	configure_animation_tree()
	pose_modifier = SkeletonModifier3D.new()
	pose_modifier.name = "GroundAndAim"
	pose_modifier.set_script(PoseModifier)
	pose_modifier.character = self
	skeleton.add_child(pose_modifier)
	if default_held_item:
		held_items = HeldItems.new()
		held_items.name = "RightHandItems"
		add_child(held_items)
		held_items.setup(skeleton,character_profile.get("rig_id",&"mannequin_humanoid_v1"),character_profile.get("fingertip_lengths",{}))
		held_items.item_changed.connect(_on_held_item_changed)
		held_items.equip(default_held_item,true)
		torch = held_items.light
		item_socket = held_items.socket
		configure_hand_pose_layer()
		set_first_person(true)
		return torch
	item_socket = BoneAttachment3D.new()
	item_socket.name = "RightHandItemSocket"
	item_socket.bone_name = "item.R"
	skeleton.add_child(item_socket)
	torch = SpotLight3D.new()
	torch.name = "FlashlightBeam"
	torch.light_color = Color(0.91, 0.92, 0.78)
	torch.light_energy = 3.5
	torch.spot_range = 24
	torch.spot_angle = 34
	torch.spot_attenuation = 0.75
	torch.shadow_enabled = true
	item_socket.add_child(torch)
	# Bone-local +Y runs along its shaft; glTF's bone basis is retained.
	# Construct the beam transform from the rest socket instead of guessing axes.
	var item_rest := skeleton.get_bone_global_rest(skeleton.find_bone("item.R"))
	var beam_rest := Transform3D(Basis.IDENTITY, Vector3(0.42544156, 0.92367536, -0.23081386))
	if character_profile.has("beam_position"):
		var forward := profile_vector("beam_forward").normalized()
		var up := profile_vector("beam_up").normalized()
		beam_rest = Transform3D(Basis(forward.cross(up),up,-forward),profile_vector("beam_position"))
	torch.transform = item_rest.affine_inverse() * beam_rest
	set_first_person(true)
	return torch

func equip_item(profile: HandGripProfile) -> bool:
	if held_items == null:
		return false
	var success := held_items.equip(profile)
	if success and player.get_script()!=null and player.battery_charge<=0:
		torch.visible = false
	return success

func can_use_flashlight() -> bool:
	return held_items == null or held_items.can_emit_light()

func _on_held_item_changed(_item_id: StringName) -> void:
	if player.get_script()!=null and player.battery_charge<=0:
		held_items.light.visible=false

func profile_vector(key: String) -> Vector3:
	var value: Array = character_profile[key]
	return Vector3(value[0],value[1],value[2])

func find_clip(short_name: StringName) -> StringName:
	for name in animator.get_animation_list():
		if String(name).get_slice("/",String(name).get_slice_count("/")-1)==short_name:
			return name
	return &""

func configure_hand_pose_layer() -> void:
	var open_clip := find_clip(&"Hand_open")
	if open_clip.is_empty():return
	var tree: AnimationNodeBlendTree=animation_tree.tree_root
	hand_transition=AnimationNodeTransition.new()
	hand_transition.xfade_time=0.16
	var curve := Curve.new()
	curve.add_point(Vector2.ZERO)
	curve.add_point(Vector2.ONE)
	hand_transition.xfade_curve=curve
	var clips: Array[StringName] = []
	for clip in animator.get_animation_list():
		if String(clip).get_slice("/",String(clip).get_slice_count("/")-1).begins_with("Hand_"):
			clips.append(clip)
	hand_transition.input_count=clips.size()
	tree.add_node("HandTransition",hand_transition)
	for i in range(clips.size()):
		var node := AnimationNodeAnimation.new()
		node.animation=clips[i]
		var state := "pose_"+str(i)
		hand_transition.set_input_name(i,state)
		hand_transition.set_input_reset(i,true)
		tree.add_node(state,node)
		tree.connect_node("HandTransition",i,state)
		hand_pose_states[clips[i]]=state
		hand_pose_nodes[clips[i]]=node
	hand_pose_node=hand_pose_nodes[open_clip]
	var blend := AnimationNodeBlend2.new()
	blend.filter_enabled=true
	var pose: Animation=animator.get_animation(open_clip)
	for track in range(pose.get_track_count()):
		var path := pose.track_get_path(track)
		var bone := String(path).get_slice(":",1)
		if bone.ends_with(".R") and (bone.begins_with("thumb") or bone.begins_with("index") or bone.begins_with("middle") or bone.begins_with("ring") or bone.begins_with("pinky")):
			blend.set_filter_path(path,true)
	tree.add_node("HandLayer",blend)
	tree.disconnect_node("output",0)
	tree.connect_node("HandLayer",0,"Cadence")
	tree.connect_node("HandLayer",1,"HandTransition")
	tree.connect_node("output",0,"HandLayer")

func update_hand_pose_layer(delta: float) -> void:
	if held_items==null:return
	held_items.advance_transition(delta)
	if hand_pose_node==null:return
	var clip := &""
	if held_items.active_grip and not held_items.active_grip.pose_animation.is_empty():
		clip=find_clip(held_items.active_grip.pose_animation)
	held_items.animated_fingers=not clip.is_empty() or held_items.active_grip==null
	var goal := 0.0
	if not clip.is_empty():
		goal=held_items.grip_strength*held_items.pose_closure
	else:
		clip=find_clip(&"Hand_open")
	if clip!=requested_hand_clip:
		animation_tree.set("parameters/HandTransition/transition_request",hand_pose_states[clip])
		requested_hand_clip=clip
		hand_pose_node=hand_pose_nodes[clip]
	var speed := held_items.active_grip.blend_speed if held_items.active_grip else 9.0
	hand_pose_weight=lerpf(hand_pose_weight,goal,1.0-exp(-delta*speed))
	animation_tree.set("parameters/HandLayer/blend_amount",hand_pose_weight)

func split_head_for_first_person() -> void:
	# Share the original skinned vertex data and normals; only partition indices.
	# The anatomical source stays continuous, with no visible neck seam in review.
	var body: MeshInstance3D = model.find_child(character_profile.get("body_mesh","MaleMannequinBody"),true,false)
	var body_mesh := ArrayMesh.new()
	var head_mesh := ArrayMesh.new()
	for surface in range(body.mesh.get_surface_count()):
		var arrays := body.mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var body_indices := PackedInt32Array()
		var head_indices := PackedInt32Array()
		for triangle in range(0,indices.size(),3):
			var center := (vertices[indices[triangle]]+vertices[indices[triangle+1]]+vertices[indices[triangle+2]])/3.0
			if center.y>1.54 and absf(center.x)<0.14:
				head_indices.append(indices[triangle])
				head_indices.append(indices[triangle+1])
				head_indices.append(indices[triangle+2])
			else:
				body_indices.append(indices[triangle])
				body_indices.append(indices[triangle+1])
				body_indices.append(indices[triangle+2])
		if not body_indices.is_empty():
			arrays[Mesh.ARRAY_INDEX] = body_indices
			body_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
			body_mesh.surface_set_material(body_mesh.get_surface_count()-1,body.get_active_material(surface))
		if not head_indices.is_empty():
			arrays[Mesh.ARRAY_INDEX] = head_indices
			head_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
			head_mesh.surface_set_material(head_mesh.get_surface_count()-1,body.get_active_material(surface))
	body.mesh = body_mesh
	var head := MeshInstance3D.new()
	head.name = "Head"
	head.mesh = head_mesh
	head.skin = body.skin
	head.skeleton = body.skeleton
	head.transform = body.transform
	body.get_parent().add_child(head)

func configure_visibility() -> void:
	for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		if String(mesh.name) == "Hair":
			for surface in range(mesh.mesh.get_surface_count()):
				var material: BaseMaterial3D = mesh.get_active_material(surface)
				material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
				material.alpha_scissor_threshold = 0.45
				material.cull_mode = BaseMaterial3D.CULL_DISABLED
		if String(mesh.name) in ["Head", "Hair", "Eyes", "Neckwear"] or String(mesh.name).begins_with("MannequinEye"):
			mesh.layers = 2
			# A shadow-only skin preserves the complete silhouette in first person.
			var shadow := MeshInstance3D.new()
			shadow.name = String(mesh.name) + "Shadow"
			shadow.mesh = mesh.mesh
			shadow.skin = mesh.skin
			shadow.skeleton = mesh.skeleton
			shadow.transform = mesh.transform
			shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
			shadow.layers = 1
			mesh.get_parent().add_child(shadow)
			shadows.append(shadow)
			mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		elif String(mesh.name) == "Flashlight":
			# Do not have the emitter shadow itself; the held prop still receives light.
			mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			for surface in range(mesh.mesh.get_surface_count()):
				var material: StandardMaterial3D = mesh.get_active_material(surface)
				if material.resource_name == "Torch_glass":
					lens_material = material.duplicate()
					lens_material.emission_enabled = true
					lens_material.emission = Color("bac5a6")
					mesh.set_surface_override_material(surface, lens_material)
		# Allow animated extremities to leave the exported rest AABB without culling.
		mesh.extra_cull_margin = 0.6

func set_first_person(enabled: bool) -> void:
	first_person = enabled
	if is_instance_valid(view_camera):
		view_camera.set_cull_mask_value(2, not enabled)

func clip_name(short_name: String) -> StringName:
	for name in animator.get_animation_list():
		if String(name).get_slice("/", String(name).get_slice_count("/") - 1) == short_name:
			return name
	push_error("Character animation is missing: " + short_name)
	return &"RESET"

func animation_node(name: String) -> AnimationNodeAnimation:
	var node := AnimationNodeAnimation.new()
	node.animation = clip_name(name)
	animator.get_animation(node.animation).loop_mode = Animation.LOOP_LINEAR
	return node

func configure_animation_tree() -> void:
	animation_tree = AnimationTree.new()
	animation_tree.name = "LocomotionTree"
	add_child(animation_tree)
	animation_tree.anim_player = animation_tree.get_path_to(animator)
	var tree := AnimationNodeBlendTree.new()
	var space := AnimationNodeBlendSpace2D.new()
	space.sync_mode = AnimationNodeBlendSpace2D.SYNC_MODE_CYCLIC_MUTABLE
	space.add_blend_point(animation_node("Idle"), Vector2.ZERO, -1, &"idle")
	space.add_blend_point(animation_node("Walk"), Vector2(0, -1), -1, &"forward")
	space.add_blend_point(animation_node("WalkBack"), Vector2(0, 1), -1, &"back")
	space.add_blend_point(animation_node("StrafeLeft"), Vector2(-1, 0), -1, &"left")
	space.add_blend_point(animation_node("StrafeRight"), Vector2(1, 0), -1, &"right")
	tree.add_node("Move", space)
	tree.add_node("Run", animation_node("Run"))
	tree.add_node("RunBlend", AnimationNodeBlend2.new())
	tree.connect_node("RunBlend", 0, "Move")
	tree.connect_node("RunBlend", 1, "Run")
	tree.add_node("CrouchIdle", animation_node("CrouchIdle"))
	tree.add_node("CrouchWalk", animation_node("CrouchWalk"))
	tree.add_node("CrouchMove", AnimationNodeBlend2.new())
	tree.connect_node("CrouchMove", 0, "CrouchIdle")
	tree.connect_node("CrouchMove", 1, "CrouchWalk")
	tree.add_node("Stance", AnimationNodeBlend2.new())
	tree.connect_node("Stance", 0, "RunBlend")
	tree.connect_node("Stance", 1, "CrouchMove")
	tree.add_node("Airborne", animation_node("Airborne"))
	tree.add_node("AirBlend", AnimationNodeBlend2.new())
	tree.connect_node("AirBlend", 0, "Stance")
	tree.connect_node("AirBlend", 1, "Airborne")
	tree.add_node("Cadence", AnimationNodeTimeScale.new())
	tree.connect_node("Cadence", 0, "AirBlend")
	tree.connect_node("output", 0, "Cadence")
	animation_tree.tree_root = tree
	animation_tree.active = true

func _process(delta: float) -> void:
	var playing := true
	if is_instance_valid(player) and player.get_script() != null:
		playing = player.active
		animation_tree.active = playing
		# Keep the held pose on the frozen animation while menus are open. Disabling
		# the modifier would restore the un-aimed arm and make the light jump.
	if playing:
		wall_retraction=lerpf(wall_retraction,wall_retraction_target,1.0-exp(-delta*16))
		update_hand_pose_layer(delta)

func animate_motion(delta: float, speed: float, phase: float, crouch: bool, on_ground: bool, sway: Vector2, light_on: bool, retraction: float = 0.0) -> void:
	local_velocity = player.global_basis.inverse() * player.velocity
	speed_ratio = speed
	motion_phase = phase
	is_crouching = crouch
	grounded = on_ground
	look_sway = sway
	wall_retraction_target = retraction
	if lens_material:
		lens_material.emission_energy_multiplier = 0.4 if light_on else 0.0
	stance_blend = move_toward(stance_blend, 1.0 if crouch else 0.0, delta * 7.0)
	air_blend = move_toward(air_blend, 0.0 if on_ground else 1.0, delta * 9.0)
	var horizontal := Vector2(local_velocity.x, local_velocity.z)
	animation_tree.set("parameters/Move/blend_position", (horizontal / 3.5).limit_length(1.0))
	animation_tree.set("parameters/RunBlend/blend_amount", clampf((horizontal.length() - 3.5) / 2.9, 0, 1))
	animation_tree.set("parameters/CrouchMove/blend_amount", clampf(horizontal.length() / 2.0, 0, 1))
	animation_tree.set("parameters/Stance/blend_amount", stance_blend)
	animation_tree.set("parameters/AirBlend/blend_amount", air_blend)
	animation_tree.set("parameters/Cadence/scale", clampf(horizontal.length() / (2.0 if crouch else 3.5), 0.7, 1.2) if horizontal.length() > 0.1 else 1.0)
