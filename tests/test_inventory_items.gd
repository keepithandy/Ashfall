extends SceneTree
## Real pack UI, imported Blender poses, gameplay swaps, consumption and modal input.
const Items=preload("res://scripts/runtime/item_catalog.gd")
var failures := 0
var game: Node3D
var pack: Control
func _initialize() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
	if not ok:
		failures+=1
		push_error("INVENTORY_FAIL: "+message)
func frames(count: int) -> void:
	for i in range(count):
		await physics_frame
		await process_frame
func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode=code;event.pressed=true
	game._input(event)
func contacts(avatar: Node3D,id: String) -> void:
	var held: HeldItemController=avatar.held_items
	check(held.active_grip!=null and String(held.active_grip.item_id)==id,"Wrong held model: "+id)
	check(held.animated_fingers,"Blender pose layer unavailable: "+id)
	for finger in ["thumb","index","middle","ring","pinky"]:
		var actual: Vector3=held.contact_positions[finger]
		var target: Vector3=held.item.to_global(held.active_grip.contact_targets[finger])
		check(target.distance_to(actual)<.005,"Imported contact >5mm: "+id+" "+finger+" "+str(target.distance_to(actual)))
		if finger=="thumb":continue
		var sk: Skeleton3D=avatar.skeleton
		var wrist := sk.get_bone_global_rest(sk.find_bone("hand.R"))
		var tip := sk.get_bone_global_rest(sk.find_bone(finger+"3.R"))*Vector3(0,held.fingertip_lengths[finger],0)
		var normal: Vector3=(wrist.basis.inverse()*avatar.profile_vector("anatomical_palm_normal")).normalized()
		check((held.socket.to_local(actual)-wrist.affine_inverse()*tip).dot(normal)>.01,"Backward finger curl: "+id+" "+finger)
