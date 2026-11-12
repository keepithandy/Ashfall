extends Control

var game: Node3D
var title: Label
var area_label: Label
var objective: Label
var interaction: Label
var message: Label
var bearing: Label
var stats: Label
var overlay: ColorRect
var menu_title: Label
var menu_body: Label
var start_button: Button
var quit_button: Button
var health_bar: ProgressBar
var stamina_bar: ProgressBar
var pack_status: Label
var loot_panel: Panel
var loot_contents: Label
var take_button: Button
var inventory_screen: Control
var detector_status: Label
var audio_panel: ColorRect
var intro_layout: Array[Dictionary] = []
var intro_label_layout: Dictionary = {}
const FIELD_THEME_PATH := "user://ashfall_field_hud.cfg"
const THEME_NAMES := ["FIELD JOURNAL", "SIGNAL RECEIVER", "WORN AMBER"]
var footer_hint: Label
var journal_stamp: Label
var objective_heading: Label
var kit_heading: Label
var vitals_heading: Label
var signal_heading: Label
var vital_status: Label
var field_activity: Label
var field_theme_mode: int = 0 # Personal field journal by default.
var hud_pale := Color("e7dfcd")
var hud_muted := Color("b2aa95")
var hud_accent := Color("b79a6b")
var hud_panel := Color(0.043, 0.044, 0.038, 0.86)
var hud_border := Color(0.39, 0.37, 0.30, 0.86)


func label_at(text_value: String, at: Vector2, size: int, tint: Color) -> Label:
	var item := Label.new()
	item.text = text_value
	item.position = at
	item.add_theme_font_size_override("font_size", size)
	item.add_theme_color_override("font_color", tint)
	item.add_theme_color_override("font_shadow_color", Color(0,0,0,0.9))
	item.add_theme_constant_override("shadow_offset_x", 1)
	item.add_theme_constant_override("shadow_offset_y", 2)
	add_child(item)
	return item

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Field-device HUD: durable screen-space telemetry, not 3D labels.
	# Anchored dynamically for 16:9 and other window sizes.
	var pale := Color("deddd0")
	var muted := Color("a2b3a6")
	title = label_at("ASHFALL  /  FIELD UNIT 04", Vector2.ZERO, 17, pale)
	area_label = label_at("STATION 04  /  PERIMETER", Vector2.ZERO, 12, muted)
	objective = label_at("", Vector2.ZERO, 15, pale)
	objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bearing = label_at("", Vector2.ZERO, 16, pale)
	bearing.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interaction = label_at("", Vector2.ZERO, 17, pale)
	interaction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message = label_at("", Vector2.ZERO, 15, pale)
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stats = label_at("", Vector2.ZERO, 13, muted)
	pack_status = label_at("", Vector2.ZERO, 13, pale)
	pack_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detector_status = label_at("", Vector2.ZERO, 13, Color("d1b287"))
	detector_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	footer_hint = label_at("[TAB] PACK  /  [E] INTERACT  /  [F] LIGHT  /  [ESC] PAUSE  /  [F10] THEME", Vector2.ZERO, 11, muted)
	journal_stamp = label_at("ENTRY RECORD  /  00:00", Vector2.ZERO, 11, muted)
	objective_heading = label_at("CURRENT FIELD NOTES", Vector2.ZERO, 11, Color("b79a6b"))
	kit_heading = label_at("PACK INVENTORY  /  ON PERSON", Vector2.ZERO, 11, Color("b79a6b"))
	vitals_heading = label_at("SURVIVOR CONDITION", Vector2.ZERO, 11, Color("b79a6b"))
	signal_heading = label_at("SIGNAL AND SURROUNDINGS", Vector2.ZERO, 11, Color("b79a6b"))
	vital_status = label_at("STATUS  /  STABLE", Vector2.ZERO, 11, muted)
	field_activity = label_at("MOVEMENT  /  QUIET", Vector2.ZERO, 11, muted)
	health_bar = make_bar(Vector2.ZERO, Color("aa6052"))
	stamina_bar = make_bar(Vector2.ZERO, Color("8a9274"))
	overlay = ColorRect.new()
	overlay.color = Color(0.018, 0.023, 0.021, 0.93)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	var stripe := ColorRect.new()
	stripe.position = Vector2(100, 130)
	stripe.size = Vector2(4, 420)
	stripe.color = Color("8a473b")
	overlay.add_child(stripe)
	menu_title = Label.new()
	menu_title.position = Vector2(132, 150)
	menu_title.text = "ASHFALL  /  FIELD JOURNAL"
	menu_title.add_theme_font_size_override("font_size", 72)
	menu_title.add_theme_color_override("font_color", pale)
	overlay.add_child(menu_title)
	menu_body = Label.new()
	menu_body.position = Vector2(138, 255)
	menu_body.add_theme_font_size_override("font_size", 20)
	menu_body.add_theme_color_override("font_color", pale)
	menu_body.text = "A FIELD EXPEDITION  /  EARLY PLAYABLE PROTOTYPE\n\nRecover the sample at the research station and return.\nPower Crossroads to open the North Relay passage.\nTAB inventory  /  Q use held item  /  F flashlight\n\nListen for footsteps. Crouch behind solid cover."
	overlay.add_child(menu_body)
	start_button = Button.new()
	start_button.position = Vector2(138, 498)
	start_button.size = Vector2(250, 48)
	start_button.text = "ENTER THE PERIMETER"
	start_button.pressed.connect(func(): game.resume_game())
	overlay.add_child(start_button)
	quit_button = Button.new()
	quit_button.position = Vector2(405, 498)
	quit_button.size = Vector2(110, 48)
	quit_button.text = "QUIT"
	quit_button.pressed.connect(func(): get_tree().quit())
	overlay.add_child(quit_button)
	var audio_button := Button.new()
	audio_button.position = Vector2(535, 498)
	audio_button.size = Vector2(170, 48)
	audio_button.text = "AUDIO"
	audio_button.pressed.connect(func(): audio_panel.show())
	overlay.add_child(audio_button)
	style_button(audio_button)
	build_audio_panel(pale, muted)
	build_loot_panel(pale,muted)
	style_button(start_button)
	style_button(quit_button)
	inventory_screen=load("res://scripts/runtime/inventory_screen.gd").new()
	inventory_screen.game=game
	add_child(inventory_screen)
	resized.connect(_layout_hud)
	_load_field_theme()
	_apply_field_palette()
	_layout_hud()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F10:
		set_field_theme((field_theme_mode + 1) % THEME_NAMES.size())
		get_viewport().set_input_as_handled()


