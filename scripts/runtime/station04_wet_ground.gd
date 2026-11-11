@tool
extends Node3D
## Station 04 surface moisture accents, not water gameplay.
## Deliberately outside house thresholds and primary route choke points.

@export var show_wet_ground: bool = true
@export_range(0.0, 0.85, 0.05) var wet_opacity: float = 0.42

const PATCHES := [
    {"x": -7.5, "z": -14.0, "w": 2.8, "l": 1.2, "angle": -0.35},
    {"x": 6.6, "z": -28.5, "w": 2.0, "l": 3.4, "angle": 0.22},
    {"x": -8.1, "z": -38.0, "w": 3.5, "l": 1.4, "angle": 0.5},
    {"x": 39.0, "z": -24.5, "w": 2.7, "l": 1.6, "angle": 0.4},
    {"x": 43.0, "z": -6.0, "w": 2.6, "l": 1.5, "angle": 0.1},
    {"x": 33.0, "z": -25.0, "w": 2.8, "l": 1.0, "angle": -0.7},
    {"x": -39.0, "z": 10.0, "w": 2.0, "l": 1.1, "angle": -0.15},
    {"x": 12.0, "z": 61.0, "w": 3.3, "l": 1.7, "angle": 0.8},
    {"x": -36.0, "z": 51.5, "w": 2.5, "l": 1.8, "angle": 0.4}
]

func _ready() -> void:
    if show_wet_ground:
        _build()

func _build() -> void:
    if has_node("WetPatch01"):
        return
    var surface := ShaderMaterial.new()
    surface.shader = preload("res://assets/shaders/station04_wet_ground.gdshader")
    surface.set_shader_parameter("opacity", wet_opacity)
    var plane := PlaneMesh.new()
    plane.size = Vector2.ONE
    plane.material = surface
    for i in range(PATCHES.size()):
        var site: Dictionary = PATCHES[i]
        var accent := MeshInstance3D.new()
        accent.name = "WetPatch%02d" % (i + 1)
        accent.mesh = plane
        accent.position = Vector3(float(site["x"]), 0.017 + 0.0003 * float(i), float(site["z"]))
        accent.rotation.y = float(site["angle"])
        accent.scale = Vector3(float(site["w"]), 1.0, float(site["l"]))
        accent.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        add_child(accent)