func run() -> void:
	game=load("res://scenes/legacy/main.tscn").instantiate()
	game.smoke_test=true
	root.add_child(game)
	game.resume_game()
	game.player.position=Vector3(-70,.1,45)
	game.player.velocity=Vector3.ZERO
	pack=game.hud.inventory_screen
	check(not pack.visible,"Pack should start closed")
	check(pack.item_buttons.size()==8,"Pack is missing item slots")
	check(pack.find_children("*","SubViewport",true,false).is_empty(),"Inventory should not render a 3D inspection preview")
	check(pack.find_child("Slots",true,false).get_child_count()==27,"Inventory grid should have 27 slots")
	check(game.open_inventory() and not game.player.active and pack.visible,"Pack did not pause player")
	await frames(3)
	var frozen: Vector3=game.player.position
	Input.action_press("move_forward")
	await frames(8)
	Input.action_release("move_forward")
	check(frozen.distance_to(game.player.position)<.001,"Player moved while pack was open")
	pack.select_item("bandage")
	check(pack.selected_id=="bandage" and pack.count_labels.bandage.text=="2","Slot selection or quantity incorrect")
	game.player.health=60
	pack.use_button.pressed.emit()
	check(game.player.health==95 and game.inventory.bandage==1 and pack.count_labels.bandage.text=="1","Using a slot did not update health and quantity")
	game.inventory.bandage=0;pack.refresh()
	check(pack.item_buttons.bandage.disabled and pack.item_buttons.bandage.icon==null and pack.count_labels.bandage.text.is_empty(),"Empty stack still displayed an item")
	game.inventory.bandage=2;pack.refresh()
	check(not pack.item_buttons.bandage.disabled and pack.item_buttons.bandage.icon!=null,"Replenished stack did not return to its slot")
	# The authoring diagnostic remains separately testable, outside the pack UI.
	var diagnostic_viewport:=SubViewport.new()
	diagnostic_viewport.own_world_3d=true
	diagnostic_viewport.size=Vector2i(320,180)
	root.add_child(diagnostic_viewport)
	var diagnostic=load("res://scripts/review/inventory_preview.gd").new()
	diagnostic_viewport.add_child(diagnostic)
	await frames(3)
	for id in Items.ORDER:
		var profile: HandGripProfile=Items.grip(id)
		check(game.inventory.get(id,0)>0,"Test loadout missing: "+id)
		check(profile.validate_for(game.player.body_model.skeleton,&"mannequin_humanoid_v1").is_empty(),"Invalid grip: "+id)
		check(not game.player.body_model.find_clip(profile.pose_animation).is_empty(),"Missing authored clip: "+id)
		diagnostic.select_item(id)
		await frames(65)
		contacts(diagnostic.character,id)
		check(game.player.body_model.held_items.active_grip.item_id==&"flashlight","Diagnostic changed actual gameplay hand")
	# Each imported pose must remain correct without the JSON quaternion fallback.
	for id in Items.ORDER:
		var authored: HandGripProfile=Items.grip(id).duplicate()
		authored.finger_rotations={}
		diagnostic.equip(authored)
		diagnostic.aim_index=2 if id=="water_bottle" else 0
		diagnostic.crouched=id=="bandage"
		diagnostic.walking=id=="field_radio"
		diagnostic.near_wall=id=="detector"
		await frames(65)
		contacts(diagnostic.character,id)
	diagnostic_viewport.queue_free()
	check(not game.equip_inventory_item("missing"),"Unknown item accepted")
	game.inventory.antiseptic=0
	check(not game.equip_inventory_item("antiseptic"),"Empty stack can equip")
	game.inventory.antiseptic=2
	pack.select_item("water_bottle")
	pack.equip_button.pressed.emit()
	check(game.equipped_item_id=="water_bottle","Cannot carry item from slot")
	await frames(8)
	check(game.player.body_model.held_items.active_grip.item_id==&"flashlight","Paused gameplay hand advanced its transition")
	key(KEY_ESCAPE)
	check(not game.inventory_open and game.player.active,"Escape failed to close and resume")
	check(not pack.visible,"Closed inventory remains visible")
	await frames(65)
	contacts(game.player.body_model,"water_bottle")
	check(not game.player.torch.visible,"Bottle retained flashlight beam")
	for id in Items.ORDER:
		check(game.equip_inventory_item(id),"Gameplay equip failed: "+id)
		await frames(65)
		contacts(game.player.body_model,id)
	# Item actions preserve stacks at full stats; healing/restoration is capped.
	game.player.health=100;game.player.stamina=100;game.player.battery_charge=100
	for id in ["bandage","food_tin","batteries","water_bottle","antiseptic"]:
		var before: int=game.inventory[id]
		check(not game.use_inventory_item(id) and game.inventory[id]==before,"Item wasted at full stat: "+id)
	for data in [["bandage","health",35.0],["antiseptic","health",20.0],["food_tin","stamina",45.0],["water_bottle","stamina",30.0],["batteries","battery_charge",60.0]]:
		game.inventory[data[0]]=2;game.player.set(data[1],10.0)
		check(game.use_inventory_item(data[0]),"Item action failed: "+data[0])
		check(is_equal_approx(game.player.get(data[1]),10.0+data[2]) and game.inventory[data[0]]==1,"Wrong restoration/quantity: "+data[0])
		game.player.set(data[1],95.0)
		check(game.use_inventory_item(data[0]) and is_equal_approx(game.player.get(data[1]),100),"Restoration not capped: "+data[0])
		check(not game.use_inventory_item(data[0]) and game.inventory[data[0]]==0,"Empty stack used: "+data[0])
	game.inventory.water_bottle=1;game.player.stamina=10
	game.equip_inventory_item("water_bottle")
	await frames(65)
	check(game.use_inventory_item("water_bottle") and game.equipped_item_id=="flashlight","Exhausted carried stack did not switch to flashlight")
	await frames(65)
	game.equip_inventory_item("detector")
	await frames(65)
	check(game.use_inventory_item("detector") and game.detector_enabled and not game.anomaly_readout().is_empty(),"Detector action failed")
	game.equip_inventory_item("field_radio")
	check(not game.detector_enabled,"Detector stayed active after stowing")
	check(game.use_inventory_item("field_radio") and "Station 04" in game.hud.message.text,"Receiver did not report objective")
	game.has_sample=true
	check(game.use_inventory_item("field_radio") and "Entry gate" in game.hud.message.text,"Receiver did not update return objective")
	game.has_sample=false
	check(game.equip_inventory_item(""),"Stow failed")
	await frames(65)
	check(game.player.body_model.held_items.item==null and not game.player.torch.visible,"Stow retained prop/beam")
	# Escape must work even while a card owns GUI keyboard focus.
	game.open_inventory();pack.item_buttons.flashlight.grab_focus()
	var escape := InputEventKey.new();escape.physical_keycode=KEY_ESCAPE;escape.pressed=true
	Input.parse_input_event(escape)
	await frames(1)
	check(not game.inventory_open and game.player.active,"Focused GUI swallowed Escape")
	escape.pressed=false;Input.parse_input_event(escape)
	key(KEY_TAB);check(game.inventory_open,"Tab did not open pack")
	key(KEY_TAB);check(not game.inventory_open and game.player.active,"Tab did not close pack")
	var cache: StaticBody3D
	for child in game.get_children():
		if child.get_meta("interaction","")=="loot_container":cache=child;break
	game.open_loot(cache);key(KEY_TAB)
	check(game.inventory_open and game.open_container==null and not game.hud.loot_panel.visible,"Loot/pack modal collision")
	game.pause_game()
	check(not game.inventory_open and not game.player.active and game.hud.overlay.visible,"Pause failed to dismiss pack")
	game.resume_game()
	check(game.player.active and not game.hud.overlay.visible,"Resume failed after pack")
	game.queue_free()
	await frames(3)
	print("INVENTORY_ITEMS_CHECK: failures=",failures)
	quit(1 if failures else 0)