func _load_field_theme() -> void:
	var settings := ConfigFile.new()
	if settings.load(FIELD_THEME_PATH) == OK:
		field_theme_mode = clampi(int(settings.get_value("field_hud", "theme", 0)), 0, THEME_NAMES.size() - 1)


func set_field_theme(next_mode: int) -> void:
	field_theme_mode = clampi(next_mode, 0, THEME_NAMES.size() - 1)
	_apply_field_palette()
	var settings := ConfigFile.new()
	settings.set_value("field_hud", "theme", field_theme_mode)
	var result := settings.save(FIELD_THEME_PATH)
	if result != OK:
		push_warning("Ashfall field HUD preference could not be saved")


func _apply_field_palette() -> void:
	# Player-selected instrument finish is persistent across sessions.
	# All three palettes keep the same functional data and contrast hierarchy.
	match field_theme_mode:
		0: # Field journal: stained paper, weathered brass, blackened leather.
			hud_pale = Color("e7dfcd")
			hud_muted = Color("b2aa95")
			hud_accent = Color("b79a6b")
			hud_panel = Color(0.043, 0.044, 0.038, 0.86)
			hud_border = Color(0.39, 0.37, 0.30, 0.86)
		1: # Cold receiver: aged green phosphor and slate hardware.
			hud_pale = Color("dce8db")
			hud_muted = Color("9cbaa9")
			hud_accent = Color("77bd9b")
			hud_panel = Color(0.018, 0.041, 0.036, 0.85)
			hud_border = Color(0.18, 0.37, 0.32, 0.86)
		2: # Worn amber: distressed oxide, dust and low-output instrument light.
			hud_pale = Color("efdec9")
			hud_muted = Color("c6aa91")
			hud_accent = Color("d28a62")
			hud_panel = Color(0.056, 0.033, 0.026, 0.86)
			hud_border = Color(0.47, 0.28, 0.20, 0.88)
	for field in [title, objective, bearing, interaction, message, pack_status]:
		field.add_theme_color_override("font_color", hud_pale)
	for field in [area_label, journal_stamp, stats, footer_hint, vital_status, field_activity]:
		field.add_theme_color_override("font_color", hud_muted)
	for field in [detector_status, objective_heading, kit_heading, vitals_heading, signal_heading]:
		field.add_theme_color_override("font_color", hud_accent)
	if is_instance_valid(health_bar):
		var health_fill := health_bar.get_theme_stylebox("fill") as StyleBoxFlat
		if health_fill != null:
			health_fill.bg_color = Color("b96757") if field_theme_mode != 1 else Color("9e665d")
	if is_instance_valid(stamina_bar):
		var stamina_fill := stamina_bar.get_theme_stylebox("fill") as StyleBoxFlat
		if stamina_fill != null:
			stamina_fill.bg_color = hud_accent
	if is_instance_valid(overlay):
		overlay.color = Color(hud_panel.r * 0.45, hud_panel.g * 0.45, hud_panel.b * 0.45, 0.96)
	if is_instance_valid(menu_title):
		menu_title.add_theme_color_override("font_color", hud_pale)
	if is_instance_valid(menu_body):
		menu_body.add_theme_color_override("font_color", hud_pale)
	if is_instance_valid(loot_panel):
		var cache_style := loot_panel.get_theme_stylebox("panel") as StyleBoxFlat
		if cache_style != null:
			cache_style.bg_color = Color(hud_panel.r, hud_panel.g, hud_panel.b, 0.98)
			cache_style.border_color = hud_accent
	if is_instance_valid(start_button):
		style_button(start_button)
	if is_instance_valid(quit_button):
		style_button(quit_button)
	if is_instance_valid(overlay):
		for item in overlay.get_children():
			if item is Button:
				style_button(item)
	footer_hint.text = "[TAB] PACK  /  [E] USE  /  [F] LIGHT  /  [ESC] MENU  /  [F10] " + THEME_NAMES[field_theme_mode]
	queue_redraw()



