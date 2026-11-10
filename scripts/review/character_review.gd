extends Node3D
@export var character_scene: PackedScene = preload("res://scenes/characters/scavenger.tscn")
@export var capture_directory := "res://reviews/character"
@export var review_title := "DRESSED CHARACTER STUDY"
## A live, full-body inspection scene using the exact game character and adapter.
var controller: CharacterBody3D
var character: Node3D
var camera: Camera3D
var eyes: Camera3D
var label: Label
var angle := 0.2
var elevation := 0.14
var distance := 3.0
var focus := Vector3(0, 0.97, 0)
var phase := 0.0
var mode := "Idle"
var first_person := false
var capture := false
var floor_mesh: MeshInstance3D

func _ready() -> void:
	capture = "--capture-character" in OS.get_cmdline_user_args()
	controller = CharacterBody3D.new()
	controller.name = "ReviewSubject"
	add_child(controller)
	eyes = Camera3D.new()
	eyes.position = Vector3(0, 1.69, -0.065)
	eyes.near = 0.025
	eyes.fov = 78
	controller.add_child(eyes)
	character = character_scene.instantiate()
	controller.add_child(character)
	character.build(eyes, controller)
	character.floor_ik_enabled = false
	camera = Camera3D.new()
	camera.fov = 38
	camera.near = 0.025
	camera.cull_mask = 3
	add_child(camera)
	camera.current = true
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("202723")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("bdc8cb")
	environment.ambient_light_energy = 0.55
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.ssao_enabled = true
	environment.ssao_intensity = 1.2
	world.environment = environment
	add_child(world)
	for item in [[Vector3(-38,-40,0),Color("ffdcba"),2.5],[Vector3(-22,135,0),Color("98bbd4"),1.3]]:
		var key := DirectionalLight3D.new()
		key.rotation_degrees = item[0]
		key.light_color = item[1]
		key.light_energy = item[2]
		key.shadow_enabled = true
		add_child(key)
	floor_mesh = MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(200,200)
	floor_mesh.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("424940")
	mat.roughness = 0.9
	floor_mesh.material_override = mat
	floor_mesh.position.y = -0.003
	add_child(floor_mesh)
	if not character.character_profile.is_empty():
		var ground := StaticBody3D.new()
		var collider := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(200,0.1,200)
		collider.shape = shape
		ground.position.y = -0.05
		ground.add_child(collider)
		add_child(ground)
		character.floor_ik_enabled = true
	var layer := CanvasLayer.new()
	add_child(layer)
	label = Label.new()
	label.position = Vector2(28,22)
	label.add_theme_color_override("font_color", Color("deddd1"))
	layer.add_child(label)
	update_label()
	update_camera()
	if capture:
		layer.hide()
		capture_views.call_deferred()

func update_label() -> void:
	label.text = "ASHFALL / "+review_title+"\n1 Front   2 Back   3 Side   4 Face   5 First person   6 Look down   7 Grip\nRight-drag orbit / aim   Wheel zoom   Space Walk   Shift Run   C Crouch   F Light   Esc Release mouse\nPose: " + mode + "  |  Full body and hand-mounted light"

func update_camera() -> void:
	if first_person:
		eyes.current = true
	else:
		camera.current = true
		camera.position = focus + Vector3(sin(angle)*cos(elevation), sin(elevation), -cos(angle)*cos(elevation))*distance
		camera.look_at(focus)

func preset(number: int) -> void:
	first_person = number == 5 or number == 6
	character.set_first_person(first_person)
	focus = Vector3(0,0.97,0)
	distance = 3.0
	elevation = 0.10
	angle = 0
	if number < 5:
		eyes.rotation.x = 0
	match number:
		2: angle = PI
		3: angle = PI/2
		4:
			focus = Vector3(0,1.675,-0.035)
			distance = 0.64
			elevation = 0.05
			angle = 0.25
		5: eyes.rotation.x = 0
		6: eyes.rotation.x = -1.4
		7:
			focus = Vector3(0.205,1.455,-0.43)
			distance = 0.48
			elevation = 0.18
			angle = 0.9
	update_camera()

func _process(delta: float) -> void:
	var speed := 0.0
	if mode == "Walk": speed = 3.5
	if mode == "Run": speed = 6.4
	if mode == "CrouchWalk": speed = 2.0
	phase += delta * speed * 2.6
	controller.velocity = Vector3(0,0,-speed)
	character.animate_motion(delta, speed/6.4, phase, mode.begins_with("Crouch"), true, Vector2.ZERO, character.torch.visible)
	eyes.position.y = lerpf(eyes.position.y, 1.07 if mode.begins_with("Crouch") else 1.69, 1-exp(-delta*12))
	eyes.position.z = lerpf(eyes.position.z, -0.065-clampf(-eyes.rotation.x/1.2,0,1)*0.16,1-exp(-delta*12))

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		if first_person:
			eyes.rotation.x = clampf(eyes.rotation.x-event.relative.y*0.004,-1.35,1.35)
			controller.rotate_y(-event.relative.x*0.004)
		else:
			angle -= event.relative.x*0.005
			elevation = clampf(elevation+event.relative.y*0.004,-0.4,1.0)
		update_camera()
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP: distance = maxf(0.35,distance*0.9)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN: distance = minf(8,distance*1.1)
		update_camera()
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode >= KEY_1 and event.physical_keycode <= KEY_7:
			preset(event.physical_keycode-KEY_1+1)
		match event.physical_keycode:
			KEY_SPACE: mode = "Idle" if mode == "Walk" else "Walk"
			KEY_SHIFT: mode = "Idle" if mode == "Run" else "Run"
			KEY_C: mode = "Idle" if mode.begins_with("Crouch") else "CrouchWalk"
			KEY_F: character.torch.visible = not character.torch.visible
			KEY_ESCAPE: Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		update_label()

func capture_views() -> void:
	var dir := capture_directory
	DirAccess.make_dir_recursive_absolute(dir)
	for item in [[1,"front"],[2,"back"],[3,"side"],[4,"face"],[5,"first-person"],[6,"look-down"]]:
		preset(item[0])
		await get_tree().create_timer(0.4).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(dir+"/"+item[1]+".png")
	preset(1)
	mode = "CrouchWalk"
	await get_tree().create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(dir+"/crouch.png")
	mode = "Idle"
	preset(7)
	first_person = false
	character.set_first_person(false)
	update_camera()
	await get_tree().create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(dir+"/grip.png")
	print("CHARACTER_REVIEW_CAPTURED")
	get_tree().quit()
