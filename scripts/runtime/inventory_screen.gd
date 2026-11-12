extends Control
## A simple slot inventory; the gameplay item and hand systems remain unchanged.
const Items = preload("res://scripts/runtime/item_catalog.gd")
const Skin = preload("res://scripts/runtime/weathered_ui_style.gd")
const SLOT_COUNT := 27
const COLUMNS := 9
const SLOT_SIZE := 58
const TEXT := Skin.INK
const MUTED := Skin.FADED_INK

var game: Node3D
var selected_id := "flashlight"
var item_buttons: Dictionary = {}
var count_labels: Dictionary = {}
var item_icons: Dictionary = {}
var selected_title: Label
var item_details: Label
var carry_status: Label
var feedback: Label
var equip_button: Button
var use_button: Button
var stow_button: Button

func make_style(background: Color, edge: Color, border: int = 2) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = background
	box.border_color = edge
	box.set_border_width_all(border)
	box.set_corner_radius_all(0)
	return box

func make_label(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func make_action(caption: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(120, 42)
	Skin.control_button(button, true)
	button.pressed.connect(action)
	return button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0.018, 0.021, 0.016, 0.9)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.name = "InventoryPanel"
	panel.add_theme_stylebox_override("panel", Skin.panel(Skin.PAPER, Skin.LEATHER, 4, 12))
	center.add_child(panel)
	Skin.paper_texture(panel, true)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 13)
	panel.add_child(margin)
	var layout := VBoxContainer.new()
	layout.custom_minimum_size.x = 568
	layout.add_theme_constant_override("separation", 8)
	margin.add_child(layout)
	var header := HBoxContainer.new()
	layout.add_child(header)
	var title := make_label("WHAT I HAVE LEFT  /  FIELD PACK", 22, TEXT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close := make_action("PUT AWAY  /  TAB", func(): game.close_inventory())
	close.custom_minimum_size = Vector2(152, 40)
	header.add_child(close)
	carry_status = make_label("", 14, MUTED)
	layout.add_child(carry_status)
	var grid := GridContainer.new()
	grid.name = "Slots"
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	layout.add_child(grid)
	for index in SLOT_COUNT:
		var id: String = Items.ORDER[index] if index < Items.ORDER.size() else ""
		var slot := Button.new()
		slot.name = "Slot%02d" % (index + 1)
		slot.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
		slot.expand_icon = true
		slot.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot.add_theme_constant_override("icon_max_width", 48)
		slot.add_theme_stylebox_override("normal", make_style(Color("88806b"), Color("534d3e")))
		slot.add_theme_color_override("font_color", Skin.INK)
		slot.add_theme_stylebox_override("hover", make_style(Color("bcb092"), Skin.OXIDE))
		slot.add_theme_stylebox_override("pressed", make_style(Color("a59a7d"), Skin.LEATHER))
		slot.add_theme_stylebox_override("focus", make_style(Color(0, 0, 0, 0), Skin.INK))
		slot.add_theme_stylebox_override("disabled", make_style(Color("968c74"), Color("756c5b")))
		slot.tooltip_text = "Empty pocket"
		grid.add_child(slot)
		var quantity := make_label("", 15, Skin.PAPER_LIGHT)
		quantity.name = "Quantity"
		quantity.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		quantity.offset_right = -5
		quantity.offset_bottom = -3
		quantity.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		quantity.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		quantity.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
		quantity.add_theme_constant_override("shadow_offset_x", 1)
		quantity.add_theme_constant_override("shadow_offset_y", 2)
		slot.add_child(quantity)
		if id.is_empty():
			slot.disabled = true
		else:
			var key := id
			slot.pressed.connect(func(): select_item(key))
			var icon_path := "res://assets/items/icons/" + id + ".png"
			if ResourceLoader.exists(icon_path): item_icons[id] = load(icon_path)
			item_buttons[id] = slot
			count_labels[id] = quantity
	selected_title = make_label("Select an item", 17, TEXT)
	layout.add_child(selected_title)
	item_details = make_label("", 13, MUTED)
	item_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item_details.custom_minimum_size = Vector2(550, 42)
	layout.add_child(item_details)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	layout.add_child(actions)
	equip_button = make_action("CARRY", func(): game.equip_inventory_item(selected_id); refresh())
	use_button = make_action("USE", func(): game.use_inventory_item(selected_id); refresh())
	stow_button = make_action("STOW", func(): game.equip_inventory_item(""); refresh())
	actions.add_child(equip_button)
	actions.add_child(use_button)
	actions.add_child(stow_button)
	feedback = make_label("Keep what you can carry. Leave room for the road home.", 13, MUTED)
	feedback.custom_minimum_size.y = 20
	layout.add_child(feedback)
	hide()

func select_item(id: String) -> void:
	if not Items.ITEMS.has(id) or game.inventory.get(id, 0) <= 0:
		return
	selected_id = id
	game.inventory_feedback = ""
	refresh()

func refresh() -> void:
	for id in Items.ORDER:
		var slot: Button = item_buttons[id]
		var quantity: int = game.inventory.get(id, 0)
		var available := quantity > 0
		slot.disabled = not available
		slot.icon = item_icons.get(id) if available else null
		slot.tooltip_text = str(Items.entry(id).get("description", "")) if available else "Empty pocket"
		count_labels[id].text = str(quantity) if available else ""
		var selected: bool = available and id == selected_id
		slot.add_theme_stylebox_override("normal", make_style(Color("a99c7a") if selected else Color("88806b"), Skin.RUST if selected else Color("534d3e"), 3 if selected else 2))
	if game.inventory.get(selected_id, 0) <= 0:
		selected_id = ""
	var data: Dictionary = Items.entry(selected_id)
	var available := not data.is_empty()
	selected_title.text = (str(data.get("name", "")) + "   ×" + str(game.inventory.get(selected_id, 0))) if available else "Select an item"
	item_details.text = (str(data.get("category", "")) + "  /  " + str(data.get("effect", "")) + "  /  %.2f KG\n" % float(data.get("mass", 0.0)) + str(data.get("description", ""))) if available else "Search the world for supplies, instruments and recovered equipment."
	carry_status.text = "TIME OUT  /  %02d:%02d    LOAD  /  %.2f KG    IN HAND  /  %s" % [int(game.elapsed / 60.0), int(game.elapsed) % 60, Items.total_mass(game.inventory), str(Items.entry(game.equipped_item_id).get("name", "Empty hand"))]
	equip_button.disabled = not available or game.equipped_item_id == selected_id
	equip_button.text = "CARRYING" if available and game.equipped_item_id == selected_id else "CARRY"
	use_button.disabled = not available
	use_button.tooltip_text = str(data.get("effect", ""))
	stow_button.disabled = game.equipped_item_id.is_empty()
	feedback.text = game.inventory_feedback if not game.inventory_feedback.is_empty() else "Select a recovered item from your field pack."

func open_pack() -> void:
	show()
	if is_instance_valid(game.hud.interface_foley):
		game.hud.interface_foley.call("cloth")
	var preferred: String = game.equipped_item_id if not game.equipped_item_id.is_empty() else selected_id
	if game.inventory.get(preferred, 0) <= 0:
		preferred = ""
		for id in Items.ORDER:
			if game.inventory.get(id, 0) > 0:
				preferred = id
				break
	selected_id = preferred
	game.inventory_feedback = ""
	refresh()

func close_pack() -> void:
	if visible and is_instance_valid(game.hud.interface_foley):
		game.hud.interface_foley.call("latch")
	hide()