func _layout_hud() -> void:
	if title == null or not is_instance_valid(title) or overlay == null:
		return
	var w := maxf(size.x, 720.0)
	var h := maxf(size.y, 480.0)
	var left_w := minf(420.0, w * 0.40)
	var right_w := minf(292.0, w * 0.30)
	title.position = Vector2(36, 29)
	title.size = Vector2(left_w - 28, 28)
	area_label.position = Vector2(36, 57)
	area_label.size = Vector2(left_w - 30, 22)
	journal_stamp.position = Vector2(36, 81)
	journal_stamp.size = Vector2(left_w - 30, 19)
	objective_heading.position = Vector2(36, 112)
	objective_heading.size = Vector2(left_w - 30, 18)
	objective.position = Vector2(36, 139)
	objective.size = Vector2(left_w - 33, 91)
	bearing.position = Vector2(w * 0.5 - 107, 251 if w < 1100.0 else 39)
	bearing.size = Vector2(214, 26)
	kit_heading.position = Vector2(w - right_w - 9, 36)
	kit_heading.size = Vector2(right_w - 33, 20)
	pack_status.position = Vector2(w - right_w - 9, 64)
	pack_status.size = Vector2(right_w - 29, 86)
	vitals_heading.position = Vector2(36, h - 156)
	vitals_heading.size = Vector2(267, 20)
	stats.position = Vector2(36, h - 128)
	stats.size = Vector2(267, 26)
	health_bar.position = Vector2(36, h - 101)
	stamina_bar.position = Vector2(36, h - 80)
	vital_status.position = Vector2(36, h - 59)
	vital_status.size = Vector2(267, 18)
	signal_heading.position = Vector2(w - right_w - 9, h - 136)
	signal_heading.size = Vector2(right_w - 28, 18)
	detector_status.position = Vector2(w - right_w - 9, h - 111)
	detector_status.size = Vector2(right_w - 32, 49)
	field_activity.position = Vector2(w - right_w - 9, h - 59)
	field_activity.size = Vector2(right_w - 30, 18)
	var message_width := minf(686.0, w * 0.75)
	message.position = Vector2((w - message_width) * 0.5, h - 241)
	message.size = Vector2(message_width, 52)
	var prompt_width := minf(610.0, maxf(280.0, w - 660.0))
	interaction.position = Vector2((w - prompt_width) * 0.5, h - 151)
	interaction.size = Vector2(prompt_width, 34)
	footer_hint.position = Vector2(26, h - 28)
	footer_hint.size = Vector2(w - 52, 20)
	if w < 1100:
		footer_hint.text = "[TAB] PACK  /  [E] USE  /  [ESC] MENU  /  [F10] THEME"
	else:
		footer_hint.text = "[TAB] PACK  /  [E] USE  /  [F] LIGHT  /  [ESC] MENU  /  [F10] " + THEME_NAMES[field_theme_mode]
	loot_panel.position = Vector2((w - loot_panel.size.x) * 0.5, (h - loot_panel.size.y) * 0.5)
	if not intro_layout.is_empty():
		_layout_intro()
	queue_redraw()



