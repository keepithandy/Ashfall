extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, text: String) -> void:
	print("PASS: " if ok else "FAIL: ",text)
	if not ok: failures += 1
func frames(n: int) -> void:
	for i in n: await physics_frame
func run() -> void:
	var game = load("res://scenes/ashfall_editable.tscn").instantiate()
	root.add_child(game)
	game.smoke_test = true
	game.resume_game()
	await frames(4)
	var areas = game.areas
	game.player.position = Vector3(8,0.1,26.5)
	game.player.velocity = Vector3.ZERO
	game.player.set_view_direction(areas.outbound.global_position + Vector3.UP - game.player.camera.global_position)
	await frames(3)
	check(game.get_target() == areas.outbound, "Outbound passage reachable by ordinary interaction ray")
	check(not areas.travel(areas.outbound), "Unpowered passage stays locked")
	game.crossroads.stage = "return"
	game.player.health = 63
	var pack: Dictionary = game.inventory.duplicate()
	var rolls: Dictionary = areas.encounter_rolls.duplicate()
	check(areas.travel(areas.outbound), "Diagnostic opens normal area link")
	await frames(8)
	check(game.player.is_on_floor(), "Arrival stands on solid ground")
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://reviews/survival-slice/relay-arrival.png")
	check(game.player.health == 63 and game.inventory == pack, "Travel preserves condition and pack")
	game.player.position = Vector3(300,0.1,19.5)
	game.player.set_view_direction(areas.inbound.global_position + Vector3.UP - game.player.camera.global_position)
	await frames(3)
	check(game.get_target() == areas.inbound, "Return passage reachable by ordinary interaction ray")
	var cache = areas.get_node("LootContainer")
	cache.take_all()
	# Traverse west flank with real movement input, then target the recorder.
	game.player.position = Vector3(288,0.15,17)
	game.player.rotation.y = 0
	areas.relay_threat.encounter_present = false
	Input.action_press("move_forward")
	await frames(480)
	Input.action_release("move_forward")
	check(game.player.position.z < -4, "West flank supports ordinary player traversal: " + str(game.player.position))
	game.player.position = Vector3(315,0.15,17)
	game.player.velocity = Vector3.ZERO
	Input.action_press("move_forward")
	await frames(480)
	Input.action_release("move_forward")
	check(game.player.position.z < -4, "East flank supports ordinary player traversal")
	game.player.position = Vector3(300,0.1,-9)
	game.player.velocity = Vector3.ZERO
	await frames(4)
	game.player.set_view_direction(areas.record.global_position - game.player.camera.global_position)
	await frames(2)
	check(game.get_target() == areas.record, "Recorder reachable through interaction ray")
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://reviews/survival-slice/relay-recorder.png")
	game.interact_with(areas.record)
	check(areas.relay_recovered, "Recorder sets return objective")
	areas.travel(areas.inbound)
	game.interact_with(game.gate)
	game.interact_with(game.gate)
	check(areas.relay_reported and game.inventory.bandage == pack.bandage+1, "Reports deliver and reward once")
	game.interact_with(game.gate)
	check(game.inventory.bandage == pack.bandage+1, "Repeat report cannot duplicate reward")
	areas.travel(areas.outbound)
	check(not areas.record.visible and areas.encounter_rolls == rolls, "Revisit retains record and encounter roll")
	check(cache.contents.is_empty(), "Looted cache remains empty after returning")
	# Force the present branch for reproducible perception checks.
	var threat = areas.relay_threat
	threat.encounter_present = true
	threat.position = Vector3(288,0.1,8)
	threat.rotation = Vector3.ZERO
	game.player.position = Vector3(288,0.1,3)
	await frames(3)
	threat.sense_player()
	check(threat.state == "chase", "Relay creature detects exposed player")
	game.player.position = Vector3(312,0.1,17)
	game.player.noise_radius = 0
	threat.attention = 0
	await frames(2)
	check(threat.state == "search", "Relay creature searches after losing contact")
	threat.search_time = 0.01
	await frames(2)
	check(threat.state == "patrol", "Relay search eventually gives up")
	# Test physical routing around a solid wall, without steering the creature.
	var wall = game.box(Vector3(288,1.5,-7),Vector3(4,3,0.4),game.concrete)
	threat.position = Vector3(288,0.1,-3)
	threat.velocity = Vector3.ZERO
	threat.state = "investigate"
	threat.attention = 100
	threat.sense_timer = 100
	threat.last_known = Vector3(288,0,-11)
	threat.routing.refresh = 0
	var closest := 100.0
	for i in 660:
		await physics_frame
		closest = minf(closest,threat.position.distance_to(Vector3(288,0,-11)))
	check(closest < 1.2, "Pursuit routes around solid wall: " + str(closest))
	wall.queue_free()
	areas.travel(areas.inbound)
	var frozen: Vector3 = threat.position
	await frames(10)
	check(threat.position == frozen and threat.breath.stream_paused, "Inactive area suspends pursuit and audio")
	print("AREA_JOURNEY: failures=", failures)
	quit(1 if failures else 0)

