extends CharacterBody3D
## A single avoidable village threat. The player can outrun it and break sight.

var game: Node3D
var area_id := "perimeter"
var encounter_present := true
var routing = preload("res://scripts/runtime/pursuit_path.gd").new()
var station_mode := false
var search_time := 0.0
var footstep: AudioStreamPlayer3D
var footstep_timer := 0.0
var state := "patrol"
var points := [Vector3(-57,0,14),Vector3(-57,0,22),Vector3(-49,0,23),Vector3(-40,0,23),Vector3(-44,0,19),Vector3(-54,0,19)]
var point_index := 0
var last_known := Vector3.ZERO
var attention := 0.0
var attack_cooldown := 0.0
var sense_timer := 0.0
var blocked_time := 0.0
var step_phase := 0.0
var limbs: Array[Node3D]=[]
var body: Node3D
var breath: AudioStreamPlayer3D

func _ready() -> void:
	if name != "StationThreat": name="VillageStalker"
	var col:=CollisionShape3D.new()
	var shape:=CapsuleShape3D.new()
	shape.radius=0.34
	shape.height=1.75
	col.shape=shape
	col.position.y=0.875
	add_child(col)
	build_creature()
	build_breath()
	footstep = AudioStreamPlayer3D.new()
	footstep.bus = "Effects"
	footstep.volume_db = -24
	footstep.max_distance = 22
	var step_sound := AudioStreamWAV.new()
	step_sound.format = AudioStreamWAV.FORMAT_16_BITS
	step_sound.mix_rate = 22050
	var step_data := PackedByteArray()
	step_data.resize(6614)
	var step_rng := RandomNumberGenerator.new()
	step_rng.seed = 410
	for i in 3307:
		var t := float(i)/22050.0
		step_data.encode_s16(i*2, int((sin(TAU*85*t)*0.65+step_rng.randf_range(-0.35,0.35))*exp(-t*35)*14000))
	step_sound.data = step_data
	footstep.stream = step_sound
	add_child(footstep)

func mat(color: String) -> StandardMaterial3D:
	var m:=StandardMaterial3D.new()
	m.albedo_color=Color(color)
	m.roughness=1.0
	return m

func segment(parent: Node3D, a: Vector3, b: Vector3, radius: float, material: Material) -> void:
	var node:=MeshInstance3D.new()
	var mesh:=CapsuleMesh.new()
	mesh.radius=radius
	mesh.height=a.distance_to(b)+radius*2
	node.mesh=mesh
	node.material_override=material
	node.position=(a+b)*0.5
	node.quaternion=Quaternion(Vector3.UP,(b-a).normalized())
	parent.add_child(node)

func build_creature() -> void:
	var skin:=mat("615d4f")
	var clothing:=mat("343b30")
	var dark:=mat("262a24")
	body=Node3D.new()
	add_child(body)
	segment(body,Vector3(0,0.9,0),Vector3(0,1.42,-0.12),0.18,clothing)
	segment(body,Vector3(0,1.40,-0.12),Vector3(0,1.63,-0.18),0.115,skin)
	for side in [-1,1]:
		var arm:=Node3D.new()
		arm.position=Vector3(side*0.21,1.29,-0.08)
		body.add_child(arm)
		segment(arm,Vector3.ZERO,Vector3(side*0.08,-0.39,-0.04),0.065,clothing)
		segment(arm,Vector3(side*0.08,-0.39,-0.04),Vector3(side*0.1,-0.68,-0.13),0.045,skin)
		var leg:=Node3D.new()
		leg.position=Vector3(side*0.11,0.86,0)
		body.add_child(leg)
		segment(leg,Vector3.ZERO,Vector3(side*0.035,-0.39,0.06),0.085,dark)
		segment(leg,Vector3(side*0.035,-0.39,0.06),Vector3(side*0.03,-0.76,-0.08),0.065,clothing)
		limbs.append(arm)
		limbs.append(leg)
	var eye_mat:=mat("9a7454")
	eye_mat.emission_enabled=true
	eye_mat.emission=Color("8e6140")
	eye_mat.emission_energy_multiplier=0.35
	for x in [-0.043,0.043]:
		var eye:=MeshInstance3D.new()
		var eye_mesh:=SphereMesh.new()
		eye_mesh.radius=0.012
		eye_mesh.height=0.024
		eye.mesh=eye_mesh
		eye.material_override=eye_mat
		eye.position=Vector3(x,1.65,-0.283)
		body.add_child(eye)

func build_breath() -> void:
	breath=AudioStreamPlayer3D.new()
	breath.position=Vector3(0,1.4,0)
	breath.volume_db=-22
	breath.bus="Effects"
	breath.unit_size=5
	breath.max_distance=20
	var wav:=AudioStreamWAV.new()
	wav.format=AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate=22050
	wav.loop_mode=AudioStreamWAV.LOOP_FORWARD
	wav.loop_end=88200
	var data:=PackedByteArray()
	data.resize(wav.loop_end*2)
	var random:=RandomNumberGenerator.new()
	random.seed=633
	var filtered:=0.0
	for i in range(wav.loop_end):
		var t:=float(i)/wav.mix_rate
		filtered=filtered*0.88+random.randf_range(-1,1)*0.12
		var envelope:=pow(maxf(0,sin(TAU*t/2.0)),2.0)
		var fade:=minf(1.0,minf(t*5,(4-t)*5))
		data.encode_s16(i*2,int(filtered*envelope*fade*8500))
	wav.data=data
	breath.stream=wav
	add_child(breath)
	breath.play()

