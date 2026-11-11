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
var footer_hint: Label
var field_theme_mode: int = 0 # 0: cold field monitor; 1: worn amber monitor.
var hud_pale := Color("deddd0")
var hud_muted := Color("a2b3a6")
var hud_accent := Color("88a998")
var hud_panel := Color(0.021, 0.033, 0.032, 0.89)
var hud_border := Color(0.23, 0.36, 0.33, 0.83)


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
	footer_hint = label_at("[TAB] PACK   [E] INTERACT   [F] LIGHT   [H] HEAL   [ESC] MENU   [F10] HUD THEME", Vector2.ZERO, 11, muted)
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
	menu_title.text = "ASHFALL"
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
	_apply_field_palette()
	_layout_hud()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F10:
		field_theme_mode = (field_theme_mode + 1) % 2
		_apply_field_palette()
		get_viewport().set_input_as_handled()


func _apply_field_palette() -> void:
	# Both palettes retain identical gameplay information and a low-light theme.
	if field_theme_mode == 0:
		hud_pale = Color("deddd0")
		hud_muted = Color("a2b3a6")
		hud_accent = Color("88a998")
		hud_panel = Color(0.021, 0.033, 0.032, 0.89)
		hud_border = Color(0.23, 0.36, 0.33, 0.83)
	else:
		hud_pale = Color("e5d9c4")
		hud_muted = Color("bba68d")
		hud_accent = Color("cd9670")
		hud_panel = Color(0.048, 0.035, 0.027, 0.90)
		hud_border = Color(0.43, 0.29, 0.22, 0.83)
	for field in [title, objective, bearing, interaction, message, pack_status]:
		field.add_theme_color_override("font_color", hud_pale)
	for field in [area_label, stats, footer_hint]:
		field.add_theme_color_override("font_color", hud_muted)
	detector_status.add_theme_color_override("font_color", hud_accent)
	queue_redraw()


func _layout_hud() -> void:
	if title == null or not is_instance_valid(title) or overlay == null:
		return
	var w := maxf(size.x, 720.0)
	var h := maxf(size.y, 480.0)
	var left_w := minf(430.0, w * 0.42)
	var right_w := minf(300.0, w * 0.31)
	title.position = Vector2(34, 30)
	title.size = Vector2(left_w - 24, 28)
	area_label.position = Vector2(34, 57)
	area_label.size = Vector2(left_w - 24, 22)
	objective.position = Vector2(34, 96)
	objective.size = Vector2(left_w - 28, 122)
	bearing.position = Vector2(w * 0.5 - 107, 250 if w < 1100.0 else 37)
	bearing.size = Vector2(214, 26)
	pack_status.position = Vector2(w - right_w - 12, 37)
	pack_status.size = Vector2(right_w - 28, 84)
	stats.position = Vector2(34, h - 131)
	stats.size = Vector2(266, 26)
	health_bar.position = Vector2(34, h - 100)
	stamina_bar.position = Vector2(34, h - 77)
	detector_status.position = Vector2(w - right_w - 12, h - 115)
	detector_status.size = Vector2(right_w - 26, 66)
	message.position = Vector2(w * 0.5 - minf(350.0, w * 0.39), h - 214)
	message.size = Vector2(minf(700.0, w * 0.78), 52)
	var prompt_width := minf(610.0, maxf(280.0, w - 660.0))
	interaction.position = Vector2((w - prompt_width) * 0.5, h - 152)
	interaction.size = Vector2(prompt_width, 34)
	footer_hint.position = Vector2(26, h - 28)
	footer_hint.size = Vector2(w - 52, 20)
	loot_panel.position = Vector2((w - loot_panel.size.x) * 0.5, (h - loot_panel.size.y) * 0.5)
	queue_redraw()


func _draw_field_panel(rect: Rect2) -> void:
	draw_rect(rect, hud_panel, true)
	draw_rect(rect, hud_border, false, 1.0)
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 2)), hud_accent * Color(1, 1, 1, 0.80), true)


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
	var normal:=StyleBoxFlat.new()
	normal.bg_color=Color("1c201d")
	normal.border_color=Color("67483f")
	normal.set_border_width_all(1)
	var hover:=normal.duplicate() as StyleBoxFlat
	hover.bg_color=Color("3c302a")
	hover.border_color=Color("b17a64")
	button.add_theme_stylebox_override("normal",normal)
	button.add_theme_stylebox_override("hover",hover)
	button.add_theme_stylebox_override("pressed",hover)
	button.add_theme_color_override("font_color",Color("d3d0bf"))

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
	detector_status.text=game.anomaly_readout() if game.detector_enabled else ""
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(game) or not game.started or overlay.visible or loot_panel.visible or inventory_screen.visible:
		return
	var w := size.x
	var h := size.y
	if w < 700 or h < 460:
		return
	var left_w := minf(430.0, w * 0.42)
	var right_w := minf(300.0, w * 0.31)
	_draw_field_panel(Rect2(22, 20, left_w, 214))
	_draw_field_panel(Rect2(w - right_w - 22, 20, right_w, 116))
	_draw_field_panel(Rect2(w * 0.5 - 112, 237 if w < 1100.0 else 24, 224, 46))
	_draw_field_panel(Rect2(22, h - 146, 285, 112))
	_draw_field_panel(Rect2(w - right_w - 22, h - 132, right_w, 98))
	if not message.text.is_empty():
		_draw_field_panel(Rect2(w * 0.5 - minf(362.0, w * 0.40), h - 221, minf(724.0, w * 0.80), 62))
	if not interaction.text.is_empty():
		var prompt_width := minf(632.0, maxf(296.0, w - 644.0))
		_draw_field_panel(Rect2((w - prompt_width) * 0.5, h - 161, prompt_width, 48))
	draw_line(Vector2(20, h - 38), Vector2(w - 20, h - 38), hud_border)
	var center := size * 0.5
	var ink := Color(hud_pale.r, hud_pale.g, hud_pale.b, 0.60)
	draw_line(center + Vector2(-7, 0), center + Vector2(-3, 0), ink)
	draw_line(center + Vector2(3, 0), center + Vector2(7, 0), ink)
	draw_line(center + Vector2(0, -7), center + Vector2(0, -3), ink)
	draw_line(center + Vector2(0, 3), center + Vector2(0, 7), ink)
	if game.hazard_strength > 0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.55, 0.11, 0.04, game.hazard_strength * 0.18))

func show_minimal_intro() -> void:
	menu_title.hide()
	menu_body.hide()
	overlay.color.a = 1.0
	var buttons: Array[Button] = []
	for child in overlay.get_children():
		if child is Button:
			buttons.append(child)
		elif child is ColorRect and child != audio_panel:
			child.hide()
	for i in range(buttons.size()):
		var button := buttons[i]
		intro_layout.append({"button": button, "position": button.position, "size": button.size})
		button.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		button.position = overlay.size / 2 + Vector2(-140, -88 + i * 64)
		button.size = Vector2(280, 48)
	start_button.text = "PLAY"

func restore_menu_layout() -> void:
	if intro_layout.is_empty():
		return
	menu_title.show()
	menu_body.show()
	for entry in intro_layout:
		var button: Button = entry.button
		button.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		button.position = entry.position
		button.size = entry.size
	intro_layout.clear()
