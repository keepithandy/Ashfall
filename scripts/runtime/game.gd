extends Node3D

const PlayerScript = preload("res://scripts/runtime/player.gd")
const HudScript = preload("res://scripts/runtime/hud.gd")
const Items = preload("res://scripts/runtime/item_catalog.gd")
const AudioSettings = preload("res://scripts/runtime/audio_settings.gd")
var audio_settings = AudioSettings.new()
var player: CharacterBody3D
var hud: Control
var rng := RandomNumberGenerator.new()
var started := false
var has_sample := false
var finished := false
var hazard_strength := 0.0
var elapsed := 0.0
var message_time := 0.0
var anomalies: Array[Node3D] = []
var sample: StaticBody3D
var gate: StaticBody3D
var supplies: StaticBody3D
var concrete: StandardMaterial3D
var rust: StandardMaterial3D
var dark: StandardMaterial3D
var smoke_test := false
var ambience: AudioStreamPlayer
var inventory := Items.initial_loadout()
var inventory_open := false
var inventory_feedback := ""
var equipped_item_id := "flashlight"
var detector_enabled := false
var open_container: StaticBody3D
var baking_editable_world := false
var areas: Node3D
var crossroads: Node3D

func material(color: Color, roughness: float = 0.9, emission: float = 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	if emission > 0:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = emission
	return mat

func weathered(color: Color, seed_value: int) -> StandardMaterial3D:
	var mat := material(color)
	var noise := FastNoiseLite.new()
	noise.seed = seed_value
	noise.frequency = 0.018
	var texture := NoiseTexture2D.new()
	texture.width = 256
	texture.height = 256
	texture.noise = noise
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.64, 0.64, 0.64))
	gradient.set_color(1, Color(0.95, 0.95, 0.95))
	texture.color_ramp = gradient
	mat.albedo_texture = texture
	mat.uv1_triplanar = true
	mat.uv1_scale = Vector3(0.22, 0.22, 0.22)
	return mat

func box(at: Vector3, dimensions: Vector3, mat: Material, solid: bool = true, parent: Node3D = self) -> Node3D:
	var root: Node3D = StaticBody3D.new() if solid else Node3D.new()
	root.position = at
	parent.add_child(root)
	var mesh := MeshInstance3D.new()
	var cube := BoxMesh.new()
	cube.size = dimensions
	mesh.mesh = cube
	mesh.material_override = mat
	root.add_child(mesh)
	if solid:
		var collider := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = dimensions
		collider.shape = shape
		root.add_child(collider)
	return root

func cylinder(at: Vector3, radius_bottom: float, radius_top: float, height: float, mat: Material, parent: Node3D = self) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := CylinderMesh.new()
	shape.bottom_radius = radius_bottom
	shape.top_radius = radius_top
	shape.height = height
	shape.radial_segments = 8
	mesh.mesh = shape
	mesh.material_override = mat
	mesh.position = at
	parent.add_child(mesh)
	return mesh

func lamp(at: Vector3, tint: Color = Color("ffbd70")) -> void:
	box(at + Vector3(0, 1.4, 0), Vector3(0.11, 2.8, 0.11), dark)
	box(at + Vector3(0, 2.85, 0), Vector3(0.42, 0.16, 0.42), material(tint, 0.7, 0.9), false)
	var light := OmniLight3D.new()
	light.position = at + Vector3(0, 2.6, 0)
	light.light_color = tint
	light.light_energy = 1.5
	light.omni_range = 8
	light.light_volumetric_fog_energy = 0.2
	light.shadow_enabled = true
	light.add_to_group("perimeter_lamps",true)
	add_child(light)

func _ready() -> void:
	rng.seed = 2049
	smoke_test = "--smoke-test" in OS.get_cmdline_user_args()
	audio_settings.setup()
	setup_input()
	concrete = weathered(Color("858b87"), 1)
	rust = weathered(Color("815f40"), 2)
	dark = material(Color("292f2b"))
	var saved_world:=get_node_or_null("EditableWorld")
	if is_instance_valid(saved_world):
		bind_editable_world(saved_world)
	else:
		build_environment()
		build_level()
	if baking_editable_world:
		return
	player = CharacterBody3D.new()
	player.set_script(PlayerScript)
	player.position = Vector3(0, 0.1, 25)
	add_child(player)
	var stalker:=CharacterBody3D.new()
	stalker.set_script(load("res://scripts/runtime/village_stalker.gd"))
	stalker.game=self
	stalker.position=Vector3(-57,0.1,14)
	add_child(stalker)
	if "--house-tour" in OS.get_cmdline_user_args():
		player.position = Vector3(-4.4, 0.1, 16.2)
		player.set_view_direction(Vector3(-10, 1.6, 12) - player.camera.global_position)
	if "--village-tour" in OS.get_cmdline_user_args():
		player.position=Vector3(-39,0.1,18)
		player.set_view_direction(Vector3(-46,2,8)-player.camera.global_position)
	var canvas := CanvasLayer.new()
	add_child(canvas)
	hud = Control.new()
	hud.set_script(HudScript)
	hud.game = self
	canvas.add_child(hud)
	crossroads = get_node_or_null("CrossroadsMaintenanceStation/MaintenanceDressing")
	if crossroads != null: crossroads.setup(self)
	if crossroads != null:
		areas = Node3D.new()
		areas.set_script(load("res://scripts/runtime/expedition_areas.gd"))
		add_child(areas)
		areas.setup(self)
	build_sound()
	var atmosphere := Node3D.new()
	atmosphere.set_script(load("res://scripts/runtime/atmosphere.gd"))
	atmosphere.game = self
	add_child(atmosphere)
	get_window().focus_exited.connect(_on_window_focus_exited)
	if "--house-review" in OS.get_cmdline_user_args():
		run_house_review.call_deferred()
	elif smoke_test:
		run_smoke_test.call_deferred()
	elif "--inventory-review" in OS.get_cmdline_user_args():
		smoke_test=true
		run_inventory_review.call_deferred()
	elif "--open-pack" in OS.get_cmdline_user_args():
		start_inventory_test.call_deferred()

