extends CharacterBody3D

var camera: Camera3D
var torch: SpotLight3D
var active := false
var stamina := 100.0
var health := 100.0
var sensitivity := 0.0022
var step_time := 0.0
var crouching := false
var footsteps: AudioStreamPlayer
var was_moving := false
var sprint_exhausted := false
var collider: CollisionShape3D
var capsule: CapsuleShape3D
var body_model: Node3D
var look_sway := Vector2.ZERO
var jump_buffer := 0.0
var coyote_time := 0.0
var battery_charge := 100.0
var noise_radius := 0.0
var stamina_delay := 0.0
var wall_retraction := 0.0
const STANDING_HEIGHT := 1.8
const CROUCH_HEIGHT := 1.15

func _ready() -> void:
	collider = CollisionShape3D.new()
	capsule = CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 1.8
	collider.shape = capsule
	collider.position.y = 0.9
	add_child(collider)
	floor_snap_length=0.25
	camera = Camera3D.new()
	camera.position = Vector3(0, 1.69, -0.065)
	camera.near = 0.025
	camera.fov = 78
	camera.far = 160
	camera.current = true
	add_child(camera)
	body_model=load("res://scenes/characters/mannequin_player.tscn").instantiate()
	add_child(body_model)
	torch=body_model.build(camera,self)
	footsteps = AudioStreamPlayer.new()
	footsteps.volume_db = -28
	footsteps.bus = "Footsteps"
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	var bytes := PackedByteArray()
	bytes.resize(4400)
	var rng := RandomNumberGenerator.new()
	rng.seed = 55
	for i in range(2200):
		var sample := int(rng.randf_range(-1, 1) * exp(-float(i) / 360.0) * 23000)
		bytes.encode_s16(i * 2, sample)
	wav.data = bytes
	footsteps.stream = wav
	add_child(footsteps)

func set_view_direction(direction: Vector3) -> void:
	if direction.is_zero_approx():
		return
	var view := direction.normalized()
	# Body owns horizontal aim; the camera only pitches. Keep WASD and aim aligned.
	global_rotation = Vector3(0, atan2(-view.x, -view.z), 0)
	camera.rotation = Vector3(asin(clampf(view.y, -1, 1)), 0, 0)

func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * sensitivity)
		camera.rotation.x = clampf(camera.rotation.x - event.relative.y * sensitivity, -1.4, 1.4)
		look_sway=Vector2(clampf(event.relative.x*0.01,-1,1),clampf(event.relative.y*0.01,-1,1))
	if event is InputEventKey and event.pressed and not event.echo:
		if event.is_action_pressed("flashlight"):
			toggle_flashlight()

func toggle_flashlight() -> bool:
	if not body_model.can_use_flashlight():return false
	if torch.visible:
		torch.visible=false
		return true
	if battery_charge>0:
		torch.visible=true
		return true
	return false

func can_stand() -> bool:
	var standing := CapsuleShape3D.new()
	standing.radius=0.3
	standing.height=STANDING_HEIGHT
	var query:=PhysicsShapeQueryParameters3D.new()
	query.shape=standing
	query.transform=Transform3D(Basis.IDENTITY,global_position+Vector3.UP*(STANDING_HEIGHT*0.5+0.035))
	query.collision_mask=collision_mask
	query.exclude=[get_rid()]
	return get_world_3d().direct_space_state.intersect_shape(query,1).is_empty()

func _physics_process(delta: float) -> void:
	if not active:
		return
	var direction := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var wants_crouch:=Input.is_action_pressed("crouch")
	if wants_crouch:
		crouching=true
	elif crouching and can_stand():
		crouching=false
	var height:=CROUCH_HEIGHT if crouching else STANDING_HEIGHT
	if not is_equal_approx(capsule.height,height):
		capsule.height=height
		collider.position.y=height*0.5
	if sprint_exhausted and stamina >= 25:
		sprint_exhausted = false
	var sprint := Input.is_action_pressed("sprint") and direction.y < -0.2 and stamina > 0 and not sprint_exhausted and not crouching and is_on_floor()
	var speed := 6.4 if sprint else (2.0 if crouching else 3.5)
	if direction.y > 0.1:
		speed *= 0.8
	if sprint:
		stamina_delay=0.8
		stamina=clampf(stamina-24.0*delta,0,100)
	else:
		stamina_delay=maxf(stamina_delay-delta,0)
		if stamina_delay<=0:
			stamina=clampf(stamina+16.0*delta,0,100)
	if stamina <= 0:
		sprint_exhausted = true
	var forward := transform.basis * Vector3(direction.x, 0, direction.y)
	var acceleration:= (24.0 if direction.length()>0.1 else 30.0) if is_on_floor() else 5.0
	velocity.x = move_toward(velocity.x, forward.x * speed, delta * acceleration)
	velocity.z = move_toward(velocity.z, forward.z * speed, delta * acceleration)
	jump_buffer=maxf(0.0,jump_buffer-delta)
	coyote_time=0.1 if is_on_floor() else maxf(0.0,coyote_time-delta)
	if Input.is_action_just_pressed("jump"):
		jump_buffer=0.14
	if not is_on_floor():
		velocity.y -= 20 * delta
	if jump_buffer>0 and coyote_time>0 and not crouching:
		velocity.y = 5.0
		jump_buffer=0
		coyote_time=0
	move_and_slide()
	var horizontal_speed:=Vector2(velocity.x,velocity.z).length()
	var moving := horizontal_speed > 0.3 and is_on_floor()
	noise_radius = (2.0 if crouching else (10.0 if sprint else 5.0)) if moving else 0.0
	if torch.visible:
		battery_charge=maxf(0,battery_charge-delta*0.28)
		if battery_charge<=0:
			torch.visible=false
	if moving:
		var old_step := int(step_time / PI)
		step_time += delta * clampf(horizontal_speed*2.6,4.0,14.0)
		if int(step_time / PI) != old_step:
			footsteps.volume_db = -36 if crouching else (-24 if sprint else -28)
			footsteps.pitch_scale = randf_range(0.8, 1.1)
			footsteps.play()
	var bob := sin(step_time)*0.013*clampf(horizontal_speed/3.5,0.0,1.0) if moving else 0.0
	camera.position.y = lerpf(camera.position.y, (1.07 if crouching else 1.69) + bob, 1.0-exp(-delta*12))
	# A small forward head lean lets the real torso and boots remain visible below.
	var down_lean := clampf(-camera.rotation.x / 1.2, 0, 1) * 0.16
	camera.position.z = lerpf(camera.position.z, -0.065-down_lean, 1.0-exp(-delta*12))
	camera.fov = lerpf(camera.fov, 82.0 if sprint else 78.0, 1.0-exp(-delta*5))
	# Pull the view model back when a wall is closer than the held light.
	var query:=PhysicsRayQueryParameters3D.create(camera.global_position,camera.global_position-camera.global_basis.z*1.0)
	query.exclude=[get_rid()]
	query.collision_mask=collision_mask
	var hit:=get_world_3d().direct_space_state.intersect_ray(query)
	var target_retraction:=clampf(0.85-camera.global_position.distance_to(hit.position),0,0.65) if not hit.is_empty() else 0.0
	wall_retraction=lerpf(wall_retraction,target_retraction,1.0-exp(-delta*18))
	body_model.animate_motion(delta,clampf(horizontal_speed/6.4,0,1),step_time,crouching,is_on_floor(),look_sway,torch.visible,wall_retraction)
	look_sway=look_sway.move_toward(Vector2.ZERO,delta*4)
