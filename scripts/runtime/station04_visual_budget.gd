extends Node
## Station 04 renderer-budget options and optional live diagnostics.
## No gameplay balance, collision, save data or other level camera is touched.

const VIEW_RANGES := [900.0, 650.0, 400.0]
const FOLIAGE_RANGES := [90.0, 75.0, 45.0]
const VIEW_NAMES := ["LONG VIEW", "BALANCED", "PERFORMANCE"]

var game: Node3D
var scene_detail: Node3D
var mode: int = 0
var diagnostics: bool = false
var monitor_label: Label
var world_environment: WorldEnvironment
var source_sun: DirectionalLight3D
var source_energy: float = 1.0
var base_fog_density: float = 0.0
var base_volumetric_density: float = 0.0
var clock := 0.0
var redraw_timer := 0.0


func _ready() -> void:
    name = "Station04VisualBudget"
    if game == null:
        return
    var environments := game.find_children("*", "WorldEnvironment", true, false)
    if not environments.is_empty():
        world_environment = environments[0] as WorldEnvironment
        # Weather and quality settings must never modify imported/shared assets.
        if world_environment.environment != null:
            world_environment.environment = world_environment.environment.duplicate()
            base_fog_density = world_environment.environment.fog_density
            base_volumetric_density = world_environment.environment.volumetric_fog_density
    var suns := game.find_children("*", "DirectionalLight3D", true, false)
    if not suns.is_empty():
        source_sun = suns[0] as DirectionalLight3D
        source_energy = source_sun.light_energy
    var layer := CanvasLayer.new()
    layer.layer = 7
    layer.name = "DiagnosticOverlay"
    add_child(layer)
    monitor_label = Label.new()
    monitor_label.position = Vector2(440.0, 78.0)
    monitor_label.add_theme_font_size_override("font_size", 13)
    monitor_label.add_theme_color_override("font_color", Color("dce5d5"))
    monitor_label.add_theme_color_override("font_shadow_color", Color.BLACK)
    monitor_label.add_theme_constant_override("shadow_offset_x", 1)
    monitor_label.add_theme_constant_override("shadow_offset_y", 1)
    monitor_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    monitor_label.hide()
    layer.add_child(monitor_label)
    set_view_mode(0)


func _input(event: InputEvent) -> void:
    if not event is InputEventKey or not event.pressed or event.echo:
        return
    if not is_instance_valid(game) or not game.started or not game.player.active:
        return
    if event.physical_keycode == KEY_F8:
        set_view_mode((mode + 1) % VIEW_RANGES.size())
        game.show_message("VIEW BUDGET / " + VIEW_NAMES[mode] + " / " + str(int(VIEW_RANGES[mode])) + " METRES", 4.0)
        get_viewport().set_input_as_handled()
    elif event.physical_keycode == KEY_F7:
        diagnostics = not diagnostics
        monitor_label.visible = diagnostics
        get_viewport().set_input_as_handled()


func set_view_mode(value: int) -> void:
    mode = clampi(value, 0, VIEW_RANGES.size() - 1)
    if is_instance_valid(game.player) and is_instance_valid(game.player.camera):
        game.player.camera.far = VIEW_RANGES[mode]
    if is_instance_valid(scene_detail):
        scene_detail.foliage_view_range = FOLIAGE_RANGES[mode]
        for visual in scene_detail.find_children("*", "GeometryInstance3D", true, false):
            if visual.get_parent() != null and visual.get_parent().get_meta("ashfall_visual_only", false):
                visual.visibility_range_end = FOLIAGE_RANGES[mode]
    if is_instance_valid(world_environment) and world_environment.environment != null:
        world_environment.environment.volumetric_fog_enabled = mode != 2


func _process(delta: float) -> void:
    if not is_instance_valid(game) or not game.started:
        return
    clock += delta
    # Very slow weather modulation, bounded to retain authored fog visibility.
    var broad := sin(clock * 0.008 + 1.7) * 0.5 + sin(clock * 0.019) * 0.22
    if is_instance_valid(world_environment) and world_environment.environment != null:
        var env := world_environment.environment
        env.fog_density = base_fog_density * (1.0 + broad * 0.08)
        env.volumetric_fog_density = base_volumetric_density * (1.0 + broad * 0.1)
    if is_instance_valid(source_sun):
        source_sun.light_energy = source_energy * (1.0 - broad * 0.05)
    if not diagnostics:
        return
    redraw_timer -= delta
    if redraw_timer > 0.0:
        return
    redraw_timer = 0.5
    monitor_label.text = "ASHFALL / LIVE RENDER CHECK\nFPS  %03d  /  VIEW %dm\nMODE  %s" % [
        int(Engine.get_frames_per_second()),
        int(VIEW_RANGES[mode]),
        VIEW_NAMES[mode]
    ]