func bind_editable_world(world: Node) -> void:
	# Use the saved editor nodes as the actual gameplay objects.
	for object in world.find_children("*","StaticBody3D",true,false):
		match object.get_meta("interaction",""):
			"sample": sample=object
			"supplies": supplies=object
			"gate": gate=object
	for object in world.find_children("*","Node3D",true,false):
		if object.is_in_group("world_anomalies"):
			anomalies.append(object)
	if not is_instance_valid(sample) or not is_instance_valid(supplies) or not is_instance_valid(gate):
		push_error("Editable world is missing a sample, medical supplies, or extraction terminal.")

func setup_input() -> void:
	var keys := {
		"move_forward": KEY_W, "move_back": KEY_S, "move_left": KEY_A, "move_right": KEY_D,
		"sprint": KEY_SHIFT, "crouch": KEY_CTRL, "jump": KEY_SPACE,
		"flashlight": KEY_F, "interact": KEY_E, "pause": KEY_ESCAPE,
		"use_bandage": KEY_H, "use_food": KEY_G, "reload_battery": KEY_R,
		"inventory": KEY_TAB, "use_held_item": KEY_Q
	}
	for action: String in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var event := InputEventKey.new()
		event.physical_keycode = keys[action]
		if not InputMap.action_has_event(action, event):
			InputMap.action_add_event(action, event)

func build_environment() -> void:
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("08121e")
	sky_mat.sky_horizon_color = Color("14232e")
	sky_mat.ground_bottom_color = Color("1c2420")
	sky_mat.ground_horizon_color = Color("14232e")
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("8195aa")
	env.ambient_light_energy = 0.17
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.ssao_enabled = true
	env.ssao_intensity = 1.6
	env.ssao_radius = 1.0
	env.ssil_enabled = true
	env.ssil_intensity = 0.6
	env.glow_enabled = true
	env.glow_intensity = 0.12
	env.fog_enabled = true
	env.fog_light_color = Color("172833")
	env.fog_light_energy = 0.38
	env.fog_density = 0.009
	env.fog_sky_affect = 0.5
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = 0.009
	env.volumetric_fog_albedo = Color("9eb9b6")
	env.volumetric_fog_length = 70
	env.volumetric_fog_ambient_inject = 0.15
	environment.environment = env
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-18, -35, 0)
	sun.light_color = Color("7e9fae")
	sun.light_energy = 0.19
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 70
	add_child(sun)

