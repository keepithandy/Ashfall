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

func _ready() -> void:
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 1.8
	shape.shape = capsule
	shape.position.y = 0.9
	add_child(shape)
	camera = Camera3D.new()
	camera.position.y = 1.62
	camera.fov = 78
	camera.far = 160
	camera.current = true
	add_child(camera)
	torch = SpotLight3D.new()
	torch.position = Vector3(0.22, -0.18, -0.1)
	torch.light_color = Color(0.91, 0.92, 0.78)
	torch.light_energy = 3.5
	torch.spot_range = 24
	torch.spot_angle = 34
	torch.spot_attenuation = 0.75
	torch.shadow_enabled = true
	camera.add_child(torch)
	footsteps = AudioStreamPlayer.new()
	footsteps.volume_db = -18
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
	if event is InputEventKey and event.pressed and not event.echo:
		if event.is_action_pressed("flashlight"):
			torch.visible = not torch.visible

func _physics_process(delta: float) -> void:
	if not active:
		return
	var direction := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	crouching = Input.is_action_pressed("crouch")
	if sprint_exhausted and stamina >= 25:
		sprint_exhausted = false
	var sprint := Input.is_action_pressed("sprint") and direction.y < -0.2 and stamina > 0 and not sprint_exhausted and not crouching
	var speed := 6.4 if sprint else (2.0 if crouching else 3.5)
	stamina = clampf(stamina + (-24.0 if sprint else 16.0) * delta, 0, 100)
	if stamina <= 0:
		sprint_exhausted = true
	var forward := (transform.basis * Vector3(direction.x, 0, direction.y)).normalized()
	velocity.x = move_toward(velocity.x, forward.x * speed, delta * 25)
	velocity.z = move_toward(velocity.z, forward.z * speed, delta * 25)
	if not is_on_floor():
		velocity.y -= 20 * delta
	elif Input.is_action_just_pressed("jump") and not crouching:
		velocity.y = 5.0
	move_and_slide()
	var moving := direction.length() > 0.1 and is_on_floor()
	if moving:
		var old_step := int(step_time / PI)
		step_time += delta * (13 if sprint else 9)
		if int(step_time / PI) != old_step:
			footsteps.pitch_scale = randf_range(0.8, 1.1)
			footsteps.play()
	var bob := sin(step_time) * 0.025 if moving else 0.0
	camera.position.y = lerpf(camera.position.y, (1.08 if crouching else 1.62) + bob, delta * 12)
	camera.fov = lerpf(camera.fov, 84.0 if sprint else 78.0, delta * 5)
