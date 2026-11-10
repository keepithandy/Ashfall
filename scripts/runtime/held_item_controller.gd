class_name HeldItemController
extends Node3D
## Owns a single item on the real hand. Profiles are shared immutable data;
## current pose and blend state belong to each character instance.
signal item_changed(item_id: StringName)
var skeleton: Skeleton3D
var rig_id: StringName = &"mannequin_humanoid_v1"
var socket: BoneAttachment3D
var item: Node3D
var active_grip: HandGripProfile
var light: SpotLight3D
var finger_pose: Dictionary = {}
var grip_strength := 1.0
var contact_positions: Dictionary = {}
var fingertip_lengths: Dictionary = {}
var animated_fingers := false
var applied_rotations: Dictionary = {}
var hand_world_transform := Transform3D.IDENTITY
enum EquipPhase { READY, LOWERING, RAISING }
var equip_phase := EquipPhase.READY
var lower_amount := 0.0
var pose_closure := 1.0
var arm_weight := 1.0
var aim_profile: HandGripProfile
var aim_hand_offset := Vector3.ZERO
var aim_elbow_offset := Vector3.ZERO
var aim_frame := Basis.IDENTITY
var pending_profile: HandGripProfile
var pending_item: Node3D
var phase_time := 0.0
var phase_start := 0.0
var phase_duration := 0.16
var raise_arm_start := 1.0

func setup(target: Skeleton3D, new_rig_id: StringName, lengths: Dictionary = {}) -> void:
	skeleton = target
	rig_id = new_rig_id
	fingertip_lengths = lengths
	socket = BoneAttachment3D.new()
	socket.name = "HeldItemSocket"
	socket.bone_name = "hand.R"
	skeleton.add_child(socket)
	light = SpotLight3D.new()
	light.name = "HeldItemLight"
	light.visible = false
	light.shadow_enabled = true
	light.spot_attenuation = 0.75
	socket.add_child(light)
	for finger in ["thumb","index","middle","ring","pinky"]:
		for joint in range(1,4):
			finger_pose[finger+str(joint)+".R"] = Quaternion.IDENTITY

func equip(profile: HandGripProfile, immediate: bool=false) -> bool:
	# Instantiate and validate before releasing the previous item.
	var instance: Node3D
	if profile:
		var errors := profile.validate_for(skeleton,rig_id)
		if not errors.is_empty():
			push_warning("Cannot equip "+profile.display_name+": "+"; ".join(errors))
			return false
		var candidate := profile.model_scene.instantiate()
		if not candidate is Node3D:
			candidate.free()
			return false
		instance=candidate
	if is_instance_valid(pending_item):pending_item.free()
	pending_profile=profile
	pending_item=instance
	if immediate:
		commit_item()
		equip_phase=EquipPhase.READY
		lower_amount=0
		pose_closure=1
		arm_weight=1 if profile else 0
		if profile:reset_aim(profile)
	else:
		# Keep an in-progress lowering motion; repeated requests replace only
		# the pending prop. A request during raising lowers from its current pose.
		if equip_phase!=EquipPhase.LOWERING:
			phase_start=lower_amount
			phase_time=0
			phase_duration=active_grip.lower_time if active_grip else 0.16
			equip_phase=EquipPhase.LOWERING
	return true

func reset_aim(profile: HandGripProfile) -> void:
	aim_profile=profile
	aim_hand_offset=profile.hand_offset
	aim_elbow_offset=profile.elbow_offset
	aim_frame=Basis(profile.aim_forward.normalized(),profile.aim_up.normalized(),profile.aim_forward.cross(profile.aim_up).normalized()).orthonormalized()

func commit_item() -> void:
	clear_item()
	active_grip = pending_profile
	var profile := active_grip
	if profile==null:
		item_changed.emit(&"")
		return
	if aim_profile==null:reset_aim(profile)
	aim_profile=profile
	socket.bone_name = profile.attachment_bone
	item = pending_item
	pending_item=null
	pending_profile=null
	item.name = "Held_"+String(profile.item_id)
	socket.add_child(item)
	item.transform = profile.attachment_transform
	light.transform = profile.attachment_transform*profile.beam_transform
	light.light_color = profile.light_color
	light.light_energy = profile.light_energy
	light.spot_range = profile.light_range
	light.spot_angle = profile.light_angle
	light.visible = profile.emits_light
	for mesh: MeshInstance3D in item.find_children("*","MeshInstance3D",true,false):
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	item_changed.emit(profile.item_id)