func build_level() -> void:
	box(Vector3(0, -0.5, -10), Vector3(180, 1, 200), weathered(Color("454e42"), 4))
	# Keep exploration on the finished ground, beyond the visible fog line.
	var bounds := StaticBody3D.new()
	bounds.name = "ExplorationBoundary"
	add_child(bounds)
	for boundary in [Vector4(-86,0,1,192),Vector4(86,0,1,192),Vector4(0,-106,172,1),Vector4(0,86,172,1)]:
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(boundary.z,12,boundary.w)
		collision.shape = shape
		collision.position = Vector3(boundary.x,5,boundary.y)
		bounds.add_child(collision)
	box(Vector3(0, -0.0085, -6), Vector3(7, 0.025, 77), weathered(Color("4a4d47"), 7), false)
	for z in range(-42, 30, 6):
		box(Vector3(0, -0.0065, z), Vector3(0.13, 0.025, 2.2), material(Color("b1ad82")), false)
	for x in [-32, 32]:
		if x == -32:
			# A five-metre opening connects the village lane to the existing level.
			box(Vector3(x,1.5,-17.75),Vector3(0.5,3,72.5),concrete)
			box(Vector3(x,1.5,27.75),Vector3(0.5,3,8.5),concrete)
		else:
			box(Vector3(x, 1.5, -11), Vector3(0.5, 3, 86), concrete)
		for z in range(-52, 33, 6):
			box(Vector3(x, 3.15, z), Vector3(0.13, 0.8, 0.13), rust, false)
	box(Vector3(0, 1.5, -54), Vector3(64, 3, 0.5), concrete)
	box(Vector3(-19, 1.5, 32), Vector3(26, 3, 0.5), concrete)
	box(Vector3(19, 1.5, 32), Vector3(26, 3, 0.5), concrete)
	box(Vector3(0, 1.3, 32), Vector3(12, 2.6, 0.3), dark)
	for x in [-5.5, 5.5]:
		box(Vector3(x, 3.2, 17), Vector3(0.7, 6.4, 0.7), concrete)
	box(Vector3(0, 6.2, 17), Vector3(12, 1.3, 0.6), dark)
	var house: Node3D = load("res://scenes/checkpoint_house.tscn").instantiate()
	house.position = Vector3(-10, 0, 11)
	add_child(house)
	var checkpoint_props: Node3D = load("res://scenes/checkpoint_props.tscn").instantiate()
	add_child(checkpoint_props)
	var perimeter_dressing: Node3D = load("res://scenes/perimeter_dressing.tscn").instantiate()
	add_child(perimeter_dressing)
	var natural_landmarks: Node3D = load("res://scenes/natural_landmarks.tscn").instantiate()
	# Preview galleries bring their own camera, floor and input controller.
	# Keep editor reference instances out of the playable world.
	for preview in natural_landmarks.get_children():
		if preview.scene_file_path in ["res://scenes/natural_gallery.tscn","res://scenes/prop_gallery.tscn"]:
			preview.free()
	add_child(natural_landmarks)
	# Clear only the new village area at runtime. Preserve the saved forest layout.
	for prop in natural_landmarks.get_children():
		if Rect2(-75,-20,41,50).has_point(Vector2(prop.position.x,prop.position.z)):
			prop.hide()
			if prop is CollisionObject3D:
				prop.collision_layer=0
	var village: Node3D=load("res://scenes/village_layout.tscn").instantiate()
	add_child(village)
	lamp(Vector3(-35,0,22.8),Color("bc9463"))
	lamp(Vector3(-46,0,18.3),Color("bc9463"))
	var village_nature:=Node3D.new()
	village_nature.set_script(load("res://scripts/runtime/village_nature.gd"))
	village_nature.position=Vector3(-46,0,0)
	add_child(village_nature)
	var workshop_dressing: Node3D=load("res://scenes/workshop_dressing.tscn").instantiate()
	add_child(workshop_dressing)
	# Editor galleries may be placed in dressing scenes; captions stay out of play.
	for lettering in find_children("*","Label3D",true,false):
		lettering.free()
	var nature := Node3D.new()
	nature.set_script(load("res://scripts/runtime/nature_dressing.gd"))
	nature.dressing = checkpoint_props
	nature.additional_dressing = [perimeter_dressing,natural_landmarks,workshop_dressing]
	add_child(nature)
	building(Vector3(10, 0, 11), Vector2(7, 6), false)
	building(Vector3(-9, 0, -31), Vector2(12, 12), true)
	for z in [-20, -12, -4]:
		var container := box(Vector3(16, 1.4, z), Vector3(5, 2.8, 6), rust)
		container.rotation.y = 0.04 * z
		for n in range(7):
			box(Vector3(0, 0, -2.8 + n * 0.9), Vector3(5.08, 2.6, 0.08), dark, false, container)
	for z in [21, 7, -9, -23, -39]:
		lamp(Vector3(-4.5, 0, z))
	for i in range(20):
		var at := Vector3(rng.randf_range(-28, 28), 0.18, rng.randf_range(-48, 28))
		if absf(at.x) > 5:
			var debris := box(at, Vector3(rng.randf_range(0.25, 0.8), 0.35, rng.randf_range(0.2, 0.8)), concrete)
			debris.rotation.y = rng.randf_range(0, TAU)
	# A collapsed barrier leaves a walkable gap along the road.
	for x in [-10, -6, 6, 10]:
		box(Vector3(x, 0.65, -3), Vector3(3.5, 1.3, 0.9), concrete)
		box(Vector3(x, 1.32, -3), Vector3(3.45, 0.04, 0.85), material(Color("a29b54")), false)
	# Water in the service yard is visual only; the solid ground stays beneath it.
	var water := material(Color("334b49"), 0.08)
	box(Vector3(-18, 0.035, -10), Vector3(11, 0.03, 13), water, false)
	# Tower and elevated tank create landmarks above the fog.
	for x in [19, 25]:
		for z in [-41, -35]:
			box(Vector3(x, 4.5, z), Vector3(0.4, 9, 0.4), rust)
	box(Vector3(22, 9, -38), Vector3(7, 0.3, 7), dark)
	cylinder(Vector3(22, 11, -38), 3.5, 3.5, 4, rust)
	box(Vector3(22, 14.5, -38), Vector3(0.1, 4, 0.1), dark, false)
	lamp(Vector3(24, 0, -30))
	make_anomaly(Vector3(2.8, 0.15, -10), 2.2)
	make_anomaly(Vector3(-2.5, 0.15, -20), 1.9)
	make_anomaly(Vector3(9, 0.15, -33), 2.5)
	box(Vector3(-9, 0.6, -33), Vector3(2.5, 1.2, 1.4), dark)
	sample = StaticBody3D.new()
	sample.position = Vector3(-9, 1.65, -33)
	sample.set_meta("interaction", "sample")
	add_child(sample)
	var orb := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.19
	sphere.height = 0.38
	orb.mesh = sphere
	orb.material_override = material(Color("85f2c6"), 0.2, 4)
	sample.add_child(orb)
	var collider := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.35
	collider.shape = shape
	sample.add_child(collider)
	var glow := OmniLight3D.new()
	glow.light_color = Color("72e8ba")
	glow.light_energy = 1.5
	glow.omni_range = 5
	sample.add_child(glow)
	supplies = box(Vector3(-10, 0.9485, 10), Vector3(0.5, 0.28, 0.4), material(Color("b5ac8a"))) as StaticBody3D
	supplies.set_meta("interaction", "supplies")
	# The medical marker is geometry, not attached lettering.
	box(Vector3(0,0.01,0.205),Vector3(0.03,0.12,0.009),material(Color("a74635")),false,supplies)
	box(Vector3(0,0.01,0.205),Vector3(0.12,0.03,0.01),material(Color("a74635")),false,supplies)
	gate = box(Vector3(3.9, 1, 28), Vector3(0.65, 1.5, 0.6), dark) as StaticBody3D
	gate.set_meta("interaction", "gate")
	box(Vector3(3.9, 1.25, 28.32), Vector3(0.42, 0.35, 0.03), material(Color("9ccd91"), 0.7, 2), false)
	lamp(Vector3(5, 0, 28), Color("9bd3a0"))
	var cache: StaticBody3D=load("res://scenes/loot/supply_cache.tscn").instantiate()
	cache.position=Vector3(-6.3,0,21.5)
	cache.rotation.y=0.15
	add_child(cache)
	var village_cache: StaticBody3D=load("res://scenes/loot/supply_cache.tscn").instantiate()
	village_cache.contents={"bandage":1,"food_tin":2,"batteries":1}
	village_cache.position=Vector3(-48.1,0.18,10.0)
	village_cache.rotation.y=-0.35
	add_child(village_cache)
	var yard_cache: StaticBody3D=load("res://scenes/loot/supply_cache.tscn").instantiate()
	yard_cache.contents={"bandage":0,"food_tin":1,"batteries":2}
	yard_cache.position=Vector3(-53,0,15)
	yard_cache.rotation.y=0.4
	add_child(yard_cache)

