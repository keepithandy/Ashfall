extends Node3D
## Crossroads 2.3 environment-first playtest. The old Station 04 objective
## world stays archived and unchanged. Here: absolutely no generator,
## anomaly, sample, loot economy, extraction gate, enemy AI or story triggers.
const PLAYER = preload("res://scripts/runtime/player.gd")
const AUDIO = preload("res://scripts/runtime/audio_settings.gd")
const PROFILE = preload("res://scripts/crossroads/crossroads_profile.gd")
var heightmap = PROFILE.new()
var player: CharacterBody3D
var survival_rules: Node = null  # The reused player keeps original movement.
var started := false
var menu: Control
var cover: ColorRect
var resume_button: Button
var fps_label: Label
var showing_fps := false
var smoke_test := false


func _ready() -> void:
    name = "Crossroads"
    smoke_test = "--smoke-test" in OS.get_cmdline_user_args()
    AUDIO.new().setup()
    _bind_input()
    _spawn_walker()
    _menu_ui()
    get_window().focus_exited.connect(_on_focus_lost)
    if smoke_test:
        start_walking.call_deferred()


func _spawn_walker() -> void:
    player = CharacterBody3D.new()
    player.name = "Walker"
    player.set_script(PLAYER)
    # Start on the south road, far enough from every gate and building.
    var z := 183.0
    var x := heightmap.main_road_x(z)
    player.position = Vector3(x, heightmap.surface_height_at(x, z) + 0.2, z)
    add_child(player)
    player.camera.far = 650.0
    player.set_view_direction(Vector3(0.04, -0.03, -1.0))
    player.torch.visible = false


func _bind_input() -> void:
    var keys := {
        "move_forward": KEY_W, "move_back": KEY_S,
        "move_left": KEY_A, "move_right": KEY_D,
        "sprint": KEY_SHIFT, "crouch": KEY_CTRL,
        "jump": KEY_SPACE, "flashlight": KEY_F
    }
    for action in keys:
        if not InputMap.has_action(action):
            InputMap.add_action(action)
        var event := InputEventKey.new()
        event.physical_keycode = keys[action]
        if not InputMap.action_has_event(action, event):
            InputMap.action_add_event(action, event)


func _ui_label(text_value: String, font_size: int, color: Color) -> Label:
    var label := Label.new()
    label.text = text_value
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", color)
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    return label


func _menu_ui() -> void:
    var layer := CanvasLayer.new()
    layer.name = "WalkthroughDisplay"
    layer.layer = 5
    add_child(layer)
    menu = Control.new()
    menu.name = "PauseCard"
    menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    layer.add_child(menu)
    cover = ColorRect.new()
    cover.color = Color(0.04, 0.045, 0.037, 0.94)
    cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    cover.mouse_filter = Control.MOUSE_FILTER_STOP
    menu.add_child(cover)
    var center := CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    cover.add_child(center)
    var shell := PanelContainer.new()
    shell.name = "CanvasCover"
    var panel_style := StyleBoxFlat.new()
    panel_style.bg_color = Color("26271f")
    panel_style.border_color = Color("70695a")
    panel_style.set_border_width_all(2)
    panel_style.set_content_margin_all(25)
    shell.add_theme_stylebox_override("panel", panel_style)
    center.add_child(shell)
    var sheet := VBoxContainer.new()
    sheet.add_theme_constant_override("separation", 16)
    sheet.custom_minimum_size = Vector2(540, 0)
    shell.add_child(sheet)
    var eyebrow := _ui_label("A PLACE TO WALK    /    NO OBJECTIVES", 13, Color("ad9c80"))
    sheet.add_child(eyebrow)
    var heading := _ui_label("CROSSROADS", 46, Color("e5ddca"))
    sheet.add_child(heading)
    var copy := _ui_label(
        "A forgotten stretch of country. The houses are empty.\nThere is no task to complete. Walk the road, enter the yards,\nand see whether this feels like somewhere real.\n\nWASD / mouse  •  Shift sprint  •  Ctrl crouch\nSpace jump  •  F torch  •  Esc pause\nF7 FPS  •  F8 draw distance",
        17, Color("c5baa3"))
    copy.custom_minimum_size = Vector2(510, 180)
    sheet.add_child(copy)
    resume_button = Button.new()
    resume_button.text = "WALK THE ROAD"
    resume_button.custom_minimum_size = Vector2(280, 48)
    var button_style := StyleBoxFlat.new()
    button_style.bg_color = Color("575440")
    button_style.border_color = Color("867960")
    button_style.set_border_width_all(2)
    resume_button.add_theme_stylebox_override("normal", button_style)
    var hovered := button_style.duplicate() as StyleBoxFlat
    hovered.bg_color = Color("706b51")
    resume_button.add_theme_stylebox_override("hover", hovered)
    resume_button.add_theme_color_override("font_color", Color("e8e0ca"))
    resume_button.pressed.connect(start_walking)
    sheet.add_child(resume_button)
    fps_label = _ui_label("", 14, Color("d7d0bd"))
    fps_label.name = "OptionalFPS"
    fps_label.position = Vector2(22, 20)
    fps_label.size = Vector2(380, 36)
    fps_label.visible = false
    fps_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    layer.add_child(fps_label)
    if smoke_test:
        cover.hide()


func start_walking() -> void:
    started = true
    cover.hide()
    player.active = true
    if not smoke_test and DisplayServer.get_name() != "headless":
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func pause_walking() -> void:
    if not started or not player.active:
        return
    player.active = false
    player.velocity = Vector3.ZERO
    resume_button.text = "BACK TO THE ROAD"
    cover.show()
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_focus_lost() -> void:
    # The dummy/headless display has no actual window focus. Treating its
    # synthetic focus events as user alt-tabs silently disables the walker.
    if not smoke_test and DisplayServer.get_name() != "headless":
        pause_walking()


func _unhandled_key_input(event: InputEvent) -> void:
    if not event is InputEventKey or not event.pressed or event.echo:
        return
    if event.physical_keycode == KEY_ESCAPE and started:
        if player.active:
            pause_walking()
        else:
            start_walking()
        get_viewport().set_input_as_handled()
    elif event.physical_keycode == KEY_F7:
        showing_fps = not showing_fps
        fps_label.visible = showing_fps
        get_viewport().set_input_as_handled()
    elif event.physical_keycode == KEY_F8 and is_instance_valid(player):
        player.camera.far = 350.0 if player.camera.far > 500.0 else (500.0 if player.camera.far < 400.0 else 650.0)
        get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
    if showing_fps and is_instance_valid(player):
        fps_label.text = "%d FPS  /  %dm view  /  CROSSROADS" % [
            Engine.get_frames_per_second(), int(player.camera.far)
        ]
    if not is_instance_valid(player) or not player.active:
        return
    # Terrain extends to the forest border. Recover from falling off the
    # physical mesh during early map iteration without altering save data.
    if player.position.y < -16.0:
        var z := 183.0
        var x := heightmap.main_road_x(z)
        player.velocity = Vector3.ZERO
        player.position = Vector3(x, heightmap.surface_height_at(x, z) + 0.3, z)
