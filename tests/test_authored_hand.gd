extends SceneTree
var failures := 0
var avatar: Node3D
func _initialize() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
	if not ok:
		failures+=1
		push_error(message)
func settle(crouched: bool=false,retraction: float=0.0,speed: float=0.0) -> void:
	for i in range(55):
		avatar.player.velocity=Vector3(0,0,-speed)
		avatar.animate_motion(1.0/60,speed/6.4,i*speed*2.6/60,crouched,true,Vector2.ZERO,false,retraction)
		await physics_frame
		await process_frame
func contacts() -> void:
	var held: HeldItemController=avatar.held_items
	for finger in ["thumb","index","middle","ring","pinky"]:
		var actual: Vector3=held.contact_positions[finger]
		var goal: Vector3=held.item.to_global(held.active_grip.contact_targets[finger])
		check(actual.distance_to(goal)<0.005,"Authored pose import drifted: "+finger+" "+str(actual.distance_to(goal)))
		if finger!="thumb":
			var skeleton: Skeleton3D=avatar.skeleton
			var wrist_rest := skeleton.get_bone_global_rest(skeleton.find_bone("hand.R"))
			var tip_rest := skeleton.get_bone_global_rest(skeleton.find_bone(finger+"3.R"))*Vector3(0,held.fingertip_lengths[finger],0)
			var open_tip := wrist_rest.affine_inverse()*tip_rest
			var closed_tip := held.socket.to_local(actual)
			var palm: Vector3 = (wrist_rest.basis.inverse()*avatar.profile_vector("anatomical_palm_normal")).normalized()
			check((closed_tip-open_tip).dot(palm)>0.01,"Finger curls backward, away from its anatomical palm: "+finger)
func run() -> void:
	var body := CharacterBody3D.new()
	root.add_child(body)
	var camera := Camera3D.new()
	camera.position=Vector3(0,1.69,-0.065)
	body.add_child(camera)
	avatar=load("res://scenes/characters/mannequin_hand_candidate.tscn").instantiate()
	body.add_child(avatar)
	avatar.build(camera,body)
	avatar.floor_ik_enabled=false
	check(avatar.hand_pose_node!=null,"Imported Blender pose assets missing")
	await settle()
	check(avatar.held_items.animated_fingers,"Finger animation layer not active")
	contacts()
	# The baked animation must work without the resource's quaternion fallback.
	var authored: HandGripProfile=load("res://assets/grips/flashlight.tres").duplicate()
	authored.finger_rotations={}
	avatar.equip_item(authored)
	await settle()
	contacts()
	avatar.equip_item(load("res://assets/grips/food_tin.tres"))
	await settle()
	contacts()
	var held: HeldItemController=avatar.held_items
	check((-held.item.global_basis.z).dot(Vector3.UP)>0.98,"Held tin is not upright at level aim")
	for item in [load("res://assets/grips/food_tin.tres"),load("res://assets/grips/flashlight.tres")]:
		avatar.equip_item(item)
		for state in [[-1.2,false,0.0,0.0],[1.2,false,0.0,3.5],[0.0,true,0.0,2.0],[0.0,false,0.65,0.0],[0.8,true,0.65,2.0]]:
			camera.rotation.x=state[0]
			camera.position.y=1.07 if state[1] else 1.69
			await settle(state[1],state[2],state[3])
			contacts()
			check(held.item.global_position.distance_to(camera.global_position)<0.9,"Held item escaped the arm during aim or retraction")
			if state[2]==0.0 and item.emits_light:
				check((-held.light.global_basis.z).dot(-camera.global_basis.z)>0.98,"Flashlight aim drifted during movement")
	camera.rotation.x=0
	avatar.held_items.grip_strength=0
	await settle()
	check(avatar.hand_pose_weight<0.01,"Authored pose cannot release")
	avatar.equip_item(null)
	await settle()
	check(avatar.held_items.item==null,"Authored pose unequip failed")
	body.queue_free()
	await process_frame
	print("AUTHORED_HAND_CHECK: failures=",failures)
	quit(1 if failures else 0)
