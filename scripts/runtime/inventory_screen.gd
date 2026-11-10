extends Control
## A simple slot inventory; the gameplay item and hand systems remain unchanged.
const Items = preload("res://scripts/runtime/item_catalog.gd")
const SLOT_COUNT := 27
const COLUMNS := 9
const SLOT_SIZE := 64
const TEXT := Color("272c29")
const MUTED := Color("525a52")

var game: Node3D
var selected_id := "flashlight"
var item_buttons: Dictionary = {}
var count_labels: Dictionary = {}
var item_icons: Dictionary = {}
var selected_title: Label
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
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_color_override("font_disabled_color", Color("777e76"))
	button.add_theme_stylebox_override("normal", make_style(Color("d2d4c9"), Color("777e73")))
	button.add_theme_stylebox_override("hover", make_style(Color("e7e8dc"), Color("424c42")))
	button.add_theme_stylebox_override("pressed", make_style(Color("aeb5a8"), Color("424c42")))
	button.add_theme_stylebox_override("focus", make_style(Color(0, 0, 0, 0), Color("344a36")))
	button.add_theme_stylebox_override("disabled", make_style(Color("b3b9ad"), Color("989e94")))
	button.pressed.connect(action)
	return button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0.01, 0.015, 0.012, 0.76)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.name = "InventoryPanel"
	panel.add_theme_stylebox_override("panel", make_style(Color("c7ccc0"), Color("515b50"), 4))
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	panel.add_child(margin)
	var layout := VBoxContainer.new()
	layout.custom_minimum_size.x = 608
	layout.add_theme_constant_override("separation", 12)
	margin.add_child(layout)
	var header := HBoxContainer.new()
	layout.add_child(header)
	var title := make_label("INVENTORY", 24, TEXT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close := make_action("CLOSE  /  TAB", func(): game.close_inventory())
	close.custom_minimum_size = Vector2(145, 36)
	header.add_child(close)
	carry_status = make_label("", 14, MUTED)
	layout.add_child(carry_status)
	var grid := GridContainer.new()
	grid.name = "Slots"
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", 3)
	grid.add_theme_constant_override("v_separation", 3)
	layout.add_child(grid)
	for index in SLOT_COUNT:
		var id: String = Items.ORDER[index] if index < Items.ORDER.size() else ""
		var slot := Button.new()
		slot.name = "Slot%02d" % (index + 1)
		slot.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
		slot.expand_icon = true
		slot.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot.add_theme_constant_override("icon_max_width", 51)
		slot.add_theme_stylebox_override("normal", make_style(Color("8f998a"), Color("667263")))
		slot.add_theme_stylebox_override("hover", make_style(Color("b1bbab"), Color("edf0df")))
		slot.add_theme_stylebox_override("pressed", make_style(Color("a3ae9e"), Color("f1f3e8")))
		slot.add_theme_stylebox_override("focus", make_style(Color(0, 0, 0, 0), Color("f1f3e8")))
		slot.add_theme_stylebox_override("disabled", make_style(Color("a0a99a"), Color("7e897b")))
		grid.add_child(slot)
		var quantity := make_label("", 15, Color("f9f8eb"))
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
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	layout.add_child(actions)
	equip_button = make_action("CARRY", func(): game.equip_inventory_item(selected_id); refresh())
	use_button = make_action("USE", func(): game.use_inventory_item(selected_id); refresh())
	stow_button = make_action("STOW", func(): game.equip_inventory_item(""); refresh())
	actions.add_child(equip_button)
	actions.add_child(use_button)
	actions.add_child(stow_button)
	feedback = make_label("Click an item to select it.", 13, MUTED)
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
		slot.tooltip_text = Items.entry(id).name if available else ""
		count_labels[id].text = str(quantity) if available else ""
		var selected: bool = available and id == selected_id
		slot.add_theme_stylebox_override("normal", make_style(Color("9da994") if selected else Color("8f998a"), Color("f1f3e8") if selected else Color("667263"), 3 if selected else 2))
	if game.inventory.get(selected_id, 0) <= 0:
		selected_id = ""
	var data: Dictionary = Items.entry(selected_id)
	var available := not data.is_empty()
	selected_title.text = (data.get("name", "") + "   ×" + str(game.inventory.get(selected_id, 0))) if available else "Select an item"
	carry_status.text = "IN HAND: " + str(Items.entry(game.equipped_item_id).get("name", "Empty hand"))
	equip_button.disabled = not available or game.equipped_item_id == selected_id
	equip_button.text = "CARRYING" if available and game.equipped_item_id == selected_id else "CARRY"
	use_button.disabled = not available
	use_button.tooltip_text = str(data.get("effect", ""))
	stow_button.disabled = game.equipped_item_id.is_empty()
	feedback.text = game.inventory_feedback if not game.inventory_feedback.is_empty() else "Click an item to select it."

func open_pack() -> void:
	show()
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
	hide()
