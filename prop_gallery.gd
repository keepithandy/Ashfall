extends Node3D

var inspector: CharacterBody3D
var caption: Label
var review := false

func _ready() -> void:
	review = "--prop-review" in OS.get_cmdline_user_args()
	# Reuse the game's existing bindings and player controller.
	var bindings = load("res://game.gd").new()
	bindings.setup_input()
	bindings.free()
	var floor_body := StaticBody3D.new()
	var floor_mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(30,0.2,30)
	floor_mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("303b40")
	mat.roughness = 0.9
	floor_mesh.material_override = mat
	floor_body.position = Vector3(0,-0.11,-4)
	floor_body.add_child(floor_mesh)
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = box.size
	collider.shape = shape
	floor_body.add_child(collider)
	add_child(floor_body)
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("303b40")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("c5d2db")
	env.ambient_light_energy = 0.65
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.ssao_enabled = true
	env.ssao_radius = 0.5
	env.ssao_intensity = 1.8
	world.environment = env
	add_child(world)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-48,-25,0)
	key.light_color = Color("ffe6ca")
	key.light_energy = 1.7
	key.shadow_enabled = true
	key.directional_shadow_max_distance = 40
	add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-30,145,0)
	fill.light_color = Color("a9d0ec")
	fill.light_energy = 0.6
	add_child(fill)
	inspector = CharacterBody3D.new()
	inspector.set_script(load("res://player.gd"))
	inspector.position = Vector3(0,0.1,6)
	add_child(inspector)
	inspector.set_view_direction(Vector3(0,-0.1,-1))
	inspector.torch.visible = false
	var layer := CanvasLayer.new()
	add_child(layer)
	caption = Label.new()
	caption.text = "ASHFALL  /  PROP LIBRARY\n%d reusable scenes  ·  Click to explore  ·  WASD + mouse  ·  ESC releases mouse  ·  F torch" % $Displays.get_child_count()
	caption.position = Vector2(24,20)
	caption.add_theme_font_size_override("font_size",18)
	layer.add_child(caption)
	get_window().focus_exited.connect(func():
		inspector.active = false
		inspector.velocity = Vector3.ZERO
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE)
	if review:
		capture_reviews.call_deferred()

func _unhandled_input(event: InputEvent) -> void:
	if review:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		inspector.active = true
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed("pause"):
		inspector.active = false
		inspector.velocity = Vector3.ZERO
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func capture_reviews() -> void:
	var folder := "res://reviews/nature/" if name == "NaturalPropGallery" else "res://reviews/props/"
	if name == "WorkshopGallery":
		folder="res://reviews/workshop/"
	DirAccess.make_dir_recursive_absolute(folder)
	caption.hide()
	var camera: Camera3D = inspector.camera
	camera.fov = 52
	var rows := ceili(float($Displays.get_child_count())/6)
	camera.global_position = Vector3(12,13,18)
	camera.look_at(Vector3(0,0.4,-float(rows-1)*1.5))
	await frames(20)
	get_viewport().get_texture().get_image().save_png(folder+"gallery.png")
	var sheet := Image.create(2304,384*rows,false,Image.FORMAT_RGB8)
	sheet.fill(Color("536065"))
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	caption.show()
	caption.position = Vector2(280,650)
	caption.size = Vector2(720,50)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size",28)
	var displays := $Displays.get_children()
	for item in displays:
		item.hide()
	var index := 0
	for display in displays:
		display.show()
		display.get_node("Caption").hide()
		var prop: Node3D = display.get_child(0)
		var size: Vector3 = prop.get_meta("approximate_size_metres")*prop.scale
		var target: Vector3 = display.global_position + Vector3(0,0.08+size.y*0.45,0)
		var span := maxf(size.x,maxf(size.y,size.z))
		camera.size = maxf(0.3,span*1.7)
		camera.global_position = target + Vector3(3,2,4).normalized() * (span*4+2)
		camera.look_at(target)
		caption.text = "%02d  %s" % [index+1,display.get_meta("title")]
		await frames(8)
		var shot := get_viewport().get_texture().get_image()
		var crop := shot.get_region(Rect2i(280,0,720,720))
		crop.convert(Image.FORMAT_RGB8)
		crop.resize(384,384,Image.INTERPOLATE_LANCZOS)
		sheet.blit_rect(crop,Rect2i(0,0,384,384),Vector2i((index%6)*384,(index/6)*384))
		if display.name in ["portable_generator","jerrycan","steel_drum","warning_sign"]:
			shot.save_png(folder+str(display.name)+".png")
		display.hide()
		index += 1
	sheet.save_png(folder+"prop-catalog.png")
	print("PROP_REVIEW_CAPTURED: gallery and ",displays.size(),"-asset contact sheet")
	get_tree().quit()

func frames(count: int) -> void:
	for i in range(count):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
