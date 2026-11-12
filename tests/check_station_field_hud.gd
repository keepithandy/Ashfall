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
		for field_name in ["title", "area_label", "journal_stamp", "objective_heading", "objective", "kit_heading", "bearing", "stats", "vitals_heading", "vital_status", "pack_status", "signal_heading", "detector_status", "field_activity", "message", "interaction", "footer_hint"]:
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
		var stamp: Label = hud.get("journal_stamp")
		if stamp == null or not stamp.text.contains("ENTRY RECORD"):
			failures.append("Personal expedition record is not updating")
		var activity: Label = hud.get("field_activity")
		player.noise_radius = 10.0
		hud.call("_process", 0.0)
		if activity == null or not activity.text.contains("RUNNING"):
			failures.append("HUD activity indicator ignores real player movement noise")
		player.noise_radius = 0.0
		hud.call("_process", 0.0)
		var starting_theme := int(hud.get("field_theme_mode"))
		var event := InputEventKey.new()
		event.physical_keycode = KEY_F10
		event.pressed = true
		hud.call("_input", event)
		var next_theme := (starting_theme + 1) % 3
		if int(hud.get("field_theme_mode")) != next_theme:
			failures.append("F10 failed to cycle among the three instrument finishes")
		else:
			var settings := ConfigFile.new()
			if settings.load("user://ashfall_field_hud.cfg") != OK or int(settings.get_value("field_hud", "theme", -1)) != next_theme:
				failures.append("Personal HUD theme did not persist")
		hud.call("set_field_theme", starting_theme)
		if hud.get("inventory_screen") == null:
			failures.append("Field pack inventory was disconnected from the HUD")
		hud.call("_layout_hud")
		var prompt: Label = hud.get("interaction")
		if prompt != null and prompt.position.y < 440:
			failures.append("Interaction prompt is no longer near the bottom of the field screen")
		# Laptop-sized windows need a dedicated compass row and a narrow,
		# centered interaction strip that does not cover the vital panels.
		hud.size = Vector2(960, 540)
		hud.call("_layout_hud")
		var compass: Label = hud.get("bearing")
		if compass != null and compass.position.y < 230.0:
			failures.append("Compact HUD compass overlaps the top data panels")
		if prompt != null and (prompt.position.x < 310.0 or prompt.position.x + prompt.size.x > 650.0):
			failures.append("Compact HUD interaction strip overlaps side telemetry")
		# Ashfall 2.0 keeps the opening field journal legible and buttons
		# accessible at laptop resolutions; no blank unbranded splash.
		var opening_title: Label = hud.get("menu_title")
		var opening_body: Label = hud.get("menu_body")
		if opening_title == null or not opening_title.visible or opening_title.text != "ASHFALL 2.0":
			failures.append("Ashfall 2.0 opening title is absent")
		if opening_body == null or not opening_body.visible or not opening_body.text.contains("FIELD EXPEDITION"):
			failures.append("Station 04 opening briefing is absent")
		if opening_title != null and opening_body != null and opening_title.position.y + opening_title.size.y > opening_body.position.y:
			failures.append("Opening title overlaps its field briefing")
		var intro_buttons: Array = hud.get("intro_layout")
		if intro_buttons.size() != 3:
			failures.append("Opening menu lost Play, Quit or Audio")
		else:
			for entry in intro_buttons:
				var button: Button = entry["button"]
				if button == null or button.position.x < 0.0 or button.position.y < opening_body.position.y + opening_body.size.y or button.position.x + button.size.x > 960.0 or button.position.y + button.size.y > 540.0:
					failures.append("Compact opening menu clips or overlaps action buttons")
					break

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