func _draw_field_panel(rect: Rect2) -> void:
	draw_rect(rect, hud_panel, true)
	draw_rect(rect, hud_border, false, 1.0)
	draw_rect(Rect2(rect.position + Vector2(0, 0), Vector2(68, 3)), hud_accent, true)
	draw_line(rect.position + Vector2(rect.size.x - 16, 0), rect.position + Vector2(rect.size.x, 16), hud_accent, 1.0)
	draw_line(rect.position + Vector2(8, rect.size.y - 9), rect.position + Vector2(8, rect.size.y - 20), hud_border, 1.0)
	draw_line(rect.position + Vector2(8, rect.size.y - 9), rect.position + Vector2(26, rect.size.y - 9), hud_border, 1.0)
	# Three static abrasion marks imply worn equipment without distracting animation.
	for mark in range(3):
		var px := rect.position.x + rect.size.x - 52 + mark * 9
		draw_line(Vector2(px, rect.position.y + rect.size.y - 11), Vector2(px + 4, rect.position.y + rect.size.y - 7), Color(hud_muted.r, hud_muted.g, hud_muted.b, 0.25), 1.0)


func build_audio_panel(pale: Color, muted: Color) -> void:
	audio_panel = ColorRect.new()
	audio_panel.name = "AudioSettings"
	audio_panel.color = Color(0.018, 0.023, 0.021, 1.0)
	audio_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	audio_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(audio_panel)
	var heading := Label.new()
	heading.position = Vector2(138, 115)
	heading.text = "AUDIO SETTINGS"
	heading.add_theme_font_size_override("font_size", 42)
	heading.add_theme_color_override("font_color", pale)
	audio_panel.add_child(heading)
	var caption := Label.new()
	caption.position = Vector2(140, 179)
	caption.text = "Adjust the mix. Changes are saved automatically."
	caption.add_theme_font_size_override("font_size", 16)
	caption.add_theme_color_override("font_color", muted)
	audio_panel.add_child(caption)
	var rows := [["Master", "MASTER"], ["Wind", "WIND & DRONE"], ["Footsteps", "FOOTSTEPS"], ["Effects", "CREATURE & WORLD SOUNDS"]]
	for index in rows.size():
		var bus_name: String = rows[index][0]
		var y := 235.0 + index * 64.0
		var title_label := Label.new()
		title_label.position = Vector2(140, y)
		title_label.size = Vector2(285, 30)
		title_label.text = rows[index][1]
		title_label.add_theme_font_size_override("font_size", 16)
		title_label.add_theme_color_override("font_color", pale)
		audio_panel.add_child(title_label)
		var value_label := Label.new()
		value_label.position = Vector2(850, y)
		value_label.size = Vector2(70, 30)
		value_label.add_theme_font_size_override("font_size", 16)
		value_label.add_theme_color_override("font_color", pale)
		audio_panel.add_child(value_label)
		var slider := HSlider.new()
		slider.name = bus_name + "Slider"
		slider.position = Vector2(440, y + 2)
		slider.size = Vector2(380, 26)
		slider.min_value = 0
		slider.max_value = 100
		slider.step = 1
		slider.value = roundi(float(game.audio_settings.levels[bus_name]) * 100)
		value_label.text = "%d%%" % int(slider.value)
		slider.value_changed.connect(_audio_level_changed.bind(bus_name, value_label))
		audio_panel.add_child(slider)
	var back := Button.new()
	back.position = Vector2(140, 540)
	back.size = Vector2(180, 48)
	back.text = "BACK"
	back.pressed.connect(func(): audio_panel.hide())
	style_button(back)
	audio_panel.add_child(back)
	audio_panel.hide()

