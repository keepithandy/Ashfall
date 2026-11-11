@tool
extends Node3D
## Station 04 distant vegetation: deterministic, decorative silhouettes only.
## No new collision, navigation obstacles, pickups, or runtime randomness.
## Four angular sectors cull independently instead of one world-sized batch.

@export var show_tree_line: bool = true
@export_range(24, 480, 8) var tree_count: int = 312
@export_range(0, 400, 8) var sapling_count: int = 192
@export_range(3.0, 12.0, 0.5) var average_height: float = 6.5
@export_range(0.08, 0.50, 0.02) var cluster_spread: float = 0.31
@export_range(0.0, 0.25, 0.01) var dead_tree_share: float = 0.055

const LIMIT_X := 86.0
const LIMIT_Z := 81.0
const SECTOR_COUNT := 4
const LIVING_PROFILES := 3
const DEAD_PROFILE := 3
const PROFILE_COUNT := 4
const CLUSTER_ANGLES := [0.16, 0.82, 1.52, 2.26, 3.04, 3.79, 4.65, 5.52]

# Logical placement samples for deterministic headless regression checks.
# Headless's dummy renderer cannot reliably read back MultiMesh transforms.
var generated_tree_bases: Array[Vector3] = []

func _ready() -> void:
    if show_tree_line:
        _build()

func _edge_radius(angle: float) -> float:
    return minf(LIMIT_X / maxf(absf(cos(angle)), 0.001),
                LIMIT_Z / maxf(absf(sin(angle)), 0.001))

func _triangle(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
    tool.add_vertex(a)
    tool.add_vertex(b)
    tool.add_vertex(c)

func _tube(tool: SurfaceTool, bottom: Vector3, top: Vector3, base_radius: float, tip_radius: float) -> void:
    var axis := (top - bottom).normalized()
    var right := axis.cross(Vector3.UP)
    if right.length_squared() < 0.01:
        right = axis.cross(Vector3.RIGHT)
    right = right.normalized()
    var forward := axis.cross(right).normalized()
    for j in range(6):
        var a0 := TAU * float(j) / 6.0
        var a1 := TAU * float(j + 1) / 6.0
        var p0 := right * cos(a0) + forward * sin(a0)
        var p1 := right * cos(a1) + forward * sin(a1)
        var b0 := bottom + p0 * base_radius
        var b1 := bottom + p1 * base_radius
        var t0 := top + p0 * tip_radius
        var t1 := top + p1 * tip_radius
        _triangle(tool, b0, b1, t0)
        _triangle(tool, b1, t1, t0)

func _wood_material() -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.19, 0.16, 0.14)
    material.roughness = 1.0
    material.vertex_color_use_as_albedo = true
    return material

func _needle_material(profile: int) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    var colors := [
        Color(0.225, 0.295, 0.22),
        Color(0.24, 0.275, 0.19),
        Color(0.18, 0.255, 0.215)
    ]
    material.albedo_color = colors[profile]
    material.roughness = 1.0
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    material.vertex_color_use_as_albedo = true
    return material

# Cross-angled, vertically oriented needle sprays. The former nearly
# horizontal fans collapsed to hairline strokes at a walking camera height.
func _needle_spray(tool: SurfaceTool, center: Vector3, direction: Vector3, tangent: Vector3, width: float, height: float) -> void:
    var top := center + Vector3.UP * height
    var bottom := center - Vector3.UP * height * 0.82 + direction * width * 0.19
    var side_a := center + tangent * width - direction * width * 0.12
    var side_b := center - tangent * width + direction * width * 0.20
    _triangle(tool, top, side_a, bottom)
    _triangle(tool, top, bottom, side_b)
    # A crossed plane gives each bough visible volume when viewed end-on.
    var tip := center + direction * width * 1.04 - Vector3.UP * height * 0.55
    var inward := center - direction * width * 0.83 + Vector3.UP * height * 0.13
    _triangle(tool, top, tip, inward)
    _triangle(tool, bottom, inward, tip)