func has_line_to_player() -> bool:
	var target: CharacterBody3D=game.player
	var query:=PhysicsRayQueryParameters3D.create(global_position+Vector3.UP*1.35,target.global_position+Vector3.UP*(0.8 if target.crouching else 1.2))
	query.exclude=[get_rid(),target.get_rid()]
	query.collision_mask=1
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func sense_player() -> void:
	var target: CharacterBody3D=game.player
	var offset: Vector3=target.global_position-global_position
	var distance:=Vector2(offset.x,offset.z).length()
	var direction:=Vector3(offset.x,0,offset.z).normalized()
	var facing:=(-global_basis.z).dot(direction)
	var clear:=has_line_to_player()
	var sees:=distance<(7.0 if target.crouching else 13.0) and (facing>0.35 or distance<2.2) and clear
	var hears: bool=distance<float(target.noise_radius)*(1.0 if clear else 0.4)
	if sees:
		state="chase"
		last_known=target.global_position
		attention=5.0
	elif hears:
		last_known=target.global_position
		attention=5.0
		if state!="chase":
			state="investigate"

func _physics_process(delta: float) -> void:
	if not is_instance_valid(game) or not is_instance_valid(game.player) or not game.player.active or not encounter_present or (game.areas != null and game.areas.current != area_id):
		if is_instance_valid(breath):
			breath.stream_paused=true
		if is_instance_valid(footstep): footstep.stream_paused=true
		return
	breath.stream_paused=false
	footstep.stream_paused=false
	sense_timer-=delta
	attack_cooldown=maxf(0,attack_cooldown-delta)
	if sense_timer<=0:
		sense_timer=0.18
		sense_player()
	attention=maxf(0,attention-delta)
	if state!="patrol" and attention<=0:
		if state not in ["search", "retreat"]:
			state="search"
			search_time=16.0
	if state=="search":
		search_time-=delta
		if search_time<=0: state="retreat" if station_mode else "patrol"
	var destination: Vector3=points[0] if state=="retreat" else (points[point_index] if state in ["patrol", "search"] else last_known)
	# The creature returns to the village if the player escapes the area.
	if not station_mode and area_id == "perimeter" and game.player.global_position.x> -32 and state!="patrol":
		state="patrol"
		destination=points[point_index]
	var offset:=destination-global_position
	offset.y=0
	if offset.length()<0.8:
		if state in ["patrol", "search"]:
			point_index=(point_index+1)%points.size()
		else:
			if state=="retreat":
				breath.stop()
				set_physics_process(false)
			else:
				state="search"
				search_time=16.0
		velocity.x=0
		velocity.z=0
	else:
		var direction: Vector3 = routing.direction(self, destination, delta)
		var forward_check:=PhysicsRayQueryParameters3D.create(global_position+Vector3.UP*0.5,global_position+Vector3.UP*0.5+direction*0.85)
		forward_check.exclude=[get_rid(),game.player.get_rid()]
		if not get_world_3d().direct_space_state.intersect_ray(forward_check).is_empty():
			blocked_time+=delta
			direction=direction.rotated(Vector3.UP,PI/2 if point_index%2==0 else -PI/2)
			if blocked_time>3.0:
				state="search" if station_mode else "patrol"
				point_index=(point_index+1)%points.size()
				blocked_time=0
		else:
			blocked_time=maxf(0,blocked_time-delta)
		var speed:=4.15 if state=="chase" else 1.65
		velocity.x=move_toward(velocity.x,direction.x*speed,delta*9)
		velocity.z=move_toward(velocity.z,direction.z*speed,delta*9)
		rotation.y=lerp_angle(rotation.y,atan2(-direction.x,-direction.z),1.0-exp(-delta*5))
	if not is_on_floor():
		velocity.y-=20*delta
	move_and_slide()
	footstep_timer-=delta
	if Vector2(velocity.x,velocity.z).length()>0.3 and footstep_timer<=0:
		footstep.play()
		footstep_timer=0.38 if state=="chase" else 0.72
	step_phase+=delta*Vector2(velocity.x,velocity.z).length()*3
	for i in range(limbs.size()):
		limbs[i].rotation.x=sin(step_phase)*0.38*(1 if i in [0,3] else -1)
	body.rotation.z=sin(step_phase*0.5)*0.025
	if state=="chase" and attack_cooldown<=0 and global_position.distance_to(game.player.global_position)<1.25 and has_line_to_player():
		game.player.health=maxf(0,game.player.health-18)
		game.show_message("Something struck you. Break sight and run!",3)
		attack_cooldown=2.0