func _audio_level_changed(value: float, bus_name: String, value_label: Label) -> void:
	value_label.text = "%d%%" % int(value)
	game.audio_settings.set_level(bus_name, value / 100.0)

func style_button(button: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(hud_panel.r * 1.7, hud_panel.g * 1.7, hud_panel.b * 1.7, 1.0)
	normal.border_color = hud_border
	normal.set_border_width_all(1)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(hud_panel.r * 2.7, hud_panel.g * 2.7, hud_panel.b * 2.7, 1.0)
	hover.border_color = hud_accent
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_color_override("font_color", hud_pale)
	button.add_theme_color_override("font_hover_color", hud_pale)

func build_loot_panel(pale: Color, muted: Color) -> void:
	loot_panel=Panel.new()
	loot_panel.position=Vector2(390,135)
	loot_panel.size=Vector2(500,450)
	var style:=StyleBoxFlat.new()
	style.bg_color=Color(0.035,0.041,0.036,0.97)
	style.border_color=Color("78463d")
	style.set_border_width_all(2)
	style.set_corner_radius_all(2)
	loot_panel.add_theme_stylebox_override("panel",style)
	add_child(loot_panel)
	var title_label:=Label.new()
	title_label.position=Vector2(30,26)
	title_label.text="SUPPLY CACHE"
	title_label.add_theme_font_size_override("font_size",26)
	title_label.add_theme_color_override("font_color",pale)
	loot_panel.add_child(title_label)
	var sub:=Label.new()
	sub.position=Vector2(31,65)
	sub.text="FOUND AT THE OUTER PERIMETER"
	sub.add_theme_font_size_override("font_size",12)
	sub.add_theme_color_override("font_color",muted)
	loot_panel.add_child(sub)
	loot_contents=Label.new()
	loot_contents.position=Vector2(31,117)
	loot_contents.add_theme_font_size_override("font_size",20)
	loot_contents.add_theme_color_override("font_color",pale)
	loot_panel.add_child(loot_contents)
	var hint:=Label.new()
	hint.position=Vector2(31,305)
	hint.text="E or ESC  Close     /     TAB  Open your field pack"
	hint.add_theme_font_size_override("font_size",13)
	hint.add_theme_color_override("font_color",muted)
	loot_panel.add_child(hint)
	take_button=Button.new()
	take_button.position=Vector2(30,354)
	take_button.size=Vector2(205,52)
	take_button.text="TAKE ALL"
	take_button.pressed.connect(func(): game.take_loot())
	loot_panel.add_child(take_button)
	var close:=Button.new()
	close.position=Vector2(250,354)
	close.size=Vector2(205,52)
	close.text="CLOSE"
	close.pressed.connect(func(): game.close_loot())
	loot_panel.add_child(close)
	style_button(take_button)
	style_button(close)
	loot_panel.hide()

func show_loot(contents: Dictionary) -> void:
	loot_contents.text="CACHE EMPTY" if contents.is_empty() else "BANDAGE ROLL    × %d\n\nCANNED FOOD      × %d\n\nBATTERIES              × %d" % [contents.get("bandage",0),contents.get("food_tin",0),contents.get("batteries",0)]
	take_button.disabled=contents.is_empty()
	loot_panel.show()

func make_bar(at: Vector2, tint: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.position = at
	bar.size = Vector2(256, 10)
	bar.max_value = 100.0
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill := StyleBoxFlat.new()
	fill.bg_color = tint
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.10, 0.15, 0.14, 0.90)
	bar.add_theme_stylebox_override("fill", fill)
	bar.add_theme_stylebox_override("background", background)
	add_child(bar)
	return bar

func _process(_delta: float) -> void:
	if not is_instance_valid(game) or not is_instance_valid(game.player):
		return
	area_label.text = "NORTH RELAY  /  SERVICE YARD" if game.areas != null and game.areas.current == "relay" else "STATION 04  /  OUTER PERIMETER"
	health_bar.value = game.player.health
	stamina_bar.value = game.player.stamina
	stats.text = "CONDITION %03d    /    STAMINA %03d" % [int(game.player.health), int(game.player.stamina)]
	var minutes := int(game.elapsed / 60.0)
	journal_stamp.text = "ENTRY RECORD  /  %02d:%02d   /   %s" % [minutes, int(game.elapsed) % 60, "SAMPLE SECURED" if game.has_sample else "IN PROGRESS"]
	var condition := "CRITICAL" if game.player.health < 25.0 else ("WOUNDED" if game.player.health < 60.0 else "STABLE")
	vital_status.text = "FIELD ASSESSMENT  /  " + condition
	var motion := "CROUCHING" if game.player.crouching else ("RUNNING" if game.player.noise_radius >= 9.0 else ("MOVING" if game.player.noise_radius >= 4.0 else "STILL"))
	field_activity.text = "MOVEMENT  /  " + motion
	if game.hazard_strength > 0.08:
		field_activity.text = "WARNING  /  UNSTABLE FIELD"
	pack_status.text = "BANDAGE %d  /  FOOD %d\nBATTERIES %d  /  LIGHT %d%%" % [game.inventory.bandage, game.inventory.food_tin, game.inventory.batteries, int(game.player.battery_charge)]
	var carried: Dictionary = ItemCatalog.entry(game.equipped_item_id)
	pack_status.text += "\nHAND  /  " + str(carried.get("name", "Empty")).to_upper()
	if not carried.is_empty():
		pack_status.text += "  ×" + str(game.inventory.get(game.equipped_item_id, 0))
	objective.text = "01 / RETURN TO THE ENTRY GATE" if game.has_sample else "01 / RECOVER THE RESEARCH SAMPLE"
	if game.crossroads != null: objective.text += "\n" + game.crossroads.objective_text()
	if game.areas != null: objective.text += "\n" + game.areas.objective_text()
	var degrees := fposmod(rad_to_deg(-game.player.rotation.y), 360)
	var directions := ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
	bearing.text = "· · ·    %s   %03d°    · · ·" % [directions[int((degrees + 22.5) / 45) % 8], int(degrees)]
	detector_status.text = game.anomaly_readout() if game.detector_enabled else "SENSOR STANDBY\nEQUIP METER TO SCAN"
	if game.hazard_strength > 0.08:
		detector_status.text = "SIGNAL DISTORTION\nMOVE OUT OF THE FIELD"
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(game) or not game.started or overlay.visible or loot_panel.visible or inventory_screen.visible:
		return
	var w := size.x
	var h := size.y
	if w < 700 or h < 460:
		return
	var left_w := minf(420.0, w * 0.40)
	var right_w := minf(292.0, w * 0.30)
	_draw_field_panel(Rect2(22, 20, left_w, 218))
	_draw_field_panel(Rect2(w - right_w - 22, 20, right_w, 144))
	_draw_field_panel(Rect2(w * 0.5 - 112, 237 if w < 1100.0 else 24, 224, 46))
	_draw_field_panel(Rect2(22, h - 171, 294, 135))
	_draw_field_panel(Rect2(w - right_w - 22, h - 153, right_w, 117))
	if not message.text.is_empty():
		var message_width := minf(710.0, w * 0.78)
		_draw_field_panel(Rect2((w - message_width) * 0.5, h - 248, message_width, 62))
	if not interaction.text.is_empty():
		var prompt_width := minf(632.0, maxf(296.0, w - 644.0))
		_draw_field_panel(Rect2((w - prompt_width) * 0.5, h - 161, prompt_width, 48))
	draw_line(Vector2(20, h - 36), Vector2(w - 20, h - 36), hud_border)
	# Personalized recorder's paperclip / corner scratch motifs are static.
	draw_line(Vector2(23, 247), Vector2(23, 260), hud_border, 2.0)
	draw_line(Vector2(23, 260), Vector2(37, 260), hud_border, 2.0)
	var center := size * 0.5
	var crosshair_ink := Color(hud_pale.r, hud_pale.g, hud_pale.b, 0.68)
	draw_line(center + Vector2(-7, 0), center + Vector2(-3, 0), crosshair_ink)
	draw_line(center + Vector2(3, 0), center + Vector2(7, 0), crosshair_ink)
	draw_line(center + Vector2(0, -7), center + Vector2(0, -3), crosshair_ink)
	draw_line(center + Vector2(0, 3), center + Vector2(0, 7), crosshair_ink)
	if game.hazard_strength > 0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.52, 0.10, 0.04, game.hazard_strength * 0.15))

