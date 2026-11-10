class_name HandGripProfile
extends Resource
## An authored grip for one item and one compatible humanoid hand rig.
## All item transforms and contact points are local, so aiming cannot detach it.
@export var item_id: StringName
@export var display_name := "Held item"
@export var compatible_rig: StringName = &"mannequin_humanoid_v1"
@export var model_scene: PackedScene
@export var attachment_bone: StringName = &"hand.R"
@export var attachment_transform := Transform3D.IDENTITY
@export var finger_rotations: Dictionary = {}
@export var pose_animation: StringName = &""
@export var contact_targets: Dictionary = {}
@export var hand_offset := Vector3(0.205,-0.18,-0.31)
@export var elbow_offset := Vector3(0.46,-0.34,0.16)
@export var aim_forward := Vector3.FORWARD
@export var aim_up := Vector3.UP
@export_range(0.1,30.0) var blend_speed := 9.0
@export_range(0.05,0.5) var lower_time := 0.16
@export_range(0.05,0.6) var raise_time := 0.24
@export var emits_light := false
@export var beam_transform := Transform3D.IDENTITY
@export var light_color := Color(0.91,0.92,0.78)
@export var light_energy := 3.5
@export var light_range := 24.0
@export var light_angle := 34.0

func validate_for(skeleton: Skeleton3D, rig_id: StringName) -> PackedStringArray:
	var errors := PackedStringArray()
	if compatible_rig != rig_id:
		errors.append("Grip is for a different hand rig")
	if model_scene == null:
		errors.append("Grip has no item scene")
	if skeleton.find_bone(attachment_bone)<0:
		errors.append("Grip attachment bone is missing")
	if attachment_bone != &"hand.R":
		errors.append("This controller currently fits right-hand profiles")
	for bone in finger_rotations:
		if skeleton.find_bone(bone)<0 or not finger_rotations[bone] is Quaternion:
			errors.append("Invalid finger pose: "+String(bone))
	return errors
