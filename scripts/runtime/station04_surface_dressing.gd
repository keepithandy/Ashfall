@tool
extends Node3D
## Lightweight, collision-free ground microdressing for Station 04.
## Author-placed zones keep the main road, doors, loot, and station route clear.
## Two MultiMesh draw calls replace hundreds of standalone physics props.
## All positions are deterministic and use the existing flat surface y=0.

@export var draw_surface_detail: bool = true

const ZONES := [
    # Road edges (the drivable/walkable road is only 5.5 m wide).
    {"x": -7.2, "z": -20.0, "rx": 1.4, "rz": 25.0, "leaf": 80, "stone": 75},
    {"x": 7.4, "z": -18.0, "rx": 1.6, "rz": 23.0, "leaf": 80, "stone": 75},
    # Service-yard perimeter; not the generator doorway or sample location.
    {"x": 43.2, "z": -10.0, "rx": 1.7, "rz": 13.0, "leaf": 52, "stone": 52},
    {"x": 24.0, "z": -27.0, "rx": 10.0, "rz": 1.4, "leaf": 44, "stone": 64},
    # Damaged understory outside the main route and house thresholds.
    {"x": -43.0, "z": 31.0, "rx": 4.5, "rz": 4.0, "leaf": 60, "stone": 22},
    {"x": 48.0, "z": 32.0, "rx": 4.0, "rz": 5.0, "leaf": 55, "stone": 25},
    {"x": -43.0, "z": -49.0, "rx": 6.0, "rz": 4.0, "leaf": 45, "stone": 34}
]

func _ready() -> void:
    if draw_surface_detail:
        _make_layer(true)
        _make_layer(false)

func _make_layer(leaves: bool) -> void:
    var label := "LeafFragments" if leaves else "ScatteredGravel"
    if has_node(label):
        return
    var rng := RandomNumberGenerator.new()
    rng.seed = 40412 if leaves else 40413
    var points: Array[Vector3] = []
    for zone in ZONES:
        var amount: int = int(zone["leaf"] if leaves else zone["stone"])
        for i in range(amount):
            var x: float = float(zone["x"]) + rng.randf_range(-float(zone["rx"]), float(zone["rx"]))
            var z: float = float(zone["z"]) + rng.randf_range(-float(zone["rz"]), float(zone["rz"]))
            points.append(Vector3(x, 0.013 if leaves else 0.028, z))

    var surface := StandardMaterial3D.new()
    surface.roughness = 0.96
    surface.metallic = 0.0
    surface.vertex_color_use_as_albedo = true
    var mesh: Mesh
    if leaves:
        var plane := PlaneMesh.new()
        plane.size = Vector2(0.14, 0.058)
        mesh = plane
        surface.cull_mode = BaseMaterial3D.CULL_DISABLED
    else:
        var pebble := SphereMesh.new()
        pebble.radius = 0.045
        pebble.height = 0.045
        pebble.radial_segments = 8
        pebble.rings = 4
        mesh = pebble
    mesh.surface_set_material(0, surface)

    var multi := MultiMesh.new()
    multi.transform_format = MultiMesh.TRANSFORM_3D
    multi.use_colors = true
    multi.mesh = mesh
    # Explicit combined draw bounds prevent disappearing fragments on camera pans.
    multi.custom_aabb = AABB(Vector3(-56.0, -0.2, -57.0), Vector3(114.0, 0.6, 110.0))
    multi.instance_count = points.size()
    for i in range(points.size()):
        var turn := rng.randf_range(-PI, PI)
        var stretch := rng.randf_range(0.72, 1.45)
        var scale := Vector3(stretch, 1.0, rng.randf_range(0.65, 1.55)) if leaves else Vector3(stretch, rng.randf_range(0.45, 1.0), stretch)
        var basis := Basis(Vector3.UP, turn).scaled(scale)
        multi.set_instance_transform(i, Transform3D(basis, points[i]))
        var tint: Color
        if leaves:
            tint = Color(0.31, 0.26, 0.16).lerp(Color(0.48, 0.43, 0.28), rng.randf())
        else:
            tint = Color(0.35, 0.35, 0.30).lerp(Color(0.53, 0.52, 0.45), rng.randf())
        multi.set_instance_color(i, tint)

    var instance := MultiMeshInstance3D.new()
    instance.name = label
    instance.multimesh = multi
    instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(instance)
