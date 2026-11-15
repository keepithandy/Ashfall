extends Node3D
## Briar Creek independent walkabout controller. Reuses Ashfall's character
## movement but does not attach the old objective/save/encounter runtime.
const PLAYER = preload("res://scripts/runtime/player.gd")
const AUDIO = preload("res://scripts/runtime/audio_settings.gd")
const PROFILE = preload("res://scripts/briar_creek/briar_creek_profile.gd")
var profile=PROFILE.new()
var player: CharacterBody3D
var survival_rules: Node = null
var paused := true
var smoke_test := false
var menu: Control
var cover: ColorRect
var status: Label

func _ready() -> void:
    smoke_test="--smoke-test" in OS.get_cmdline_user_args()
    AUDIO.new().setup()
    _bind_input()
    _spawn_player()
    _make_ui()
    var overview := get_node_or_null("../TerrainPlan/PlanCamera") as Camera3D
    if overview != null:
        overview.current=false
    var markers := get_node_or_null("../TerrainPlan/Generated/SiteFootprintMarkers") as Node3D
    if markers != null:
        markers.hide()
    if smoke_test:
        _resume()

func _bind_input() -> void:
    var bindings := {
        "move_forward":KEY_W, "move_back":KEY_S,
        "move_left":KEY_A, "move_right":KEY_D,
        "sprint":KEY_SHIFT, "crouch":KEY_CTRL,
        "jump":KEY_SPACE, "flashlight":KEY_F
    }
    for action in bindings.keys():
        if not InputMap.has_action(action):
            InputMap.add_action(action)
        var key := InputEventKey.new()
        key.physical_keycode=bindings[action]
        if not InputMap.action_has_event(action,key):
            InputMap.action_add_event(action,key)

func _spawn_player() -> void:
    player=CharacterBody3D.new()
    player.name="Walker"
    player.set_script(PLAYER)
    var at := profile.to_world(305.0,44.0)
    at.y=profile.surface_height_at(at.x,at.z)+0.4
    player.position=at
    add_child(player)
    player.camera.far=450.0
    player.camera.current=true
    player.set_view_direction(Vector3(0.01,-0.03,-1.0))
    player.torch.visible=false

func _make_ui() -> void:
    var layer := CanvasLayer.new()
    layer.name="WalkthroughHUD"
    add_child(layer)
    status=Label.new()
    status.name="AreaStatus"
    status.position=Vector2(24,18)
    status.text="BRIAR CREEK  /  AREA 02  /  ENVIRONMENT WALKABOUT"
    status.add_theme_font_size_override("font_size",15)
    status.add_theme_color_override("font_color",Color("d4d1c5"))
    status.mouse_filter=Control.MOUSE_FILTER_IGNORE
    layer.add_child(status)
    menu=Control.new()
    menu.name="PausePanel"
    menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    menu.mouse_filter=Control.MOUSE_FILTER_IGNORE
    layer.add_child(menu)
    cover=ColorRect.new()
    cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    cover.color=Color(0.045,0.056,0.049,0.94)
    cover.mouse_filter=Control.MOUSE_FILTER_STOP
    menu.add_child(cover)
    var center := CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    cover.add_child(center)
    var panel := PanelContainer.new()
    center.add_child(panel)
    var column := VBoxContainer.new()
    column.custom_minimum_size=Vector2(480,230)
    column.add_theme_constant_override("separation",18)
    panel.add_child(column)
    var heading := Label.new()
    heading.text="BRIAR CREEK"
    heading.add_theme_font_size_override("font_size",39)
    column.add_child(heading)
    var detail := Label.new()
    detail.text="AREA 02  /  LOGGING DISTRICT WALKABOUT\n\nExplore the southern checkpoint, mill, cabin terraces and depot.\nWASD move • Mouse look • Shift sprint • Ctrl crouch\nSpace jump • F flashlight • Esc pause\n\nEnvironment-only development scene. No save, loot or travel link yet."
    detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    detail.add_theme_font_size_override("font_size",15)
    column.add_child(detail)
    var button := Button.new()
    button.text="ENTER BRIAR CREEK"
    button.custom_minimum_size=Vector2(260,45)
    button.pressed.connect(_resume)
    column.add_child(button)
    if smoke_test:
        cover.hide()

func _resume() -> void:
    paused=false
    cover.hide()
    player.active=true
    if not smoke_test and DisplayServer.get_name()!="headless":
        Input.mouse_mode=Input.MOUSE_MODE_CAPTURED

func _pause() -> void:
    paused=true
    player.active=false
    player.velocity=Vector3.ZERO
    cover.show()
    Input.mouse_mode=Input.MOUSE_MODE_VISIBLE

func _unhandled_key_input(event: InputEvent) -> void:
    if not event is InputEventKey or not event.pressed or event.echo:
        return
    if event.physical_keycode==KEY_ESCAPE:
        if paused:
            _resume()
        else:
            _pause()
        get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
    if not is_instance_valid(player):
        return
    if player.position.y < -25.0:
        var at := profile.to_world(305.0,44.0)
        at.y=profile.surface_height_at(at.x,at.z)+0.4
        player.velocity=Vector3.ZERO
        player.position=at