func building(at: Vector3, dimensions: Vector2, research: bool) -> void:
	var width := dimensions.x
	var depth := dimensions.y
	box(at + Vector3(0, 0.07, 0), Vector3(width, 0.14, depth), concrete)
	# The character has no automatic step-up: bridge the raised floor lip.
	var approach := box(at+Vector3(0,0.02,depth/2+0.7),Vector3(1.9,0.12,1.8),concrete)
	approach.name = "WalkableEntranceRamp"
	approach.rotation.x = 0.08
	box(at + Vector3(-width / 2, 1.8, 0), Vector3(0.35, 3.6, depth), concrete)
	box(at + Vector3(width / 2, 1.8, 0), Vector3(0.35, 3.6, depth), concrete)
	box(at + Vector3(0, 1.8, -depth / 2), Vector3(width, 3.6, 0.35), concrete)
	var side_width := (width - 2.2) / 2
	for side in [-1, 1]:
		box(at + Vector3(side * (1.1 + side_width / 2), 1.8, depth / 2), Vector3(side_width, 3.6, 0.35), concrete)
	box(at + Vector3(0, 3.25, depth / 2), Vector3(2.2, 0.7, 0.35), concrete)
	box(at + Vector3(0, 3.65, 0), Vector3(width + 0.6, 0.25, depth + 0.6), dark)
	for side in [-1, 1]:
		box(at + Vector3(side * width * 0.32, 2, depth / 2 + 0.2), Vector3(width * 0.16, 0.8, 0.08), material(Color("a29460"), 0.8, 0.7), false)
	if research:
		box(at + Vector3(-3.5, 1, -3), Vector3(1.2, 2, 1), rust)
		box(at + Vector3(4, 0.9, 2), Vector3(1.5, 1.8, 1.5), dark)
		lamp(at + Vector3(3.6, 0, -3.5))
	else:
		box(at + Vector3(2, 0.7, -1), Vector3(1.5, 1.4, 1.5), rust)

