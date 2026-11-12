extends Control
## Personal expedition field notes. Discoveries are ephemeral within the
## current expedition; this does not alter the inventory or save format.
## All presentation is screen-space, not floating world labels.

const PLACES := [
    {"id": "village", "at": Vector2(-47.0, 16.0), "radius": 8.0,
     "title": "THE SHUTTERED LANE",
     "detail": "The houses face the road, but their windows face one another. Tracks end at a locked gate. Someone left supplies where they could be found."},
    {"id": "workers", "at": Vector2(-24.0, 43.0), "radius": 9.0,
     "title": "WORKERS' ROW",
     "detail": "Three residences share the southern approach. No luggage is outside. The evacuation seems to have begun before anyone was ready."},
    {"id": "ward", "at": Vector2(-24.0, -29.0), "radius": 7.0,
     "title": "NORTHERN ISOLATION WARD",
     "detail": "An ordinary cottage was pressed into service as a ward. Follow the remaining work lamps, and check corners before crossing open ground."},
    {"id": "yard", "at": Vector2(31.0, -12.0), "radius": 9.0,
     "title": "THE SERVICE YARD",
     "detail": "Maintenance equipment was left under the tower. The yard is exposed on both sides, but the scattered cover gives another route around the road."},
    {"id": "sample", "at": Vector2(-10.0, -34.0), "radius": 6.5,
     "title": "RESEARCH APPROACH",
     "detail": "The northern lab was abandoned with instruments still running. The sample should be recovered only if the entry gate remains accessible."}
]

var game: Node3D
var unlocked: Dictionary = {"deployment": true}
var shade: ColorRect
var frame: PanelContainer
var heading: Label
var content: RichTextLabel
var footer: Label
var close_button: Button
var paper := Color("e7dfcd")
var muted := Color("b2aa95")
var accent := Color("b79a6b")


func _ready() -> void:
    name = "ExpeditionFieldRecord"
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    shade = ColorRect.new()
    shade.color = Color(0.012, 0.014, 0.012, 0.9)
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    shade.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(shade)
    var center := CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    shade.add_child(center)
    frame = PanelContainer.new()
    frame.custom_minimum_size = Vector2(680, 0)
    center.add_child(frame)
    var margin := MarginContainer.new()
    for side in ["left", "right", "top", "bottom"]:
        margin.add_theme_constant_override("margin_" + side, 24)
    frame.add_child(margin)
    var stack := VBoxContainer.new()
    stack.add_theme_constant_override("separation", 12)
    margin.add_child(stack)
    var top := HBoxContainer.new()
    stack.add_child(top)
    heading = Label.new()
    heading.text = "ASHFALL  /  PERSONAL FIELD RECORD"
    heading.add_theme_font_size_override("font_size", 22)
    heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    top.add_child(heading)
    close_button = Button.new()
    close_button.text = "CLOSE  /  J"
    close_button.custom_minimum_size = Vector2(110, 38)
    close_button.pressed.connect(close_record)
    top.add_child(close_button)
    var line := HSeparator.new()
    stack.add_child(line)
    content = RichTextLabel.new()
    content.fit_content = false
    content.scroll_active = true
    content.custom_minimum_size = Vector2(590, 290)
    content.size_flags_vertical = Control.SIZE_EXPAND_FILL
    content.add_theme_font_size_override("normal_font_size", 16)
    stack.add_child(content)
    footer = Label.new()
    footer.text = "DISCOVERIES RECORDED DURING THIS EXPEDITION  /  NO CROSS-SESSION SAVE"
    footer.add_theme_font_size_override("font_size", 11)
    stack.add_child(footer)
    set_palette(paper, muted, accent)
    _refresh()
    hide()


func set_palette(light: Color, subdued: Color, highlight: Color) -> void:
    paper = light
    muted = subdued
    accent = highlight
    if not is_instance_valid(frame):
        return
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.055, 0.058, 0.050, 0.97)
    style.border_color = accent
    style.set_border_width_all(2)
    frame.add_theme_stylebox_override("panel", style)
    heading.add_theme_color_override("font_color", paper)
    footer.add_theme_color_override("font_color", muted)
    content.add_theme_color_override("default_color", paper)
    var button_style := StyleBoxFlat.new()
    button_style.bg_color = Color(0.17, 0.16, 0.13, 1)
    button_style.border_color = accent
    button_style.set_border_width_all(1)
    close_button.add_theme_stylebox_override("normal", button_style)
    close_button.add_theme_color_override("font_color", paper)


func _refresh() -> void:
    var text_value := "ENTRY 00  /  STATION 04\nFIELD DEPLOYMENT\n\nRecover the research sample and find your way back to the entry gate. Your pack is limited; your route is not.\n"
    var entry_num := 1
    for place in PLACES:
        if unlocked.has(place["id"]):
            text_value += "\n────────────────────────────────────\nENTRY %02d  /  %s\n%s\n" % [entry_num, place["title"], place["detail"]]
            entry_num += 1
    text_value += "\n────────────────────────────────────\n%02d OF %02d SURVEY LOCATIONS DOCUMENTED" % [entry_num - 1, PLACES.size()]
    if is_instance_valid(content):
        content.text = text_value


func _process(_delta: float) -> void:
    if not is_instance_valid(game) or not game.started or not is_instance_valid(game.player):
        return
    if not game.player.active or (game.areas != null and game.areas.current != "perimeter"):
        return
    var at := Vector2(game.player.global_position.x, game.player.global_position.z)
    for place in PLACES:
        if not unlocked.has(place["id"]) and at.distance_to(place["at"]) < float(place["radius"]):
            unlocked[place["id"]] = true
            _refresh()
            game.show_message("FIELD RECORD UPDATED  /  " + str(place["title"]) + "  /  [J] READ", 5.0)
            break


func _input(event: InputEvent) -> void:
    if not event is InputEventKey or not event.pressed or event.echo:
        return
    if visible and (event.physical_keycode == KEY_J or event.physical_keycode == KEY_ESCAPE):
        close_record()
        get_viewport().set_input_as_handled()
    elif event.physical_keycode == KEY_J:
        if is_instance_valid(game) and game.started and game.player.active and not game.hud.overlay.visible and not game.inventory_open and not game.hud.loot_panel.visible:
            open_record()
            get_viewport().set_input_as_handled()


func open_record() -> void:
    _refresh()
    show()
    game.player.active = false
    game.player.velocity = Vector3.ZERO
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func close_record() -> void:
    if not visible:
        return
    hide()
    if is_instance_valid(game) and game.started and not game.hud.overlay.visible:
        game.player.active = true
        if not game.smoke_test:
            Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
