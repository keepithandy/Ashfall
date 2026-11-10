extends Node3D
## Deterministic dressing and an open-ended quarantine exploration loop.
var lamps: Array[OmniLight3D] = []
var elapsed := 0.0

func prop(kind: String, at: Vector3, yaw := 0.0, folder := "props") -> Node3D:
	var scene := load("res://scenes/" + folder + "/" + kind + ".tscn") as PackedScene
	var item := scene.instantiate() as Node3D
	add_child(item)
	item.position = at
	item.rotation.y = yaw
	return item

func block(at: Vector3, size: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	add_child(body)
	body.position = at
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.94
	mesh.material_override = mat
	body.add_child(mesh)
	var hit := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	hit.shape = shape
	body.add_child(hit)

func sign_text(words: String, at: Vector3) -> void:
	var label := Label3D.new()
	add_child(label)
	label.position = at
	label.text = words
	label.font_size = 44
	label.pixel_size = 0.008
	label.modulate = Color("b8b69b")

func lamp(at: Vector3, color: Color) -> void:
	var light := OmniLight3D.new()
	add_child(light)
	var fixture := (load("res://assets/station_lamps/street_lamp_1980s.glb") as PackedScene).instantiate() as Node3D
	add_child(fixture)
	var fixture_scale := 0.55 if at.z < -45 and absf(at.x) < 12 else 1.0
	fixture.scale = Vector3.ONE * fixture_scale
	fixture.position = Vector3(at.x - 1.4 * fixture_scale, 0, at.z)
	light.position = fixture.position + Vector3(1.4, 4.85, 0) * fixture_scale
	var body := StaticBody3D.new()
	fixture.add_child(body)
	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.11
	shape.height = 4.8
	collision.shape = shape
	collision.position.y = 2.4
	body.add_child(collision)
	light.light_color = color
	light.light_energy = 1.5
	light.omni_range = 9.0
	lamps.append(light)

func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4104
	# North ward: two entrances, central passage, side bays, supply reward.
	var concrete := Color("303936")
	block(Vector3(0, 1.8, -61), Vector3(24, 3.6, 0.35), concrete)
	for x in [-12.0, 12.0]:
		block(Vector3(x, 1.8, -53), Vector3(0.35, 3.6, 16), concrete)
	for x in [-8.0, 8.0]:
		block(Vector3(x, 1.8, -45), Vector3(8, 3.6, 0.35), concrete)
		block(Vector3(x, 3.7, -53), Vector3(8, 0.2, 16), concrete)
		for z in [-49.0, -55.0]:
			block(Vector3(x, 1.4, z), Vector3(6, 2.8, 0.15), concrete)
	for x in [-9.0, 9.0]:
		for z in [-47.0, -52.0, -58.0]:
			prop("field_cot", Vector3(x, 0, z), PI / 2)
			prop("metal_bucket", Vector3(x - 1, 0, z + 0.6))
			prop("worn_mattress", Vector3(x + 0.3, 0.6, z), PI / 2)
	prop("shelving_unit", Vector3(-10, 0, -60))
	prop("filing_cabinet", Vector3(10, 0, -60))
	prop("desk_radio", Vector3(9, 0.8, -58))
	prop("supply_cache", Vector3(-8, 0, -59), 0, "loot")
	sign_text("ISOLATION WARD 04\nKEEP THE CENTRAL AISLE CLEAR", Vector3(0, 3.3, -45))
	sign_text("06:14 — ALL BEDS EMPTY\n06:15 — STILL HEARING THEM", Vector3(0, 2, -60.7))
	lamp(Vector3(-7, 2.8, -52), Color("ac3428"))
	lamp(Vector3(7, 2.8, -58), Color("76a99e"))
	# Follow the lit service trail east, then loop back to the station.
	for z in [-30.0, -39.0, -48.0, -57.0]:
		prop("damaged_fence", Vector3(18, 0, z), PI / 2)
		prop("rusted_drum", Vector3(23, 0, z), 0.4)
		prop("pipe_bundle", Vector3(27, 0, z), 0.2)
		lamp(Vector3(20, 2.4, z), Color("b48143"))
	prop("portable_generator", Vector3(21, 0, -60))
	prop("supply_cache", Vector3(25, 0, -59), 0, "loot")
	sign_text("WARD ACCESS  <\nRETURN TO STATION  v", Vector3(23, 2, -61))
	# Abandoned evacuation queues and possessions near the arrival gate.
	for x in [-8.0, 8.0]:
		for z in [14.0, 18.0, 23.0]:
			prop("wooden_bench", Vector3(x, 0, z), PI / 2)
			prop("equipment_case", Vector3(x + 1, 0, z + 0.8), 0.4)
		prop("sandbag_stack", Vector3(x, 0, 29))
	lamp(Vector3(-7, 3, 22), Color("ce9c58"))
	sign_text("EVACUATION SUSPENDED\nFOLLOW WARD LIGHTS NORTH", Vector3(0, 3, 18))
	# Concentrate clutter at edges, preserving the road and door approaches.
	for i in range(75):
		var side := -1.0 if i % 2 == 0 else 1.0
		var at := Vector3(side * rng.randf_range(5.5, 8.0), 0.03, rng.randf_range(-42, 12))
		prop("dry_grass_tuft", at, rng.randf_range(0, TAU), "extra_dressing")
	for i in range(32):
		var at := Vector3(rng.randf_range(-32, 32), 0, rng.randf_range(-74, -65))
		prop("bare_tree", at, rng.randf_range(0, TAU), "nature")
	for i in range(18):
		prop("rubble_pile", Vector3(rng.randf_range(30, 42), 0, rng.randf_range(-29, -24)), rng.randf_range(0, TAU))

func _process(delta: float) -> void:
	elapsed += delta
	for i in range(lamps.size()):
		var pulse := sin(elapsed * 1.8 + float(i) * 2.1)
		lamps[i].light_energy = 1.1 + pulse * 0.18
		if i == 0 and fmod(elapsed, 11.0) > 10.5:
			lamps[i].light_energy = 0.08

