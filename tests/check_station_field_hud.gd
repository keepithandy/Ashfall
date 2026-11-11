extends SceneTree
## Live Station 04 HUD/view integration: real player, main scene, telemetry,
## interaction UI, responsive positioning and no floating world captions.
## Run: godot --headless --path . --script res://tests/check_station_field_hud.gd

func _initialize() -> void:
	call_deferred("_verify")


func _verify() -> void:
	var failures: Array[String] = []
	var packed := load("res://scenes/ashfall_station_main.tscn") as PackedScene
	if packed == null:
		push_error("Station 04 scene not found")
		quit(1)
		return
	var level := packed.instantiate()
	root.add_child(level)
	await process_frame

	var player := level.get("player") as CharacterBody3D
	var hud := level.get("hud") as Control
	if player == null or player.camera == null:
		failures.append("Main scene did not create a controllable player camera")
	elif not is_equal_approx(player.camera.far, 900.0):
		failures.append("Station 04 camera is not using the 900m viewing budget")

	if hud == null:
		failures.append("Live game HUD is missing")
	else:
		hud.size = Vector2(1280, 720)
		hud.call("_layout_hud")
		for field_name in ["title", "area_label", "objective", "bearing", "stats", "pack_status", "detector_status", "message", "interaction", "footer_hint"]:
			var field: Label = hud.get(field_name)
			if field == null:
				failures.append("Missing field HUD label: " + field_name)
			elif field.size.x < 100.0:
				failures.append("Field HUD layout has zero-width label: " + field_name)
		var health: ProgressBar = hud.get("health_bar")
		var stamina: ProgressBar = hud.get("stamina_bar")
		if health == null or stamina == null:
			failures.append("Field HUD health/stamina bars are missing")
		else:
			hud.call("_process", 0.0)
			if absf(health.value - float(player.health)) > 0.1 or absf(stamina.value - float(player.stamina)) > 0.1:
				failures.append("HUD does not show the real player health and stamina")
		var event := InputEventKey.new()
		event.physical_keycode = KEY_F10
		event.pressed = true
		hud.call("_input", event)
		if int(hud.get("field_theme_mode")) != 1:
			failures.append("F10 failed to switch the HUD palette")
		hud.call("_layout_hud")
		var prompt: Label = hud.get("interaction")
		if prompt != null and prompt.position.y < 440:
			failures.append("Interaction prompt is no longer near the bottom of the field screen")

	for caption in level.find_children("*", "Label3D", true, false):
		if caption.visible:
			failures.append("World-space floating text is still visible: " + str(caption.name))
			break
	if level.get_node_or_null("EditableWorld/Objectives/ResearchLabel") != null or level.get_node_or_null("EditableWorld/Objectives/GateLabel") != null:
		failures.append("Legacy objective captions remain in the Station 04 scene")

	level.queue_free()
	await process_frame
	if failures.is_empty():
		print("STATION 04 FIELD HUD CHECK PASSED")
		print("Camera distance, telemetry, theme switch, anchored layout and world-caption cleanup validated")
		quit(0)
	else:
		for issue in failures:
			push_error(issue)
		print("STATION 04 FIELD HUD CHECK FAILED: ", failures.size(), " issues")
		quit(1)
