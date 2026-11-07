extends Node3D
var model: Node3D
var camera: Camera3D
var light: SpotLight3D
var studio:=false
var environment: Environment
var angle:=0.3
var capture: bool
var key_light: DirectionalLight3D
var fill_light: DirectionalLight3D
var night:=false
var animator: AnimationPlayer

func _ready() -> void:
	capture="--capture" in OS.get_cmdline_user_args()
	model=load("res://ashfall_hands_flashlight.glb").instantiate()
	add_child(model)
	var players=model.find_children("*","AnimationPlayer",true,false)
	if not players.is_empty():
		animator=players[0]
	camera=Camera3D.new()
	camera.fov=65
	camera.near=0.025
	add_child(camera)
	camera.current=true
	var world:=WorldEnvironment.new()
	environment=Environment.new()
	environment.background_mode=Environment.BG_COLOR
	environment.background_color=Color("283332")
	environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color=Color("b6c8c3")
	environment.ambient_light_energy=0.65
	environment.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	environment.ssao_enabled=true
	environment.ssao_intensity=1.6
	world.environment=environment
	add_child(world)
	var key:=DirectionalLight3D.new()
	key.rotation_degrees=Vector3(-42,-35,0)
	key.light_color=Color("eedac2")
	key.light_energy=1.5
	key.shadow_enabled=true
	add_child(key)
	key_light=key
	var fill:=DirectionalLight3D.new()
	fill.rotation_degrees=Vector3(-25,130,0)
	fill.light_energy=0.45
	fill.light_color=Color("91b5c4")
	add_child(fill)
	fill_light=fill
	var floor_mesh:=MeshInstance3D.new()
	var plane:=PlaneMesh.new()
	plane.size=Vector2(5,5)
	floor_mesh.mesh=plane
	floor_mesh.position=Vector3(0,-0.25,-1)
	var mat:=StandardMaterial3D.new()
	mat.albedo_color=Color("3a4039")
	floor_mesh.material_override=mat
	add_child(floor_mesh)
	light=SpotLight3D.new()
	light.light_energy=3.0
	light.spot_range=8
	light.spot_angle=30
	var emitter: Node3D=model.find_child("BeamOrigin",true,false)
	if emitter:
		emitter.add_child(light)
	else:
		push_error("Flashlight beam origin is missing")
	var layer:=CanvasLayer.new()
	add_child(layer)
	var text:=Label.new()
	text.position=Vector2(28,24)
	text.text="ASHFALL  /  PLAYER ASSET STUDY 02\nTAB  Studio / first person   F  Beam   L  Lighting   A  Motion\nMouse wheel  Rotate studio view     ESC  Quit"
	text.add_theme_color_override("font_color",Color("d1d3c5"))
	layer.add_child(text)
	set_camera()
	if capture:
		layer.hide()
		capture_views.call_deferred()

func set_camera() -> void:
	if studio:
		camera.position=Vector3(sin(angle)*0.8,0.55,cos(angle)*0.8-0.40)
		camera.look_at(Vector3(0,0.12,-0.4))
	else:
		camera.position=Vector3(0,0.37,0.16)
		camera.rotation=Vector3.ZERO

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode==KEY_TAB:
			studio=not studio
			set_camera()
		elif event.physical_keycode==KEY_F:
			light.visible=not light.visible
		elif event.physical_keycode==KEY_L:
			night=not night
			set_lighting()
		elif event.physical_keycode==KEY_A and is_instance_valid(animator):
			if animator.is_playing():
				animator.stop()
			else:
				for clip in animator.get_animation_list():
					if clip!="RESET":
						animator.get_animation(clip).loop_mode=Animation.LOOP_LINEAR
						animator.play(clip)
						break
		elif event.physical_keycode==KEY_ESCAPE:
			get_tree().quit()
	if event is InputEventMouseButton and event.pressed and studio:
		angle+=0.15 if event.button_index==MOUSE_BUTTON_WHEEL_DOWN else (-0.15 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 0.0)
		set_camera()

func set_lighting() -> void:
	environment.ambient_light_energy=0.19 if night else 0.65
	key_light.light_energy=0.2 if night else 1.5
	fill_light.light_energy=0.08 if night else 0.45
	environment.background_color=Color("0e171b") if night else Color("283332")

func capture_views() -> void:
	for mode in [false,true]:
		studio=mode
		set_camera()
		for i in range(25):
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://"+("studio.png" if studio else "first-person.png"))
	camera.position=Vector3(0.53,0.38,-0.13)
	camera.look_at(Vector3(0.255,0.17,-0.49))
	camera.fov=48
	for i in range(25):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://grip-detail.png")
	studio=false
	set_camera()
	camera.fov=65
	night=true
	set_lighting()
	for i in range(25):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://low-light.png")
	print("PLAYER_PREVIEW_RENDERED")
	get_tree().quit()