func make_anomaly(at: Vector3, radius: float) -> void:
	var root := Node3D.new()
	root.position = at
	root.set_meta("radius", radius)
	root.add_to_group("world_anomalies",true)
	add_child(root)
	anomalies.append(root)
	var glow_mat := material(Color("71b8ae"), 0.4, 0.9)
	for i in range(3):
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = radius * (0.65 + i * 0.13)
		torus.outer_radius = torus.inner_radius + 0.035
		torus.rings = 32
		torus.ring_segments = 6
		ring.mesh = torus
		ring.material_override = glow_mat
		ring.position.y = i * 0.22
		root.add_child(ring)
	for i in range(9):
		var mote := box(Vector3(rng.randf_range(-radius, radius), rng.randf_range(0.4, 2.2), rng.randf_range(-radius, radius)), Vector3(0.035, 0.2, 0.035), glow_mat, false, root)
		mote.rotation.z = rng.randf_range(-0.6, 0.6)
	var light := OmniLight3D.new()
	light.position.y = 1
	light.light_color = Color("6fbcb0")
	light.light_energy = 1.2
	light.omni_range = radius * 3
	root.add_child(light)

func build_sound() -> void:
	ambience = AudioStreamPlayer.new()
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_end = 22050 * 8
	var data := PackedByteArray()
	data.resize(wav.loop_end * 2)
	var smooth := 0.0
	var audio_rng := RandomNumberGenerator.new()
	audio_rng.seed = 45
	for i in range(wav.loop_end):
		var time := float(i) / 22050
		smooth = smooth * 0.96 + audio_rng.randf_range(-1, 1) * 0.04
		var wind := smooth * (0.65 + 0.25 * sin(time * TAU / 8))
		var drone := sin(time * TAU * 43) * 0.05 + sin(time * TAU * 44.5) * 0.035
		# Fade the loop seam to avoid clicks.
		var fade := minf(1.0, minf(time * 8, (8 - time) * 8))
		data.encode_s16(i * 2, int((wind + drone) * fade * 18000))
	wav.data = data
	ambience.stream = wav
	ambience.volume_db = -17
	ambience.bus = "Wind"
	add_child(ambience)
	ambience.play()

func resume_game() -> void:
	if finished or player.health <= 0:
		get_tree().reload_current_scene()
		return
	started = true
	if inventory_open:close_inventory(false)
	player.set_view_direction(-player.camera.global_basis.z)
	player.active = true
	hud.overlay.hide()
	hud.restore_menu_layout()
	if not smoke_test:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	show_message("Search the supply box by the checkpoint lamp. Station 04 is north.", 7)

func open_loot(container: StaticBody3D) -> void:
	if inventory_open:close_inventory(false)
	open_container=container
	container.set_open(true)
	player.active=false
	player.velocity=Vector3.ZERO
	hud.interaction.hide()
	hud.message.hide()
	hud.show_loot(container.contents)
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE

func take_loot() -> void:
	if not is_instance_valid(open_container):
		return
	var taken: Dictionary=open_container.take_all()
	for id in taken:
		inventory[id] = inventory.get(id,0)+taken[id]
	hud.show_loot(open_container.contents)
	if not taken.is_empty():
		show_message("Supplies collected. Press H to use a bandage.",5)

func close_loot() -> void:
	if not is_instance_valid(open_container):
		return
	open_container.set_open(false)
	open_container=null
	hud.loot_panel.hide()
	hud.interaction.show()
	hud.message.show()
	player.active=true
	if not smoke_test:
		Input.mouse_mode=Input.MOUSE_MODE_CAPTURED

func use_bandage() -> void:
	if inventory.bandage<=0:
		show_message("No bandages in your pack.")
	elif player.health>=100:
		show_message("Condition is already full.")
	else:
		inventory.bandage-=1
		after_consumed("bandage")
		player.health=minf(100,player.health+35)
		show_message("Bandage used. Condition restored.")

func use_food() -> void:
	if inventory.food_tin<=0:
		show_message("No food in your pack.")
	elif player.stamina>=99.9:
		show_message("Your stamina is already full.")
	else:
		inventory.food_tin-=1
		after_consumed("food_tin")
		player.stamina=minf(100,player.stamina+45)
		player.sprint_exhausted=false
		show_message("Food eaten. Stamina restored.")

func reload_battery() -> void:
	if inventory.batteries<=0:
		show_message("No spare batteries in your pack.")
	elif player.battery_charge>=99.9:
		show_message("Flashlight battery is already full.")
	else:
		inventory.batteries-=1
		after_consumed("batteries")
		player.battery_charge=minf(100,player.battery_charge+60)
		show_message("Flashlight battery replaced. Press F to switch it on.")

func pause_game() -> void:
	if inventory_open:close_inventory(false)
	player.active = false
	player.velocity = Vector3.ZERO
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	hud.menu_title.text = "EXPEDITION PAUSED"
	hud.menu_title.add_theme_font_size_override("font_size", 48)
	hud.menu_body.text = "WASD — Move    /    Mouse — Look\nSHIFT — Sprint    /    SPACE — Jump    /    CTRL — Crouch\nF — Torch    /    R — Battery    /    G — Food    /    H — Bandage\nE — Search    /    TAB — Inventory    /    Q — Use held item\n\nRecover the sample at Station 04, then use the entry terminal.\nThe village creature hears running. Crouching is quieter."
	hud.start_button.text = "RESUME EXPEDITION"
	hud.overlay.show()

