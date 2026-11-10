extends SceneTree
const FLASHLIGHT=preload("res://assets/grips/flashlight.tres")
const TIN=preload("res://assets/grips/food_tin.tres")
var failures := 0
var player: CharacterBody3D
var visual: Node3D
var held: HeldItemController
var previous_hand := Transform3D.IDENTITY
var previous_fingers: Dictionary = {}
var max_hand_step := 0.0
var max_wrist_angle := 0.0
var max_finger_angle := 0.0
var monitoring := false
var stage := "initial"
func _initialize() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
	if not ok:
		failures+=1
		push_error(message)
func frames(count: int) -> void:
	for i in range(count):
		await physics_frame
		await process_frame
		if monitoring:
			var hand_step := previous_hand.origin.distance_to(held.hand_world_transform.origin)
			if hand_step>max_hand_step and hand_step>0.06:
				print("TRANSITION_STEP ",stage," phase=",held.equip_phase," lower=",held.lower_amount," arm=",held.arm_weight," meters=",hand_step)
			max_hand_step=maxf(max_hand_step,hand_step)
			max_wrist_angle=maxf(max_wrist_angle,previous_hand.basis.get_rotation_quaternion().angle_to(held.hand_world_transform.basis.get_rotation_quaternion()))
			for bone in previous_fingers:
				max_finger_angle=maxf(max_finger_angle,Quaternion(previous_fingers[bone]).angle_to(held.applied_rotations[bone]))
		previous_hand=held.hand_world_transform
		previous_fingers=held.applied_rotations.duplicate()
func check_contacts() -> void:
	for finger in ["thumb","index","middle","ring","pinky"]:
		var tip: Vector3=held.contact_positions[finger]
		var goal: Vector3=held.item.to_global(held.active_grip.contact_targets[finger])
		check(tip.distance_to(goal)<0.005,"Transition failed to settle onto its contact: "+finger)
func run() -> void:
	var inputs: Node3D=load("res://scripts/runtime/game.gd").new()
	inputs.setup_input();inputs.free()
	player=CharacterBody3D.new()
	player.set_script(load("res://scripts/runtime/player.gd"))
	root.add_child(player)
	player.set_physics_process(false)
	player.active=true
	visual=player.body_model
	visual.floor_ik_enabled=false
	held=visual.held_items
	await frames(65)
	monitoring=true
	var old_item := held.item.get_instance_id()
	stage="tin swap"
	check(visual.equip_item(TIN),"Cannot request tin")
	await frames(4)
	check(held.item.get_instance_id()==old_item,"Item was exchanged before the hand lowered")
	var invalid: HandGripProfile=FLASHLIGHT.duplicate()
	invalid.compatible_rig=&"invalid_during_exchange"
	check(not visual.equip_item(invalid) and held.pending_profile==TIN,"Invalid request replaced a valid pending exchange")
	var frozen_amount := held.lower_amount
	var frozen_hand := held.hand_world_transform
	player.active=false
	await frames(12)
	check(is_equal_approx(held.lower_amount,frozen_amount),"Equip motion continued while paused")
	check(held.hand_world_transform.is_equal_approx(frozen_hand),"Paused equip moved the hand")
	player.active=true
	await frames(65)
	check(held.active_grip==TIN and held.equip_phase==HeldItemController.EquipPhase.READY,"Tin exchange did not finish")
	check_contacts()
	visual.equip_item(FLASHLIGHT)
	stage="flashlight swap"
	await frames(65)
	check_contacts()
	# Reverse opening halfway through, instead of resetting the finger pose.
	held.grip_strength=0
	stage="open reverse"
	await frames(6)
	held.grip_strength=1
	await frames(50)
	check_contacts()
	# Replace a pending request and interrupt a raising motion repeatedly.
	for i in range(10):
		stage="interrupt "+str(i)
		visual.equip_item(TIN if i%2==0 else FLASHLIGHT)
		await frames(4 if i<6 else 14)
	await frames(65)
	check(held.active_grip==FLASHLIGHT,"Latest item request did not win")
	check(held.socket.get_child_count()==2 and held.pending_item==null,"Interrupted swaps leaked prop nodes")
	check_contacts()
	visual.equip_item(null)
	stage="unequip"
	await frames(65)
	check(held.item==null and held.arm_weight<0.001 and not held.light.visible,"Empty hand failed to relax")
	player.battery_charge=0
	visual.equip_item(FLASHLIGHT)
	stage="draw from empty"
	await frames(65)
	check(not held.light.visible,"Deferred equip bypassed an empty battery")
	check_contacts()
	check(max_hand_step<0.07,"Wrist position popped during an item transition: "+str(max_hand_step))
	check(max_wrist_angle<0.4,"Wrist orientation snapped during an item transition: "+str(max_wrist_angle))
	check(max_finger_angle<0.4,"Finger pose snapped during an item transition: "+str(max_finger_angle))
	print("GRIP_TRANSITION_METRICS: max_wrist_m=",max_hand_step," wrist_rad=",max_wrist_angle," finger_rad=",max_finger_angle)
	player.queue_free()
	await process_frame
	print("GRIP_TRANSITIONS_CHECK: failures=",failures)
	quit(1 if failures else 0)
