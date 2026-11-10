extends SceneTree
## Exercise actual item swaps, imported finger contacts, pose isolation and light use.
const FLASHLIGHT = preload("res://assets/grips/flashlight.tres")
const TIN = preload("res://assets/grips/food_tin.tres")
var failures := 0

func _initialize() -> void:call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("HELD_ITEM_FAIL: "+message)

func frames(count: int) -> void:
	for i in range(count):
		await physics_frame
		await process_frame

func make_player(at: Vector3) -> CharacterBody3D:
	var player := CharacterBody3D.new()
	player.set_script(load("res://scripts/runtime/player.gd"))
	player.position = at
	root.add_child(player)
	player.set_physics_process(false)
	player.active = true
	return player

func check_contacts(visual: Node3D) -> void:
	var held: HeldItemController = visual.held_items
	for finger in ["thumb","index","middle","ring","pinky"]:
		check(held.contact_positions.has(finger),"Missing imported fingertip contact: "+finger)
		if not held.contact_positions.has(finger):continue
		var actual: Vector3 = held.contact_positions[finger]
		var goal := held.item.to_global(held.active_grip.contact_targets[finger])
		check(goal.distance_to(actual)<0.005,"Imported fingertip missed its authored item contact by over 5 mm: "+finger)
	if held.active_grip.item_id==&"flashlight":
		var switch: Marker3D=held.item.get_node("ThumbSwitch")
		check(switch.global_position.distance_to(held.contact_positions.thumb)<0.006,"Thumb no longer reaches the physical side switch")

func run() -> void:
	var inputs: Node3D = load("res://scripts/runtime/game.gd").new()
	inputs.setup_input()
	inputs.free()
	var ground := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(12,0.2,12)
	collision.shape = box
	ground.position.y = -0.1
	ground.add_child(collision)
	root.add_child(ground)
	var player := make_player(Vector3.ZERO)
	var visual: Node3D = player.body_model
	var held: HeldItemController = visual.held_items
	check(held != null,"Permanent hand item controller is missing")
	if held == null:quit(1);return
	await frames(48)
	check(held.active_grip==FLASHLIGHT,"Default flashlight profile did not equip")
	check(held.socket.bone_name=="hand.R","Items must attach to the anatomical hand")
	check(held.item.find_children("*","Skeleton3D",true,false).is_empty(),"Item model still contains a character rig")
	for mesh: MeshInstance3D in held.item.find_children("*","MeshInstance3D",true,false):
		check(mesh.skin==null,"Held prop is still baked into the deform skin")
	check_contacts(visual)
	var persistent_light := held.light.get_instance_id()
	var original_pose := var_to_str(FLASHLIGHT.finger_rotations)
	for pitch in [-1.1,0.0,0.9]:
		player.camera.rotation.x=pitch
		await frames(12)
		check((-held.light.global_basis.z).dot(-player.camera.global_basis.z)>0.98,"Beam lost alignment while aiming")
		check_contacts(visual)
	player.camera.rotation.x=0
	check(visual.equip_item(TIN),"Food tin cannot use the shared hand socket")
	await frames(48)
	check(held.active_grip==TIN and not visual.can_use_flashlight(),"Food tin retained flashlight behavior")
	check(held.light.get_instance_id()==persistent_light,"Item swap invalidated the player's light reference")
	check(not held.light.visible,"Non-light item turned on the flashlight")
	check_contacts(visual)
	var f := InputEventKey.new()
	f.pressed=true
	f.physical_keycode=KEY_F
	player._unhandled_input(f)
	check(not held.light.visible,"F enabled the light while holding the tin")
	player.battery_charge=50
	player.set_physics_process(true)
	await frames(12)
	player.set_physics_process(false)
	check(is_equal_approx(player.battery_charge,50),"Non-light item drained flashlight batteries")
	var invalid: HandGripProfile=FLASHLIGHT.duplicate()
	invalid.compatible_rig=&"different_skeleton"
	var item_id := held.item.get_instance_id()
	check(not held.equip(invalid),"Incompatible rig profile was accepted")
	check(held.item.get_instance_id()==item_id and held.active_grip==TIN,"Rejected grip destroyed the current item")
	for i in range(8):
		check(visual.equip_item(FLASHLIGHT if i%2 else TIN),"Repeated equip failed")
	await frames(48)
	check(held.socket.get_child_count()==2,"Item swaps left duplicate held models behind")
	check(visual.equip_item(FLASHLIGHT),"Cannot restore the flashlight")
	await frames(40)
	var other := make_player(Vector3(3,0,0))
	await frames(40)
	held.grip_strength=0
	await frames(48)
	check(Quaternion(held.finger_pose["index2.R"]).angle_to(Quaternion.IDENTITY)<0.02,"Grip cannot open its fingers")
	check(Quaternion(other.body_model.held_items.finger_pose["index2.R"]).angle_to(Quaternion.IDENTITY)>0.2,"Opening one character changed another's grip")
	check(var_to_str(FLASHLIGHT.finger_rotations)==original_pose,"Runtime blending mutated the shared grip resource")
	held.grip_strength=1
	await frames(40)
	check_contacts(visual)
	check(visual.equip_item(null),"Empty-hand transition failed")
	await frames(40)
	check(held.item==null and held.socket.get_child_count()==1 and not held.light.visible,"Unequip left an orphan prop or active light")
	check(Quaternion(held.finger_pose["thumb2.R"]).angle_to(Quaternion.IDENTITY)<0.02,"Unequip did not release the thumb")
	player.queue_free();other.queue_free();ground.queue_free()
	await process_frame
	print("HELD_ITEMS_CHECK: failures=",failures)
	quit(1 if failures else 0)