func _on_window_focus_exited() -> void:
	if not smoke_test and is_instance_valid(player) and player.active:
		pause_game()

func show_message(words: String, duration: float = 4) -> void:
	hud.message.text = words
	message_time = duration
	if inventory_open:inventory_feedback=words

func open_inventory() -> bool:
	if not started or finished or player.health<=0:return false
	if is_instance_valid(open_container):close_loot()
	inventory_open=true
	player.active=false
	player.velocity=Vector3.ZERO
	hud.interaction.hide();hud.message.hide()
	hud.inventory_screen.open_pack()
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	return true

func close_inventory(resume: bool=true) -> void:
	inventory_open=false
	hud.inventory_screen.close_pack()
	hud.interaction.show();hud.message.show()
	player.active=resume and started and not finished and player.health>0
	if player.active and not smoke_test:Input.mouse_mode=Input.MOUSE_MODE_CAPTURED

func equip_inventory_item(id: String) -> bool:
	if not id.is_empty() and (not Items.ITEMS.has(id) or inventory.get(id,0)<=0):
		inventory_feedback="That item is not in your pack."
		return false
	var profile: HandGripProfile=Items.grip(id) if not id.is_empty() else null
	if not player.body_model.equip_item(profile):return false
	equipped_item_id=id
	if id!="detector":detector_enabled=false
	inventory_feedback="Hands empty." if id.is_empty() else "Carrying "+Items.entry(id).get("name", "item")+"."
	return true

func after_consumed(id: String) -> void:
	if inventory.get(id,0)<=0 and equipped_item_id==id:
		equip_inventory_item("flashlight" if inventory.get("flashlight",0)>0 else "")

func use_inventory_item(id: String) -> bool:
	if not Items.ITEMS.has(id) or inventory.get(id,0)<=0:
		show_message("No item available in your pack.")
		return false
	var before: int=inventory.get(id,0)
	match id:
		"bandage":use_bandage()
		"food_tin":use_food()
		"batteries":reload_battery()
		"water_bottle":
			if player.stamina>=99.9:show_message("Your stamina is already full.")
			else:
				inventory[id]-=1;player.stamina=minf(100,player.stamina+30);player.sprint_exhausted=false
				show_message("Water consumed. Stamina restored.")
		"antiseptic":
			if player.health>=100:show_message("Condition is already full.")
			else:
				inventory[id]-=1;player.health=minf(100,player.health+20)
				show_message("Antiseptic applied. Condition restored.")
		"flashlight":
			if not player.body_model.can_use_flashlight():
				show_message("Carry the flashlight to switch its beam.");return false
			var toggled: bool=player.toggle_flashlight()
			show_message(("Flashlight on." if player.torch.visible else "Flashlight off.") if toggled else "The flashlight needs batteries.")
			return toggled
		"detector":
			if equipped_item_id!=id:show_message("Carry the anomaly meter to activate its sensor.");return false
			detector_enabled=not detector_enabled
			show_message(anomaly_readout() if detector_enabled else "Anomaly meter switched off.")
			return true
		"field_radio":
			var beacon: Node3D=gate if has_sample else sample
			if areas != null and areas.current == "relay": beacon = areas.inbound if areas.relay_recovered else areas.record
			var offset: Vector3=beacon.global_position-player.global_position
			var heading := fposmod(rad_to_deg(atan2(offset.x,-offset.z)),360)
			show_message("Receiver: %s bearing %03d°, range %d m."%["North Relay exit" if areas != null and areas.current == "relay" and areas.relay_recovered else ("Relay recorder" if areas != null and areas.current == "relay" else ("Entry gate" if has_sample else "Station 04")),heading,Vector2(offset.x,offset.z).length()],7)
			return true
	after_consumed(id)
	return inventory.get(id,0)<before

func anomaly_readout() -> String:
	var nearest := INF
	for anomaly in anomalies:
		nearest=minf(nearest,player.global_position.distance_to(anomaly.global_position))
	return "SENSOR  /  %02d m to nearest anomaly"%nearest if nearest<40 else "SENSOR  /  No anomaly within 40 m"

func run_inventory_review() -> void:
	resume_game()
	open_inventory()
	DirAccess.make_dir_recursive_absolute("res://reviews/inventory")
	for id in Items.ORDER:
		hud.inventory_screen.select_item(id)
		await get_tree().create_timer(1.1).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://reviews/inventory/"+id+".png")
	print("INVENTORY_SCREEN_REVIEW_CAPTURED")
	hud.inventory_screen.close_pack()
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_tree().quit()

func start_inventory_test() -> void:
	resume_game()
	open_inventory()

