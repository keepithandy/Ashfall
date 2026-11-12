extends Control
## Weather-beaten paper field notes. Current-expedition discoveries only.
const Skin = preload("res://scripts/runtime/weathered_ui_style.gd")
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
     "detail": "The northern lab was abandoned with instruments still running. The sample should be recovered only if the entry gate remains accessible."},
    {"id": "memorial", "at": Vector2(-12.0, 65.0), "radius": 7.5,
     "title": "ROADSIDE MEMORIAL",
     "detail": "Someone kept returning here long after the evacuation. The marker has no name; someone else stripped the metal tag."},
    {"id": "shelter", "at": Vector2(53.0, 47.0), "radius": 9.0,
     "title": "THE LAST BUS",
     "detail": "A shelter without its roof and a road with no buses. Timetables are still pinned beneath the broken frame."},
    {"id": "utility", "at": Vector2(53.0, -47.0), "radius": 9.0,
     "title": "SNAPPED TRANSMISSION",
     "detail": "The utility pole fell toward the perimeter, not away from it. The line was cut before the station lights failed."},
    {"id": "mailbox", "at": Vector2(-62.0, -49.0), "radius": 7.0,
     "title": "UNCLAIMED MAIL",
     "detail": "A mailbox sits at the forest edge. The house it served is no longer standing."},
    {"id": "washing", "at": Vector2(-49.0, 63.0), "radius": 7.0,
     "title": "LAUNDRY ON THE LINE",
     "detail": "The washing was left to dry. Nobody took it down when the road was closed. There is still a chair beside the empty garden."},
    {"id": "yard_cable", "at": Vector2(56.0, -29.0), "radius": 8.0,
     "title": "UNFINISHED REPAIR",
     "detail": "A cable tray sits where the workers dropped it. The drainage ditch and broken steel may hide a way around the service road."},
    {"id": "table", "at": Vector2(67.0, 54.0), "radius": 7.5,
     "title": "LAST ROADSIDE STOP",
     "detail": "A rotten picnic table faces the abandoned shelter. It is too far from the houses to have been anyone's garden."}
]


var game: Node3D
var unlocked: Dictionary = {"deployment": true}
var shade: ColorRect
var frame: PanelContainer
var heading: Label
var content: RichTextLabel
var footer: Label
var close_button: Button
var paper := Skin.PAPER_LIGHT
var muted := Skin.FADED_INK
var accent := Skin.RUST


func _ready() -> void:
    name = "ExpeditionFieldRecord"
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    shade = ColorRect.new()
    shade.name = "WeatheredCanvas"
    shade.color = Color(0.035, 0.038, 0.031, 0.94)
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    shade.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(shade)
    var center := CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    shade.add_child(center)
    frame = PanelContainer.new()
    frame.name = "WornNotebookCover"
    frame.add_theme_stylebox_override("panel", Skin.panel(Skin.LEATHER, Skin.THREAD, 3, 10))
    center.add_child(frame)
    var page := PanelContainer.new()
    page.name = "StainedPaper"
    page.add_theme_stylebox_override("panel", Skin.panel(Skin.PAPER, Skin.PAPER_DARK, 2, 16))
    frame.add_child(page)
    Skin.paper_texture(page, true)
    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 30)
    margin.add_theme_constant_override("margin_right", 15)
    margin.add_theme_constant_override("margin_top", 17)
    margin.add_theme_constant_override("margin_bottom", 16)
    page.add_child(margin)
    var stack := VBoxContainer.new()
    stack.add_theme_constant_override("separation", 13)
    margin.add_child(stack)
    var preface := Label.new()
    preface.text = "PRIVATE PROPERTY     /     IF FOUND, LEAVE AT THE SOUTH GATE"
    Skin.ink_label(preface, false, true)
    preface.add_theme_font_size_override("font_size", 11)
    stack.add_child(preface)
    var top := HBoxContainer.new()
    stack.add_child(top)
    heading = Label.new()
    heading.text = "THE FIELD NOTEBOOK"
    heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    Skin.ink_label(heading, true)
    top.add_child(heading)
    close_button = Button.new()
    close_button.name = "CloseFieldRecord"
    close_button.text = "PUT AWAY  /  J"
    close_button.custom_minimum_size = Vector2(132, 40)
    Skin.control_button(close_button, true)
    close_button.pressed.connect(close_record)
    top.add_child(close_button)
    var separator := HSeparator.new()
    stack.add_child(separator)
    var section := Label.new()
    section.text = "ROUTE NOTES   /   STATION 04"
    Skin.ink_label(section, false, true)
    stack.add_child(section)
    content = RichTextLabel.new()
    content.name = "Pages"
    content.fit_content = false
    content.scroll_active = true
    content.custom_minimum_size = Vector2(390, 225)
    content.size_flags_vertical = Control.SIZE_EXPAND_FILL
    content.add_theme_font_size_override("normal_font_size", 16)
    content.add_theme_color_override("default_color", Skin.INK)
    content.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
    content.add_theme_constant_override("line_separation", 6)
    stack.add_child(content)
    footer = Label.new()
    footer.text = "PENCIL MARKS  /  OBSERVATIONS FROM THIS EXPEDITION ONLY"
    footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    Skin.ink_label(footer, false, true)
    footer.add_theme_font_size_override("font_size", 11)
    stack.add_child(footer)
    resized.connect(_resize_record)
    _resize_record()
    set_palette(paper, muted, accent)
    _refresh()
    hide()


func _resize_record() -> void:
    if is_instance_valid(frame):
        frame.custom_minimum_size = Vector2(minf(760.0, maxf(530.0, size.x - 36.0)), minf(560.0, maxf(405.0, size.y - 30.0)))


func set_palette(light: Color, subdued: Color, highlight: Color) -> void:
    # Theme finishes tint only the brass/ink accents; the notebook remains
    # recognizably stained paper in every mode.
    paper = light
    muted = subdued
    accent = highlight
    if is_instance_valid(heading):
        heading.add_theme_color_override("font_color", Skin.INK)
    if is_instance_valid(footer):
        footer.add_theme_color_override("font_color", Skin.FADED_INK)
    if is_instance_valid(content):
        content.add_theme_color_override("default_color", Skin.INK)
    if is_instance_valid(close_button):
        Skin.control_button(close_button, true)


func _refresh() -> void:
    var text_value := "00  /  FIRST DAY AT THE STATION\n\nThe road in is gone quiet. Recover the sample and come back the way you came. Take only what fits in the pack. Remember where the shelter is.\n"
    var entry_num := 1
    for place in PLACES:
        if unlocked.has(place["id"]):
            text_value += "\n──────────────────────────────────\n%02d  /  %s\n\n%s\n" % [entry_num, place["title"], place["detail"]]
            entry_num += 1
    text_value += "\n──────────────────────────────────\n%02d OF %02d PLACES NOTED" % [entry_num - 1, PLACES.size()]
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
            game.show_message("NOTE ADDED  /  " + str(place["title"]) + "  /  [J] READ", 5.0)
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
