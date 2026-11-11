@tool
extends Node3D
## Station 04 silhouette vegetation. Decorative only, beyond the physics limits.
## No new collision, navigation obstacles, pickups, or runtime randomness.

@export var show_tree_line: bool = true
@export_range(24, 240, 8) var tree_count: int = 128
@export_range(3.0, 12.0, 0.5) var average_height: float = 6.5

const LIMIT_X := 86.0
const LIMIT_Z := 81.0

func _ready() -> void:
    if show_tree_line:
        _build()

func _edge_radius(angle: float) -> float:
    return minf(LIMIT_X / maxf(absf(cos(angle)), 0.001),
                LIMIT_Z / maxf(absf(sin(angle)), 0.001))

func _build() -> void:
    if has_node("Trunks") or has_node("Crowns"):
        return
    var horizon := get_node_or_null("../HorizonRelief") as Node3D
    if horizon == null or horizon.get_script() == null:
        push_warning("Station 04 tree line needs HorizonRelief for terrain-aligned roots")
        return
    var terrain_noise: FastNoiseLite = horizon.call("_make_noise") as FastNoiseLite
    if terrain_noise == null:
        push_warning("Station 04 tree line cannot sample distant ground heights")
        return
    var rng := RandomNumberGenerator.new()
    rng.seed = 410404
    var trunk_mesh := CylinderMesh.new()
    trunk_mesh.top_radius = 0.09
    trunk_mesh.bottom_radius = 0.18
    trunk_mesh.height = 1.0
    trunk_mesh.radial_segments = 5
    trunk_mesh.rings = 1
    var crown_mesh := CylinderMesh.new()
    crown_mesh.top_radius = 0.05
    crown_mesh.bottom_radius = 0.85
    crown_mesh.height = 1.0
    crown_mesh.radial_segments = 6
    crown_mesh.rings = 1

    var wood := StandardMaterial3D.new()
    wood.albedo_color = Color(0.16, 0.14, 0.12)
    wood.roughness = 1.0
    trunk_mesh.material = wood
    var needles := StandardMaterial3D.new()
    needles.albedo_color = Color(0.115, 0.16, 0.135)
    needles.roughness = 1.0
    crown_mesh.material = needles

    var trunk_batch := MultiMesh.new()
    trunk_batch.transform_format = MultiMesh.TRANSFORM_3D
    trunk_batch.mesh = trunk_mesh
    trunk_batch.instance_count = tree_count
    var crown_batch := MultiMesh.new()
    crown_batch.transform_format = MultiMesh.TRANSFORM_3D
    crown_batch.mesh = crown_mesh
    crown_batch.instance_count = tree_count

    for i in range(tree_count):
        var angle := TAU * (float(i) + rng.randf_range(-0.28, 0.28)) / float(tree_count)
        var distance := _edge_radius(angle) + rng.randf_range(25.0, 85.0)
        var x := cos(angle) * distance
        var z := sin(angle) * distance
        var height := average_height * rng.randf_range(0.62, 1.48)
        var crown_height := height * rng.randf_range(0.66, 0.83)
        # Use the exact horizon profile at this angle and distance so trunks
        # do not float above raised terrain or begin far below its surface.
        var ground_point: Vector3 = horizon.call("_point", angle, distance - _edge_radius(angle), terrain_noise)
        var trunk_base := Vector3(x, ground_point.y - 0.14, z)
        var trunk_basis := Basis().scaled(Vector3(1.0, height, 1.0))
        trunk_batch.set_instance_transform(i, Transform3D(trunk_basis, trunk_base + Vector3(0, height * 0.5, 0)))
        var crown_basis := Basis(Vector3.UP, rng.randf_range(-PI, PI))
        crown_basis = crown_basis.scaled(Vector3(height * 0.22, crown_height, height * 0.22))
        crown_batch.set_instance_transform(i, Transform3D(crown_basis, trunk_base + Vector3(0, height - crown_height * 0.48, 0)))

    # Give each whole batch a conservative draw extent to prevent camera-pan
    # culling; these are far-field visuals, not hundreds of physics nodes.
    var batch_bounds := AABB(Vector3(-240.0, -5.0, -240.0), Vector3(480.0, 35.0, 480.0))
    trunk_batch.custom_aabb = batch_bounds
    crown_batch.custom_aabb = batch_bounds
    for item in [
        {"name": "Trunks", "batch": trunk_batch},
        {"name": "Crowns", "batch": crown_batch}
    ]:
        var instance := MultiMeshInstance3D.new()
        instance.name = item["name"]
        instance.multimesh = item["batch"]
        instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        add_child(instance)
