@tool
extends Node3D
## Optional, non-colliding exterior finish for the five Station 04 house scenes.
## All generated nodes are transient; existing authored architecture is preserved.
## Scene dimensions, openings, paths and gameplay collision are intentionally unchanged.

@export_enum("Green longhouse", "Ochre workers house", "White garden house", "Blue porch cottage", "Northern cottage")
var house_style := 0:
    set(value):
        house_style = value
        _rebuild()

@export_range(0.0, 1.0, 0.05)
var weathering := 0.70:
    set(value):
        weathering = value
        _rebuild()

const TIMBER_BASE := Color(0.43, 0.39, 0.32)
const IRON_BASE := Color(0.19, 0.21, 0.21)
const OXIDE_BASE := Color(0.31, 0.18, 0.12)
const PALE_PLASTER := Color(0.48, 0.46, 0.39)

func _ready() -> void:
    _rebuild()

func _material(color: Color, metallic := 0.0, texture_path := "") -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.metallic = metallic
    m.roughness = 0.95 if metallic < 0.2 else 0.80
    if not texture_path.is_empty():
        var texture := load(texture_path) as Texture2D
        if texture != null:
            m.albedo_texture = texture
            m.uv1_triplanar = true
            m.uv1_world_triplanar = true
            m.uv1_scale = Vector3.ONE * 0.85
    return m

func _generated(mesh: PrimitiveMesh, label: String, location: Vector3, mat: Material, euler := Vector3.ZERO) -> void:
    var visual := MeshInstance3D.new()
    visual.name = label
    visual.mesh = mesh
    visual.material_override = mat
    visual.position = location
    visual.rotation = euler
    visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
    visual.set_meta("ashfall_generated_weathering", true)
    add_child(visual)
    # Do not assign owner: @tool provides preview but changes never bake duplicate
    # nodes into the source house. Generated parts rebuild on scene instantiation.

func _beam(label: String, location: Vector3, size: Vector3, mat: Material, tilt := Vector3.ZERO) -> void:
    var mesh := BoxMesh.new()
    mesh.size = size
    _generated(mesh, label, location, mat, tilt)

func _pipe(label: String, location: Vector3, radius: float, length: float, mat: Material, sideways := false) -> void:
    var mesh := CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = length
    mesh.radial_segments = 10
    _generated(mesh, label, location, mat, Vector3(0.0, 0.0, PI * 0.5 if sideways else 0.0))

