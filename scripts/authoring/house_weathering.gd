@tool
extends Node3D
## Optional, no-collision architectural aging for Station 04 homes.
## Intentionally leaves original structural nodes, doorways and physics untouched.

@export_enum("Longhouse", "Workers house", "Garden house", "Porch cottage", "Northern cottage")
var house_style := 0:
    set(value):
        house_style = value
        _rebuild()

@export_range(0.0, 1.0, 0.01) var weathering := 0.68:
    set(value):
        weathering = value
        _rebuild()

const PALE_WOOD := Color(0.29, 0.25, 0.20)
const DARK_METAL := Color(0.16, 0.19, 0.19)
const RUST := Color(0.29, 0.15, 0.10)
const CHALK := Color(0.46, 0.44, 0.37)

func _ready() -> void:
    _rebuild()

func _material(tint: Color, metallic := 0.0) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = tint
    m.roughness = 0.91 if metallic < 0.2 else 0.76
    m.metallic = metallic
    return m

func _beam(label: String, at: Vector3, size: Vector3, mat: Material, angle := 0.0) -> void:
    var visual := MeshInstance3D.new()
    visual.name = label
    var mesh := BoxMesh.new()
    mesh.size = size
    visual.mesh = mesh
    visual.material_override = mat
    visual.position = at
    visual.rotation.z = angle
    visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
    add_child(visual)
    if Engine.is_editor_hint():
        visual.owner = get_tree().edited_scene_root

func _rebuild() -> void:
    if not is_inside_tree():
        return
    for child in get_children():
        child.free()

    var timber := _material(PALE_WOOD.lerp(Color(0.21, 0.20, 0.18), weathering))
    var iron := _material(DARK_METAL, 0.65)
    var oxide := _material(RUST, 0.35)
    var plaster := _material(CHALK)

    match house_style:
        0: # Longhouse: continuous sagging fascia and repaired roof edging.
            for side in [-1.0, 1.0]:
                for segment in range(7):
                    var z := -3.35 + float(segment) * 1.12
                    _beam("Fascia_%s_%d" % [str(side), segment], Vector3(side * 3.36, 3.99 - (0.018 if segment % 3 == 0 else 0.0), z), Vector3(0.085, 0.14, 1.05), timber)
                _beam("Gutter_%s" % str(side), Vector3(side * 3.48, 3.82, 0), Vector3(0.13, 0.12, 7.6), iron)
            _beam("Downpipe", Vector3(3.50, 2.0, 3.35), Vector3(0.11, 3.5, 0.11), oxide)
        1: # Workers house: utility conduit, rusted gutters and patch repairs.
            for side in [-1.0, 1.0]:
                _beam("Gutter_%s" % str(side), Vector3(side * 2.56, 3.85, 0), Vector3(0.13, 0.13, 8.35), oxide)
                for i in range(5):
                    _beam("Bracket_%s_%d" % [str(side), i], Vector3(side * 2.56, 3.78, -3.65 + i * 1.8), Vector3(0.24, 0.16, 0.08), iron)
            _beam("ServiceConduit", Vector3(3.99, 2.25, 1.5), Vector3(0.065, 2.55, 0.065), iron)
            _beam("WallPatch", Vector3(4.005, 1.4, 2.45), Vector3(0.035, 0.86, 0.75), plaster)
        2: # Garden house: restrained chalked fascias and rainwater collection.
            for side in [-1.0, 1.0]:
                _beam("Fascia_%s" % str(side), Vector3(side * 2.75, 3.96, 0), Vector3(0.095, 0.17, 10.35), timber)
                _beam("RainGutter_%s" % str(side), Vector3(side * 2.83, 3.83, 0), Vector3(0.10, 0.10, 10.5), iron)
            _beam("Rainpipe", Vector3(2.91, 2.04, -4.85), Vector3(0.10, 3.4, 0.10), iron)
            _beam("DrainElbow", Vector3(2.77, 0.35, -4.85), Vector3(0.32, 0.09, 0.10), oxide)
        3: # Porch cottage: exposed porch edging, not obstructing entrance.
            for i in range(6):
                _beam("PorchEdge_%d" % i, Vector3(-2.7 + i * 1.05, 0.30, 3.3), Vector3(0.93, 0.09, 0.12), timber)
            _beam("PorchGutter", Vector3(0, 3.26, 3.55), Vector3(6.4, 0.11, 0.11), iron)
        4: # Northern cottage: rusted eave flashing and end-wall runoff.
            for side in [-1.0, 1.0]:
                _beam("RoofFlashing_%s" % str(side), Vector3(side * 3.10, 4.85, 0), Vector3(0.12, 0.11, 7.2), oxide)
            _beam("VerticalDownpipe", Vector3(3.16, 2.9, 3.35), Vector3(0.11, 3.9, 0.11), iron)