func _tree_mesh(profile: int) -> ArrayMesh:
    var result := ArrayMesh.new()
    var wood := SurfaceTool.new()
    wood.begin(Mesh.PRIMITIVE_TRIANGLES)
    _tube(wood, Vector3.ZERO, Vector3(0.0, 1.0, 0.0), 0.025, 0.003)

    var seed_rng := RandomNumberGenerator.new()
    seed_rng.seed = 120504 + profile * 173
    var branch_count := 21 if profile == DEAD_PROFILE else 17
    for branch in range(branch_count):
        var f := float(branch) / float(branch_count)
        var y := 0.19 + f * 0.73
        var angle := TAU * (float(branch) * 0.6180339 + seed_rng.randf_range(-0.12, 0.12))
        var direction := Vector3(cos(angle), 0.0, sin(angle))
        var reach := (0.21 if profile == DEAD_PROFILE else 0.17) * (1.0 - f * 0.72)
        reach *= seed_rng.randf_range(0.65, 1.22)
        var start := Vector3(0.0, y, 0.0)
        var joint := start + direction * reach * 0.55 + Vector3(0.0, 0.018, 0.0)
        var tip := start + direction * reach + Vector3(0.0, -0.024 if profile == DEAD_PROFILE else -0.01, 0.0)
        _tube(wood, start, joint, 0.0065 * (1.0 - f * 0.5), 0.003)
        _tube(wood, joint, tip, 0.003, 0.0008)
        if profile == DEAD_PROFILE and branch % 2 == 0:
            var fork := joint + direction.rotated(Vector3.UP, 0.45) * reach * 0.46 + Vector3(0.0, 0.065, 0.0)
            _tube(wood, joint, fork, 0.0025, 0.0007)

    wood.generate_normals()
    wood.set_material(_wood_material())
    wood.commit(result)

    if profile == DEAD_PROFILE:
        return result

    # Interlocked downward branches, not a hollow horizontal starburst.
    # Vertical sprays create a real crown silhouette at eye level while
    # deliberately leaving irregular windows through the branches.
    var foliage := SurfaceTool.new()
    foliage.begin(Mesh.PRIMITIVE_TRIANGLES)
    var first_y := 0.19 if profile != 1 else 0.29
    var tiers := 15 if profile == 0 else 13
    for tier in range(tiers):
        var t := float(tier) / float(tiers - 1)
        var y := lerpf(first_y, 0.965, t)
        var radius := 0.32 * pow(1.0 - t, 0.88)
        if profile == 1:
            radius *= 1.15
        elif profile == 2:
            radius *= 0.89
        var spokes := 9 + (tier % 4)
        for spoke in range(spokes):
            var a := TAU * (float(spoke) + 0.34 * float(tier % 3)) / float(spokes)
            a += seed_rng.randf_range(-0.16, 0.16)
            var direction := Vector3(cos(a), 0.0, sin(a))
            var tangent := Vector3(-sin(a), 0.0, cos(a))
            var extent := radius * seed_rng.randf_range(0.72, 1.19)
            var branch_drop := extent * seed_rng.randf_range(0.05, 0.17)
            var outer := direction * (extent * 0.70) + Vector3.UP * (y - branch_drop)
            var inner := direction * (extent * 0.32) + Vector3.UP * (y + 0.014)
            var spray_height := 0.035 + extent * 0.27
            _needle_spray(foliage, outer, direction, tangent, extent * 0.31, spray_height)
            _needle_spray(foliage, inner, direction, tangent, extent * 0.24, spray_height * 0.82)
    foliage.generate_normals()
    foliage.set_material(_needle_material(profile))
    foliage.commit(result)
    return result