func clear_item() -> void:
	if is_instance_valid(item):
		item.visible = false
		socket.remove_child(item)
		item.queue_free()
	item = null
	active_grip = null
	contact_positions.clear()
	light.visible = false

func unequip() -> void:
	equip(null)

func advance_transition(delta: float) -> void:
	if delta<=0:return
	if equip_phase!=EquipPhase.READY:
		phase_time+=delta
		var progress := clampf(phase_time/phase_duration,0,1)
		var eased := progress*progress*(3-2*progress)
		if equip_phase==EquipPhase.LOWERING:
			lower_amount=lerpf(phase_start,1.0,eased)
			pose_closure=1-lower_amount
			if progress>=1:
				raise_arm_start=arm_weight
				commit_item()
				phase_time=0
				phase_duration=active_grip.raise_time if active_grip else 0.24
				# Reaching from the relaxed arm covers much more distance than a
				# held-item swap. Give that reach (and release) its own slower ease.
				if active_grip==null or raise_arm_start<0.01:
					phase_duration=maxf(phase_duration,0.40)
				equip_phase=EquipPhase.RAISING
		else:
			lower_amount=1-eased
			pose_closure=eased
			arm_weight=lerpf(raise_arm_start,1.0 if active_grip else 0.0,eased)
			if progress>=1:
				equip_phase=EquipPhase.READY
				if active_grip==null:aim_profile=null
	if aim_profile:
		var weight := 1-exp(-delta*10)
		aim_hand_offset=aim_hand_offset.lerp(aim_profile.hand_offset,weight)
		aim_elbow_offset=aim_elbow_offset.lerp(aim_profile.elbow_offset,weight)
		var frame := Basis(aim_profile.aim_forward.normalized(),aim_profile.aim_up.normalized(),aim_profile.aim_forward.cross(aim_profile.aim_up).normalized()).orthonormalized()
		aim_frame=aim_frame.slerp(frame,weight).orthonormalized()

func advance_pose(delta: float) -> void:
	var speed := active_grip.blend_speed if active_grip else 9.0
	var weight := 1.0-exp(-delta*speed)
	for bone in finger_pose:
		var desired := Quaternion.IDENTITY
		if active_grip:
			desired = Quaternion.IDENTITY.slerp(active_grip.finger_rotations.get(bone,Quaternion.IDENTITY),grip_strength*pose_closure)
		finger_pose[bone] = Quaternion(finger_pose[bone]).slerp(desired,weight).normalized()

func apply_finger_pose() -> void:
	for bone in finger_pose:
		var bone_index := skeleton.find_bone(bone)
		# Godot expects the complete local pose, not a delta from the rest.
		# Grip files store Blender-style offsets so they remain editable/reusable.
		var rest_rotation := skeleton.get_bone_rest(bone_index).basis.get_rotation_quaternion()
		if not animated_fingers:
			skeleton.set_bone_pose_rotation(bone_index,(rest_rotation*Quaternion(finger_pose[bone])).normalized())
		applied_rotations[bone]=skeleton.get_bone_pose_rotation(bone_index)
	hand_world_transform=skeleton.global_transform*skeleton.get_bone_global_pose(skeleton.find_bone("hand.R"))
	contact_positions.clear()
	for finger in ["thumb","index","middle","ring","pinky"]:
		var last := skeleton.find_bone(finger+"3.R")
		var length: float = fingertip_lengths.get(finger,0.018)
		var tip := skeleton.get_bone_global_pose(last)*Vector3(0,length,0)
		contact_positions[finger] = skeleton.global_transform*tip

func can_emit_light() -> bool:
	return active_grip != null and active_grip.emits_light

func _exit_tree() -> void:
	if is_instance_valid(pending_item):pending_item.free()
