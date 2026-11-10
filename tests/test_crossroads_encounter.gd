extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
	else: print("PASS: ",message)
func frames(n: int) -> void:
	for i in n: await physics_frame
func run() -> void:
	var game = load("res://scenes/ashfall_editable.tscn").instantiate()
	root.add_child(game)
	game.smoke_test = true
	game.resume_game()
	await frames(5)
	var encounter = game.crossroads
	var station = encounter.get_parent()
	var threat = encounter.threat
	check(encounter != null and encounter.stage == "repair", "Station encounter bound in main scene")
	game.player.position = station.to_global(Vector3(1.2,0.1,-1.5))
	game.player.velocity = Vector3.ZERO
	await frames(5)
	game.player.set_view_direction(encounter.generator.global_position + Vector3(0,0.3,0) - game.player.camera.global_position)
	await frames(2)
	check(game.get_target() == encounter.generator,"Generator reachable by real interaction ray")
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://reviews/crossroads/encounter.png")
	game.interact_with(encounter.generator)
	check(encounter.stage == "starting" and threat.state == "investigate", "Starting generator alerts threat")
	var time: float = encounter.remaining
	game.player.active = false
	await frames(10)
	check(encounter.remaining == time and encounter.motor.stream_paused, "Pause freezes encounter and audio")
	game.player.active = true
	game.player.position = station.to_global(Vector3(-4.8,0.1,-2.7))
	game.player.velocity = Vector3.ZERO
	await frames(5)
	check(not threat.has_line_to_player(), "Interior wall cover blocks creature sight")
	var closest := 1000.0
	Engine.time_scale = 3.0
	for i in 420:
		await physics_frame
		closest = minf(closest, threat.global_position.distance_to(threat.points[2]))
	Engine.time_scale = 1.0
	check(closest < 2.0, str(closest) + " Creature physically approaches generator-side yard without crossing walls")
	encounter.remaining = 0.03
	await frames(5)
	check(encounter.stage == "ready", "Warmup produces diagnostic")
	game.interact_with(encounter.generator)
	check(encounter.stage == "return" and not encounter.motor.playing, "Retrieval stops generator and sets return objective")
	game.player.position = game.gate.global_position + Vector3(0,0,2)
	game.player.velocity = Vector3.ZERO
	await frames(3)
	threat.set_physics_process(true)
	threat.attention = 0
	threat.state = "investigate"
	await frames(2)
	check(threat.state == "search", "Lost contact starts search")
	threat.search_time = 0.01
	await frames(2)
	check(threat.state == "retreat", "Search expires into retreat")
	var batteries: int = game.inventory.batteries
	game.interact_with(game.gate)
	check(encounter.stage == "complete" and game.inventory.batteries == batteries+1, "Gate accepts report and awards battery")
	game.interact_with(game.gate)
	check(game.inventory.batteries == batteries+1, "Reward cannot be duplicated")
	# Let the actual controller retreat through the yard, without teleporting it.
	Engine.time_scale = 3.0
	for i in 1200:
		await physics_frame
		if not threat.is_physics_processing(): break
	check(not threat.is_physics_processing(), "Creature physically withdraws to its yard retreat point")
	Engine.time_scale = 1.0
	game.queue_free()
	await process_frame
	print("CROSSROADS_ENCOUNTER: failures=", failures)
	quit(1 if failures else 0)

