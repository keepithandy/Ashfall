extends Node3D
## Anatomy-only inspection. Does not instantiate the game controller or wardrobe.
var mannequin: Node3D
var camera: Camera3D
var animator: AnimationPlayer
var label: Label
var angle := 0.28
var elevation := 0.08
var distance := 3.0
var focus := Vector3(0, 0.94, 0)
var orthographic := true
var posing := false

func _ready() -> void:
	mannequin = load("res://scenes/characters/male_mannequin.tscn").instantiate()
	add_child(mannequin)
	animator = mannequin.find_children("*", "AnimationPlayer", true, false)[0]
	camera = Camera3D.new()
	camera.near = 0.015
	camera.fov = 38
	camera.size = 2.10
	add_child(camera)
	camera.current = true
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("222b30")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("b8c7cc")
	environment.ambient_light_energy = 0.45
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.ssao_enabled = true
	environment.ssao_intensity = 0.8
	world.environment = environment
	add_child(world)
	for item in [[Vector3(-35,-40,0),Color("f5e4d1"),1.7],[Vector3(-25,130,0),Color("adc5dd"),0.9]]:
		var light := DirectionalLight3D.new()
		light.rotation_degrees = item[0]
		light.light_color = item[1]
		light.light_energy = item[2]
		light.shadow_enabled = true
		light.directional_shadow_max_distance = 8
		add_child(light)
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(200,200)
	floor_mesh.mesh = plane
	floor_mesh.position.y = -0.002
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("39434a")
	material.roughness = 1
	floor_mesh.material_override = material
	add_child(floor_mesh)
	var canvas := CanvasLayer.new()
	add_child(canvas)
	label = Label.new()
	label.position = Vector2(25,22)
	label.add_theme_color_override("font_color",Color("d7dfe0"))
	label.text = "ASHFALL / MALE MANNEQUIN — ANATOMY STUDY\n1 Front   2 Back   3 Side   4 Three-quarter   5 Head   6 Hand   7 Feet\nRight-drag orbit   Wheel zoom   O Perspective / orthographic   P Joint test\nContinuous body, neutral clay, no clothing or equipment  |  1.80 m"
	canvas.add_child(label)
	set_view(4)
	if "--capture-mannequin" in OS.get_cmdline_user_args():
		canvas.hide()
		capture_views.call_deferred()

func set_view(view: int) -> void:
	angle = 0
	elevation = 0
	focus = Vector3(0,0.92,0)
	camera.size = 2.08
	distance = 3
	match view:
		2: angle = PI
		3: angle = PI/2
		4:
			angle = 0.45
			elevation = 0.06
		5:
			focus = Vector3(0,1.68,-0.015)
			camera.size = 0.40
			distance = 0.65
			angle = 0.20
		6:
			focus = Vector3(0.53,1.05,-0.25)
			camera.size = 0.37
			distance = 0.6
			angle = 0.55
		7:
			focus = Vector3(0,0.10,-0.025)
			camera.size = 0.65
			distance = 1.0
			angle = 0.45
			elevation = 0.30
	update_camera()

func update_camera() -> void:
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL if orthographic else Camera3D.PROJECTION_PERSPECTIVE
	camera.position = focus + Vector3(sin(angle)*cos(elevation),sin(elevation),-cos(angle)*cos(elevation))*distance
	camera.look_at(focus)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		angle -= event.relative.x*0.005
		elevation = clampf(elevation+event.relative.y*0.004,-0.5,1.2)
		update_camera()
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.size = maxf(0.2,camera.size*0.9)
			distance = maxf(0.3,distance*0.9)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.size = minf(5,camera.size*1.1)
			distance = minf(8,distance*1.1)
		update_camera()
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode >= KEY_1 and event.physical_keycode <= KEY_7:
			set_view(event.physical_keycode-KEY_1+1)
		if event.physical_keycode == KEY_O:
			orthographic = not orthographic
			update_camera()
		if event.physical_keycode == KEY_P:
			posing = not posing
			if posing:
				for clip in animator.get_animation_list():
					if String(clip).ends_with("JointInspection"):
						animator.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
						animator.play(clip,0.15)
			else:
				animator.seek(0,true)
				animator.pause()

func capture_views() -> void:
	var dir := "res://reviews/mannequin"
	DirAccess.make_dir_recursive_absolute(dir)
	for item in [[1,"front"],[2,"back"],[3,"side"],[4,"three-quarter"],[5,"head"],[6,"hand"],[7,"feet"]]:
		set_view(item[0])
		await get_tree().create_timer(0.15).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(dir+"/"+item[1]+".png")
	print("MANNEQUIN_REVIEW_CAPTURED")
	get_tree().quit()