func _input(event: InputEvent) -> void:
	if not is_instance_valid(player):return
	if not (event is InputEventKey and event.pressed and not event.echo):return
	if inventory_open and (event.is_action_pressed("inventory") or event.is_action_pressed("pause")):
		close_inventory();get_viewport().set_input_as_handled()
	elif event.is_action_pressed("inventory") and (player.active or is_instance_valid(open_container)):
		open_inventory();get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if inventory_open:return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.is_action_pressed("pause") and hud.audio_panel.visible:
			hud.audio_panel.hide()
			get_viewport().set_input_as_handled()
			return
		if is_instance_valid(open_container):
			if event.is_action_pressed("pause") or event.is_action_pressed("interact"):
				close_loot()
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed("pause") and started and not finished and player.health > 0:
			if player.active:
				pause_game()
			else:
				resume_game()
		elif event.is_action_pressed("interact") and player.active:
			var target := get_target()
			if target:
				interact_with(target)
		elif event.is_action_pressed("use_bandage") and player.active:
			use_bandage()
		elif event.is_action_pressed("use_food") and player.active:
			use_food()
		elif event.is_action_pressed("reload_battery") and player.active:
			reload_battery()
		elif event.is_action_pressed("use_held_item") and player.active:
			use_inventory_item(equipped_item_id)

