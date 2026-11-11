extends Node3D
## Areas remain resident for this slice: inventory, loot, doors and objectives
## retain their actual state. Add another packed area and named link to extend.
var game: Node3D
var current := "perimeter"
var relay_recovered := false
var relay_reported := false
var visited := {}
var encounter_rolls := {}
var random := RandomNumberGenerator.new()
var record: StaticBody3D
var relay_threat: CharacterBody3D
var outbound: StaticBody3D
var inbound: StaticBody3D

func setup(world: Node3D) -> void:
	game = world
	random.randomize()
	var area = load("res://scenes/relay_yard.tscn").instantiate()
	add_child(area)
	record = area.get_node("Recorder")
	record.set_meta("interaction", "relay_record")
	outbound = make_link(Vector3(8,0,24), "relay", Vector3(300,0.15,19), true)
	inbound = make_link(Vector3(300,0,22), "perimeter", Vector3(8,0.15,21), false)
	# Reuse authored yard assets; leave both flanks and the return lane open.
	for entry in [
		["props/shipping_crate", Vector3(-8,0,-9)],
		["props/cable_spool", Vector3(10,0,-7)],
		["props/rusted_drum", Vector3(11,0,-10)],
		["props/wooden_pallet", Vector3(13,0,-12)],
		["props/field_cot", Vector3(-8,0,-13)],
		["props/jerrycan", Vector3(-7,0,-13)],
		["nature/mossy_boulder", Vector3(-16,0,7)],
		["nature/mossy_boulder", Vector3(16,0,-5)]]:
		var prop = load("res://scenes/" + entry[0] + ".tscn").instantiate()
		prop.position = entry[1]
		area.add_child(prop)
	for x in [-19,19]:
		for z in range(-21,22,6):
			var fence = load("res://scenes/props/damaged_fence.tscn").instantiate()
			fence.position = Vector3(x,0,z)
			fence.rotation.y = PI/2
			area.add_child(fence)
	for z in [-22,23]:
		for x in range(-16,18,4):
			var fence = load("res://scenes/props/damaged_fence.tscn").instantiate()
			fence.position = Vector3(x,0,z)
			area.add_child(fence)
	game.lamp(Vector3(302,0,-11))
	var dressing_rng := RandomNumberGenerator.new()
	dressing_rng.seed = 914
	for i in 80:
		var at := Vector3(dressing_rng.randf_range(-20,20),0,dressing_rng.randf_range(-22,22))
		# Leave cottage, two flank routes and both interaction approaches clear.
		if absf(at.x) < 8 or absf(absf(at.x)-12) < 2 or absf(at.x-15) < 1.5: continue
		var tuft = load("res://scenes/extra_dressing/dry_grass_tuft.tscn").instantiate()
		tuft.position = at
		tuft.rotation.y = dressing_rng.randf_range(-PI,PI)
		area.add_child(tuft)
	for side in [-1,1]:
		for z in range(-22,25,7):
			var tree = load("res://scenes/nature/forest_pine.tscn").instantiate()
			tree.position = Vector3(side*23,0,z)
			area.add_child(tree)
	var mist := FogVolume.new()
	mist.position = Vector3(300,0.4,-8)
	mist.size = Vector3(38,1.2,18)
	var fog := FogMaterial.new()
	fog.density = 0.025
	fog.albedo = Color("8c9b9a")
	fog.edge_fade = 0.5
	mist.material = fog
	add_child(mist)
	game.make_anomaly(Vector3(294,0,-1), 2.0)
	var cache = StaticBody3D.new()
	cache.set_script(load("res://scripts/runtime/loot_container.gd"))
	cache.contents = {"bandage": 1, "batteries": 1}
	cache.position = Vector3(313,0.1,-12)
	add_child(cache)
	relay_threat = CharacterBody3D.new()
	relay_threat.set_script(load("res://scripts/runtime/village_stalker.gd"))
	relay_threat.game = game
	relay_threat.area_id = "relay"
	relay_threat.position = Vector3(288,0.1,-14)
	relay_threat.points = [Vector3(288,0,-14),Vector3(288,0,6),Vector3(310,0,6),Vector3(312,0,-14)]
	add_child(relay_threat)
	roll_encounter("relay", relay_threat, 0.7)
	roll_encounter("perimeter", game.get_node("VillageStalker"), 0.8)

func roll_encounter(id: String, creature: Node3D, chance: float) -> void:
	# Resolve before the player enters; never reroll or materialize in view.
	var present := random.randf() < chance
	encounter_rolls[id] = present
	creature.encounter_present = present
	creature.visible = present
	creature.collision_layer = 1 if present else 0

func make_link(at: Vector3, destination: String, arrival: Vector3, locked: bool) -> StaticBody3D:
	var link := StaticBody3D.new()
	link.set_script(load("res://scripts/runtime/area_link.gd"))
	link.destination = destination
	link.arrival = arrival
	link.requires_diagnostic = locked
	link.position = at
	if destination == "perimeter": link.rotation.y = PI
	add_child(link)
	var model = load("res://scenes/props/electrical_cabinet.tscn").instantiate()
	if model is CollisionObject3D: model.collision_layer = 0
	link.add_child(model)
	# A single interaction collider encloses the existing cabinet asset.
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1,1.8,0.65)
	collision.shape = shape
	collision.position.y = 0.9
	link.add_child(collision)
	for body in model.find_children("*", "StaticBody3D", true, false):
		body.collision_layer = 0
	# Passage direction and lock state are shown by the field HUD on interaction.
	var barrier = load("res://scenes/props/damaged_fence.tscn").instantiate()
	barrier.position = Vector3(0,0,-0.8)
	link.add_child(barrier)
	game.lamp(at + Vector3(1.8,0,0))
	return link

func travel(link: StaticBody3D) -> bool:
	if link.requires_diagnostic and (game.crossroads == null or game.crossroads.stage not in ["return", "complete"]):
		game.show_message("Service passage has no power. Start Crossroads' generator and retrieve its diagnostic.", 7)
		return false
	current = link.destination
	visited[current] = true
	game.player.position = link.arrival
	game.player.velocity = Vector3.ZERO
	game.player.noise_radius = 0
	game.player.rotation.y = link.heading
	game.hazard_strength = 0
	game.show_message("North Relay: recover the recorder at the rear workbench. The lane is unstable; go around either side." if current == "relay" else "Crossroads. Your pack and explored locations are unchanged.", 8)
	return true

func recover() -> void:
	if relay_recovered: return
	relay_recovered = true
	record.hide()
	record.collision_layer = 0
	game.show_message("Recorder: 'We shut the relay down. It kept answering in our voices.' Return this to the entry gate.", 10)

func report() -> bool:
	if not relay_recovered or relay_reported: return false
	relay_reported = true
	game.inventory.bandage += 1
	game.show_message("North Relay recording secured. One bandage issued. Station 04's research sample is still needed for extraction.", 8)
	return true

func objective_text() -> String:
	if relay_reported: return "NORTH RELAY / Recording delivered"
	if relay_recovered: return "NORTH RELAY / Return recording to entry gate"
	if current == "relay": return "NORTH RELAY / Recorder behind the cottage; supplies in east yard"
	if game.crossroads != null and game.crossroads.stage in ["return", "complete"]: return "NORTH RELAY / Service passage east of entry gate is powered"
	return ""
