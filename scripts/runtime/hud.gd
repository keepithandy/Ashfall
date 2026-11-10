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
	var pale := Color("d3d0bf")
	var muted := Color("92988a")
	title = label_at("A S H F A L L   /   FIELD EXPEDITION 01", Vector2(34, 24), 16, pale)
	area_label = label_at("THE OUTER PERIMETER", Vector2(34, 49), 12, muted)
	objective = label_at("", Vector2(34, 100), 18, pale)
	bearing = label_at("", Vector2(520, 28), 16, pale)
	bearing.size.x = 250
	bearing.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interaction = label_at("", Vector2(340, 418), 20, pale)
	interaction.size.x = 600
	interaction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message = label_at("", Vector2(290, 584), 18, pale)
	message.size.x = 700
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats = label_at("", Vector2(34, 618), 13, muted)
	pack_status = label_at("", Vector2(900, 30), 13, pale)
	health_bar = make_bar(Vector2(34, 650), Color("aa6052"))
	stamina_bar = make_bar(Vector2(34, 668), Color("8a9274"))
	label_at("WASD Move  SHIFT Sprint  CTRL Crouch  F Torch  E Search  TAB Pack  Q Use held  ESC Pause", Vector2(275, 675), 12, muted)
	detector_status=label_at("",Vector2(34,574),14,Color("c29d68"))
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
	bar.size = Vector2(220, 28)
	bar.scale.y = 0.25
	bar.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = tint
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.12, 0.16, 0.14, 0.8)
	bar.add_theme_stylebox_override("fill", fill)
	bar.add_theme_stylebox_override("background", background)
	add_child(bar)
	return bar

func _process(_delta: float) -> void:
	if not is_instance_valid(game) or not is_instance_valid(game.player):
		return
	area_label.text = "NORTH RELAY / SERVICE YARD" if game.areas != null and game.areas.current == "relay" else "THE OUTER PERIMETER"
	health_bar.value = game.player.health
	stamina_bar.value = game.player.stamina
	stats.text = "CONDITION %03d    /    STAMINA %03d" % [game.player.health, game.player.stamina]
	pack_status.text = "BANDAGE %d  FOOD %d  BAT %d   LIGHT %d%%" % [game.inventory.bandage,game.inventory.food_tin,game.inventory.batteries,game.player.battery_charge]
	var carried: Dictionary=ItemCatalog.entry(game.equipped_item_id)
	pack_status.text+="\nHAND / "+str(carried.get("name","Empty")).to_upper()
	if not carried.is_empty():pack_status.text+="  ×"+str(game.inventory.get(game.equipped_item_id,0))
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
	var center := size * 0.5
	var ink := Color(0.82, 0.88, 0.79, 0.6)
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