func _rebuild() -> void:
    if not is_inside_tree():
        return
    for child in get_children():
        if child.get_meta("ashfall_generated_weathering", false):
            child.free()

    var timber := _material(TIMBER_BASE.lerp(Color(0.24, 0.23, 0.20), weathering),
        0.0, "res://assets/materials/wood_peeling_paint_weathered/albedo.jpg")
    var iron := _material(IRON_BASE, 0.65)
    var oxide := _material(IRON_BASE.lerp(OXIDE_BASE, weathering), 0.35)
    var plaster := _material(PALE_PLASTER,
        0.0, "res://assets/materials/rough_plaster_brick_02/albedo.jpg")

    match house_style:
        0:
            # Longhouse: irregular, weathered eaves, corroded drainage and repair batten.
            for side in [-1.0, 1.0]:
                for section in range(7):
                    var z := -3.31 + float(section) * 1.10
                    var dip := -0.025 if section % 3 == 0 else 0.0
                    _beam("SplitFascia_%s_%d" % [str(side), section],
                        Vector3(side * 3.40, 3.99 + dip, z),
                        Vector3(0.11, 0.17, 1.02), timber)
                _beam("CorrodedGutter_%s" % str(side),
                    Vector3(side * 3.53, 3.81, 0), Vector3(0.13, 0.115, 7.6), iron)
                for bracket in range(5):
                    _beam("GutterBracket_%s_%d" % [str(side), bracket],
                        Vector3(side * 3.51, 3.76, -3.20 + bracket * 1.60),
                        Vector3(0.23, 0.12, 0.08), oxide)
            _pipe("DownpipeEast", Vector3(3.54, 2.01, 3.32), 0.07, 3.5, oxide)
            _beam("RepairedSiding", Vector3(-6.05, 2.27, 2.40),
                Vector3(0.055, 1.75, 0.13), timber)
        1:
            # Workers house: drain brackets, surface conduit and masonry patchwork.
            for side in [-1.0, 1.0]:
                _beam("AgedRoofGutter_%s" % str(side),
                    Vector3(side * 2.60, 3.81, 0),
                    Vector3(0.14, 0.12, 8.32), oxide)
                for bracket in range(5):
                    _beam("GutterSupport_%s_%d" % [str(side), bracket],
                        Vector3(side * 2.58, 3.75, -3.57 + bracket * 1.78),
                        Vector3(0.25, 0.12, 0.09), iron)
            _pipe("ServiceConduit", Vector3(4.045, 2.21, 1.53), 0.042, 2.4, iron)
            _beam("PlasterRepair", Vector3(4.065, 1.48, 2.65),
                Vector3(0.025, 0.82, 0.62), plaster)
            for p in range(3):
                _beam("RepairEdge_%d" % p,
                    Vector3(4.087, 1.18 + float(p) * 0.30, 2.62),
                    Vector3(0.019, 0.035, 0.58), oxide)
        2:
            # Garden house: chalked eaves, small gutter hooks and rainwater runoff.
            for side in [-1.0, 1.0]:
                _beam("WeatheredFascia_%s" % str(side),
                    Vector3(side * 2.76, 3.94, 0),
                    Vector3(0.095, 0.16, 10.25), timber)
                _beam("OxidizedRainGutter_%s" % str(side),
                    Vector3(side * 2.86, 3.81, 0),
                    Vector3(0.115, 0.10, 10.36), iron)
                for bracket in range(6):
                    _beam("GutterHook_%s_%d" % [str(side), bracket],
                        Vector3(side * 2.86, 3.75, -4.5 + bracket * 1.8),
                        Vector3(0.17, 0.09, 0.07), oxide)
            _pipe("GardenDrain", Vector3(2.91, 2.06, -4.89), 0.065, 3.45, iron)
            _beam("GardenDrainElbow", Vector3(2.77, 0.38, -4.89),
                Vector3(0.32, 0.11, 0.12), oxide)
        3:
            # Porch cottage: flashing and subtle replacement boards above the porch.
            # Keep the centre front path clear.
            _beam("PorchDripEdge", Vector3(0.0, 2.72, 5.0),
                Vector3(2.95, 0.09, 0.10), oxide)
            for idx in range(3):
                var x := -1.07 + float(idx) * 1.07
                _beam("AgedDeckBoard_%d" % idx, Vector3(x, 0.225, 4.90),
                    Vector3(0.91, 0.04, 0.15), timber)
            _beam("LeftPorchMetalStrap", Vector3(-1.36, 1.86, 4.93),
                Vector3(0.03, 0.46, 0.19), oxide)
            _beam("RightPorchMetalStrap", Vector3(1.36, 1.86, 4.93),
                Vector3(0.03, 0.46, 0.19), oxide)
        4:
            # Northern cottage already has gutters and roof trim. Add repairs to
            # those actual components rather than superimposing a second roof.
            for idx in range(5):
                _beam("CorrodedGutterBand_%d" % idx,
                    Vector3(-4.46, 3.045, -3.0 + float(idx) * 1.48),
                    Vector3(0.18, 0.10, 0.065), oxide)
            _pipe("RainwaterDownpipe", Vector3(-4.48, 1.52, 3.34),
                0.065, 2.95, iron)
            for idx in range(4):
                _beam("EndWallRepair_%d" % idx,
                    Vector3(4.45, 1.2 + float(idx) * 0.31, -2.58),
                    Vector3(0.05, 0.24, 0.65), timber)
