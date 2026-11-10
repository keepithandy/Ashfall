extends Node3D
## Station side objective. All positions are relative to the saved station placement.
var game: Node3D
var threat: CharacterBody3D
var stage := "repair"
var remaining := 0.0
var previous_state := ""
var generator: StaticBody3D
var motor: AudioStreamPlayer3D
var lamp: OmniLight3D

func setup(world: Node3D) -> void:
	game = world
	generator = get_node("Interior/Generator")
	generator.set_meta("interaction", "station_generator")
	lamp = get_node("Interior/WorkLight")
	lamp.light_energy = 0.04
	motor = AudioStreamPlayer3D.new()
	motor.bus = "Effects"
	motor.volume_db = -23
	motor.max_distance = 38
	motor.stream = motor_sound()
	generator.add_child(motor)
	threat = get_node("StationThreat")
	threat.game = game
	threat.station_mode = true
	threat.points = []
	for p in [Vector3(4,0,13),Vector3(4,0,9),Vector3(4,0,6),Vector3(5,0,6),Vector3(5,0,9)]:
		var point := to_global(p)
		point.y = 0.1
		threat.points.append(point)
	threat.set_physics_process(false)
	threat.breath.stop()

func motor_sound() -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_end = 22050
	var data := PackedByteArray()
	data.resize(44100)
	for i in 22050:
		var t := float(i)/22050.0
		data.encode_s16(i*2, int((sin(TAU*48*t)*0.6 + sin(TAU*96*t)*0.2) * (0.7+0.3*sin(TAU*8*t)) * 12000))
	wav.data = data
	return wav

func interact() -> void:
	if stage == "repair":
		stage = "starting"
		remaining = 12.0
		motor.play()
		threat.set_physics_process(true)
		threat.breath.play()
		threat.state = "investigate"
		threat.last_known = threat.points[2]
		threat.attention = 42.0
		game.show_message("Generator starting. That noise carries. Crouch behind solid cover; keep away from windows.", 8)
	elif stage == "starting":
		game.show_message("Generator warming up — %d seconds." % ceili(remaining))
	elif stage == "ready":
		stage = "return"
		motor.stop()
		game.show_message("Relay diagnostic recovered. Return to the entry gate. Listen before stepping outside.", 7)
	else:
		game.show_message("Diagnostic already recovered.")

func report_at_gate() -> bool:
	if stage != "return": return false
	stage = "complete"
	game.inventory["batteries"] = int(game.inventory.get("batteries",0)) + 1
	game.show_message("Crossroads report delivered. Checkpoint issued one spare battery. Research mission remains available.", 8)
	return true

func objective_text() -> String:
	match stage:
		"repair": return "CROSSROADS / Start the maintenance generator (east of gate)"
		"starting": return "CROSSROADS / Let generator warm up: %ds — find cover" % ceili(remaining)
		"ready": return "CROSSROADS / E at generator: recover relay diagnostic"
		"return": return "CROSSROADS / Deliver diagnostic at entry gate"
	return "CROSSROADS / Report delivered"

func _process(delta: float) -> void:
	if not is_instance_valid(game) or not game.player.active or (game.areas != null and game.areas.current != "perimeter"): 
		if is_instance_valid(motor): motor.stream_paused = true
		return
	motor.stream_paused = false
	if stage == "starting":
		remaining = maxf(0, remaining-delta)
		lamp.light_energy = 0.18 + 0.12*sin(remaining*17)
		if remaining <= 0:
			stage = "ready"
			lamp.light_energy = 0.65
			motor.volume_db = -30
			game.show_message("Relay diagnostic ready. Retrieve it from the generator with E.", 6)
	if stage != "repair" and threat.state != previous_state:
		previous_state = threat.state
		if threat.global_position.distance_to(game.player.global_position) < 26:
			if previous_state == "search": game.show_message("Footsteps circle the yard. Stay quiet behind solid cover.", 5)
			elif previous_state == "chase": game.show_message("It saw you. Break sight — use the building corners!", 4)
			elif previous_state == "retreat": game.show_message("The footsteps are moving away.", 4)