func _layout_intro() -> void:
	# Station 04 playtest splash: fit laptop and desktop windows without
	# obscuring the journal briefing or clipping any menu action.
	if intro_layout.is_empty():
		return
	var w := maxf(size.x, 720.0)
	var h := maxf(size.y, 480.0)
	var content_width := minf(720.0, w - 64.0)
	menu_title.position = Vector2((w - content_width) * 0.5, maxf(42.0, h * 0.14))
	menu_title.size = Vector2(content_width, 75.0)
	menu_body.position = Vector2((w - content_width) * 0.5, menu_title.position.y + 94.0)
	menu_body.size = Vector2(content_width, 105.0)
	var button_width := minf(280.0, w - 80.0)
	var button_top := minf(maxf(h * 0.60, menu_body.position.y + 124.0), h - 196.0)
	for i in range(intro_layout.size()):
		var button: Button = intro_layout[i]["button"]
		button.position = Vector2((w - button_width) * 0.5, button_top + i * 58.0)
		button.size = Vector2(button_width, 48.0)


func show_minimal_intro() -> void:
	if not intro_layout.is_empty():
		return
	intro_label_layout = {
		"title_position": menu_title.position,
		"title_size": menu_title.size,
		"body_position": menu_body.position,
		"body_size": menu_body.size
	}
	menu_title.show()
	menu_body.show()
	menu_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	overlay.color.a = 1.0
	var buttons: Array[Button] = []
	for child in overlay.get_children():
		if child is Button:
			buttons.append(child)
		elif child is ColorRect and child != audio_panel:
			child.hide()
	for button in buttons:
		intro_layout.append({"button": button, "position": button.position, "size": button.size})
		button.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	start_button.text = "ENTER STATION 04"
	_layout_intro()


func restore_menu_layout() -> void:
	if intro_layout.is_empty():
		return
	menu_title.show()
	menu_body.show()
	menu_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	menu_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	menu_body.autowrap_mode = TextServer.AUTOWRAP_OFF
	if not intro_label_layout.is_empty():
		menu_title.position = intro_label_layout["title_position"]
		menu_title.size = intro_label_layout["title_size"]
		menu_body.position = intro_label_layout["body_position"]
		menu_body.size = intro_label_layout["body_size"]
		intro_label_layout.clear()
	for entry in intro_layout:
		var button: Button = entry["button"]
		button.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		button.position = entry["position"]
		button.size = entry["size"]
	intro_layout.clear()