func _build() -> void:
    if has_node("ForestBatches"):
        return
    var horizon := get_node_or_null("../HorizonRelief") as Node3D
    if horizon == null or horizon.get_script() == null:
        push_warning("Station 04 tree line needs HorizonRelief for terrain-aligned roots")
        return
    var terrain_noise: FastNoiseLite = horizon.call("_make_noise") as FastNoiseLite
    if terrain_noise == null:
        push_warning("Station 04 tree line cannot sample distant ground heights")
        return

    var meshes: Array[ArrayMesh] = []
    for profile in range(PROFILE_COUNT):
        meshes.append(_tree_mesh(profile))

    var cells: Array = []
    for sector in range(SECTOR_COUNT):
        var types: Array = []
        for profile in range(PROFILE_COUNT):
            types.append([])
        cells.append(types)

    generated_tree_bases.clear()
    var rng := RandomNumberGenerator.new()
    rng.seed = 410404
    for i in range(tree_count):
        var center: float = CLUSTER_ANGLES[i % CLUSTER_ANGLES.size()]
        var angle := wrapf(center + rng.randf_range(-cluster_spread, cluster_spread), 0.0, TAU)
        var distance_from_wall := rng.randf_range(40.0, 330.0)
        var distance := _edge_radius(angle) + distance_from_wall
        var ground_point: Vector3 = horizon.call("_point", angle, distance_from_wall, terrain_noise)
        var base := Vector3(cos(angle) * distance, ground_point.y - 0.12, sin(angle) * distance)
        generated_tree_bases.append(base)
        var height := average_height * rng.randf_range(0.83, 1.92)
        var width := height * rng.randf_range(0.85, 1.20)
        var profile := rng.randi_range(0, LIVING_PROFILES - 1)
        if rng.randf() < dead_tree_share:
            profile = DEAD_PROFILE

        var axis := Vector3(rng.randf_range(-1.0, 1.0), 0.0, rng.randf_range(-1.0, 1.0)).normalized()
        if axis.length_squared() < 0.001:
            axis = Vector3.RIGHT
        var lean := rng.randf_range(-0.065, 0.065)
        var rotation := Basis(axis, lean) * Basis(Vector3.UP, rng.randf_range(-PI, PI))
        var transform := Transform3D(rotation * Basis().scaled(Vector3(width, height, width)), base)
        var tint := Color(
            rng.randf_range(0.85, 1.05),
            rng.randf_range(0.85, 1.07),
            rng.randf_range(0.83, 1.03)
        )
        var sector := mini(int(floor(angle / (TAU / float(SECTOR_COUNT)))), SECTOR_COUNT - 1)
        cells[sector][profile].append({
            "transform": transform, "tint": tint,
            "base": base, "height": height
        })

    var forest := Node3D.new()
    forest.name = "ForestBatches"
    add_child(forest)

    for sector in range(SECTOR_COUNT):
        for profile in range(PROFILE_COUNT):
            var instances: Array = cells[sector][profile]
            if instances.is_empty():
                continue
            var batch := MultiMesh.new()
            batch.transform_format = MultiMesh.TRANSFORM_3D
            batch.use_colors = true
            batch.mesh = meshes[profile]
            batch.instance_count = instances.size()
            var lower := Vector3(100000.0, 100000.0, 100000.0)
            var upper := Vector3(-100000.0, -100000.0, -100000.0)
            for index in range(instances.size()):
                var item: Dictionary = instances[index]
                batch.set_instance_transform(index, item["transform"])
                batch.set_instance_color(index, item["tint"])
                var base: Vector3 = item["base"]
                var height: float = item["height"]
                var reach := Vector3(height * 0.45, 2.0, height * 0.45)
                lower = lower.min(base - reach)
                upper = upper.max(base + Vector3(reach.x, height + 2.0, reach.z))
            batch.custom_aabb = AABB(lower, upper - lower)
            var node := MultiMeshInstance3D.new()
            node.name = "Sector%d_Profile%d" % [sector, profile]
            node.multimesh = batch
            node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
            forest.add_child(node)

    # A second, lower growth tier prevents a bare line of trunks at the
    # horizon. These saplings grow OUTSIDE the protected gameplay rectangle;
    # they add zero physics or navigation objects.
    var understory := Node3D.new()
    understory.name = "YoungGrowth"
    add_child(understory)
    var sapling_groups: Array = [[], [], []]
    var young_rng := RandomNumberGenerator.new()
    young_rng.seed = 44017
    for i in range(sapling_count):
        var center: float = CLUSTER_ANGLES[i % CLUSTER_ANGLES.size()]
        var angle := wrapf(center + young_rng.randf_range(-cluster_spread * 1.35, cluster_spread * 1.35), 0.0, TAU)
        var offset := young_rng.randf_range(26.0, 105.0)
        var distance := _edge_radius(angle) + offset
        var root: Vector3 = horizon.call("_point", angle, offset, terrain_noise)
        var height := young_rng.randf_range(1.8, 4.8)
        var spread := height * young_rng.randf_range(0.83, 1.21)
        var base := Vector3(cos(angle) * distance, root.y - 0.10, sin(angle) * distance)
        var turn := Basis(Vector3.UP, young_rng.randf_range(-PI, PI))
        var transform := Transform3D(turn.scaled(Vector3(spread, height, spread)), base)
        var tint := Color(young_rng.randf_range(0.84, 1.06), young_rng.randf_range(0.84, 1.06), young_rng.randf_range(0.85, 1.04))
        sapling_groups[i % 3].append({"transform": transform, "tint": tint, "base": base, "height": height})

    for profile in range(3):
        var instances: Array = sapling_groups[profile]
        if instances.is_empty():
            continue
        var batch := MultiMesh.new()
        batch.transform_format = MultiMesh.TRANSFORM_3D
        batch.use_colors = true
        batch.mesh = meshes[profile]
        batch.instance_count = instances.size()
        var lower := Vector3(100000.0, 100000.0, 100000.0)
        var upper := Vector3(-100000.0, -100000.0, -100000.0)
        for j in range(instances.size()):
            var item: Dictionary = instances[j]
            batch.set_instance_transform(j, item["transform"])
            batch.set_instance_color(j, item["tint"])
            var base: Vector3 = item["base"]
            var height: float = item["height"]
            var reach := Vector3(height * 0.45, 1.0, height * 0.45)
            lower = lower.min(base - reach)
            upper = upper.max(base + Vector3(reach.x, height + 1.0, reach.z))
        batch.custom_aabb = AABB(lower, upper - lower)
        var instance := MultiMeshInstance3D.new()
        instance.name = "SaplingProfile%d" % profile
        instance.multimesh = batch
        instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        understory.add_child(instance)