func get_target() -> Object:
	var start: Vector3 = player.camera.global_position
	var end: Vector3 = start - player.camera.global_basis.z * 3.5
	var query := PhysicsRayQueryParameters3D.create(start, end)
	query.exclude = [player.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty() and hit.collider.has_meta("interaction"):
		return hit.collider
	return null

func interact_with(target: Object) -> void:
	match target.get_meta("interaction", ""):
		"area_link":
			if areas != null: areas.travel(target)
		"relay_record":
			if areas != null: areas.recover()
		"station_generator":
			if crossroads != null: crossroads.interact()
		"crossroads_door":
			if target.has_method("interact"):
				target.interact(player)
		"loot_container":
			open_loot(target)
		"sample":
			has_sample = true
			sample.hide()
			sample.collision_layer = 0
			sample.get_child(sample.get_child_count() - 1).visible = false
			show_message("Sample secured. Return south to the entry gate terminal.", 7)
		"supplies":
			if player.health < 100:
				player.health = minf(100, player.health + 45)
				supplies.hide()
				supplies.collision_layer = 0
				show_message("Medical supplies used. Condition restored.")
			else:
				show_message("Medical supplies. Your condition is already good.")
		"gate":
			if crossroads != null and crossroads.report_at_gate(): return
			if areas != null and areas.report(): return
			if has_sample:
				finish_expedition(true)
			else:
				show_message("Extraction locked. Recover the research sample first.")

func finish_expedition(success: bool) -> void:
	if inventory_open:close_inventory(false)
	finished = success
	player.active = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	hud.menu_title.text = "SAMPLE RECOVERED" if success else "SIGNAL LOST"
	hud.menu_title.add_theme_font_size_override("font_size", 48)
	hud.menu_body.text = ("You made it back from Station 04.\n\nExpedition duration: %d minutes, %02d seconds\nCondition on return: %d%%\n\nThe perimeter still has secrets.\nThis is our starting point for building the larger game." % [int(elapsed / 60), int(elapsed) % 60, int(player.health)]) if success else "You were lost inside the perimeter.\n\nGive the blue-green rings more space.\nThe road and amber lamps lead toward Station 04.\n\nMedical supplies are in the left checkpoint hut."
	hud.start_button.text = "START A NEW EXPEDITION"
	hud.overlay.show()

func _process(delta: float) -> void:
	if not is_instance_valid(player) or not is_instance_valid(hud):
		return
	var time := float(Time.get_ticks_msec()) / 1000
	for anomaly in anomalies:
		anomaly.rotation.y = time * 0.18
		for i in range(3):
			anomaly.get_child(i).position.y = 0.12 + i * 0.22 + sin(time * 1.7 + i) * 0.12
	if not has_sample:
		sample.get_child(0).position.y = sin(time * 2) * 0.08
	if not player.active:
		return
	elapsed += delta
	message_time -= delta
	if message_time <= 0:
		hud.message.text = ""
	var target := get_target()
	hud.interaction.text = ""
	if target:
		var kind: String = target.get_meta("interaction")
		var hints := {"area_link": "[ E ]  TRAVEL THROUGH SERVICE PASSAGE", "relay_record": "[ E ]  RECOVER RELAY RECORDING", "sample": "[ E ]  SECURE RESEARCH SAMPLE", "supplies": "[ E ]  USE MEDICAL SUPPLIES", "gate": "[ E ]  REQUEST EXTRACTION", "loot_container": "[ E ]  SEARCH SUPPLY BOX"}
		hud.interaction.text = hints.get(kind, "")
		if kind == "crossroads_door":
			hud.interaction.text = "[ E ]  CLOSE DOOR" if target.opened else "[ E ]  OPEN DOOR"
		if kind == "station_generator":
			hud.interaction.text = "[ E ]  START GENERATOR / RETRIEVE DIAGNOSTIC"
	hazard_strength = 0
	for anomaly in anomalies:
		var distance := Vector2(player.position.x - anomaly.position.x, player.position.z - anomaly.position.z).length()
		var radius: float = anomaly.get_meta("radius")
		if distance < radius + 1.2:
			hazard_strength = maxf(hazard_strength, 1.0 - distance / (radius + 1.2))
	if hazard_strength > 0.08:
		player.health = maxf(0, player.health - hazard_strength * 28 * delta)
		hud.interaction.text = "UNSTABLE FIELD — MOVE AWAY"
	if player.health <= 0:
		finish_expedition(false)

func run_smoke_test() -> void:
	# Exercise actual physics, interaction, pause, hazard, and completion paths.
	await get_tree().physics_frame
	await get_tree().physics_frame
	resume_game()
	var before: Vector3 = player.position
	Input.action_press("move_forward")
	for i in range(50):
		await get_tree().physics_frame
	Input.action_release("move_forward")
	assert(player.position.z < before.z - 1, "Forward movement failed")
	assert(player.position.y > -0.2, "Ground collision failed")
	player.position = Vector3(-10, 0.1, 16)
	player.velocity = Vector3.ZERO
	player.rotation = Vector3.ZERO
	Input.action_press("move_forward")
	for i in range(70):
		await get_tree().physics_frame
	Input.action_release("move_forward")
	assert(player.position.z < 13.7, "House door or threshold blocks walking entry")
	player.position = Vector3(-12, 0.2, 15)
	player.velocity = Vector3.ZERO
	Input.action_press("move_forward")
	for i in range(35):
		await get_tree().physics_frame
	Input.action_release("move_forward")
	assert(player.position.z > 14.3, "House masonry collision failed")
	pause_game()
	assert(not player.active and hud.overlay.visible, "Pause failed")
	resume_game()
	player.position = anomalies[0].position + Vector3(0, 0.05, 0)
	for i in range(20):
		await get_tree().physics_frame
	assert(player.health < 100, "Anomaly damage failed")
	player.position = Vector3(-10, 0.2, 11.8)
	player.camera.look_at(supplies.global_position)
	await get_tree().physics_frame
	assert(get_target() == supplies, "Medical supplies ray interaction failed")
	interact_with(get_target())
	assert(player.health == 100, "Healing failed")
	player.position = Vector3(-9, 0.2, -30.5)
	player.rotation = Vector3.ZERO
	player.camera.rotation = Vector3.ZERO
	player.camera.look_at(sample.global_position)
	await get_tree().physics_frame
	assert(get_target() == sample, "Sample ray interaction failed")
	interact_with(get_target())
	assert(has_sample and not sample.visible, "Sample collection failed")
	player.position = Vector3(3.9, 0.2, 25.7)
	player.camera.look_at(gate.global_position)
	await get_tree().physics_frame
	assert(get_target() == gate, "Extraction ray interaction failed")
	interact_with(get_target())
	assert(finished and not player.active, "Extraction failed")
	print("ASHFALL_SMOKE_TEST_PASS: movement, ground, house entry, house wall collision, pause, hazard, healing, sample, extraction")
	# Save a view from the entry to visually check the real rendered scene.
	finished = false
	has_sample = false
	player.health = 100
	player.position = Vector3(0, 0.1, 25)
	player.rotation = Vector3.ZERO
	player.camera.rotation = Vector3.ZERO
	hud.overlay.hide()
	hud.restore_menu_layout()
	hud.interaction.text = ""
	show_message("Station 04 is north along the road. Recover the sample.", 6)
	await get_tree().physics_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://concept-art/archive/preview.png")
	get_tree().quit()

func run_house_review() -> void:
	hud.hide()
	player.active = false
	player.torch.visible = false
	player.camera.fov = 58
	var views := [
		["house-exterior", Vector3(-3, 2.3, 16.2), Vector3(-10, 1.9, 11)],
		["house-detail", Vector3(-8.2, 1.8, 17.5), Vector3(-11.6, 1.8, 14)],
		["house-interior", Vector3(-9.8, 1.8, 12.7), Vector3(-10.5, 1.2, 9.2)],
		["research-approach",Vector3(0,2.2,-19),Vector3(-9,1.4,-30)],
		["service-yard",Vector3(6.5,2.3,0),Vector3(17,1.4,-10)],
		["wetland-edge",Vector3(-8,2,0),Vector3(-18,0.8,-10)],
		["water-tower",Vector3(10,2.4,-25),Vector3(22,5,-38)]
	]
	DirAccess.make_dir_recursive_absolute("res://reviews")
	for view in views:
		player.torch.visible = view[0] == "house-interior"
		player.camera.global_position = view[1]
		player.camera.look_at(view[2])
		for i in range(16):
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var suffix := "-before" if "--review-before" in OS.get_cmdline_user_args() else ""
		get_viewport().get_texture().get_image().save_png("res://reviews/" + view[0] + suffix + ".png")
	print("HOUSE_REVIEW_CAPTURED")
	get_tree().quit()

