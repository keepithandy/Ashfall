@tool
extends Node3D
## Crossroads countryside composition, v2.3.
## Research basis: Ukraine's field-edge shelterbelts, small copses and
## agricultural mosaic rather than a featureless randomly scattered plain.
## Everything here is visual. All vegetation meshes/materials are reused
## from the existing Ashfall scenes. No new collisions or game systems.
##
## Instances are partitioned by 170m grid cell and source mesh/material:
## a handful of draws per cell instead of thousands of costly StaticBody3Ds.
const PROFILE = preload("res://scripts/crossroads/crossroads_profile.gd")
const PINE = preload("res://scenes/nature/forest_pine.tscn")
const BARE = preload("res://scenes/nature/bare_tree.tscn")
const SHRUB = preload("res://scenes/nature/low_shrub.tscn")
const BRAMBLE = preload("res://scenes/nature/dry_bramble.tscn")
const GRASS = preload("res://scenes/extra_dressing/dry_grass_tuft.tscn")
const FIELD_SHADER = preload("res://assets/shaders/crossroads_field_rows.gdshader")
const SOIL = preload("res://assets/materials/forest_ground_05/albedo.jpg")
const CELL := 170.0

const SOURCES := {
    "Pine": PINE, "Bare": BARE, "Shrub": SHRUB,
    "Bramble": BRAMBLE, "Grass": GRASS
}

const BELTS := [
    # Long western and eastern village shelterbelts, broken and irregular.
    [Vector2(-238.0, -630.0), Vector2(-243.0, 610.0), 3, 12.0],
    [Vector2(246.0, -650.0), Vector2(252.0, 605.0), 3, 12.0],
    # Cross-field windbreaks; road opening is enforced at placement.
    [Vector2(-570.0, -347.0), Vector2(555.0, -362.0), 2, 14.2],
    [Vector2(-545.0, 345.0), Vector2(570.0, 365.0), 2, 14.2],
    # Fainter deeper belts give the long horizon more than one silhouette.
    [Vector2(-511.0, -580.0), Vector2(-504.0, 540.0), 2, 17.0],
    [Vector2(518.0, -585.0), Vector2(512.0, 540.0), 2, 17.0],
    # Outer belts make the furthest playable country read as sheltered,
    # rather than ending on an empty straight horizon.
    [Vector2(-624.0, -590.0), Vector2(-634.0, 593.0), 2, 19.0],
    [Vector2(626.0, -590.0), Vector2(638.0, 590.0), 2, 19.0],
    [Vector2(-555.0, -628.0), Vector2(554.0, -638.0), 2, 19.0],
    [Vector2(-555.0, 628.0), Vector2(554.0, 639.0), 2, 19.0]
]

# Twelve recognisable agricultural parcels. Adjacent parcels have different
# crop/soil history and their edges are planted, not randomly scattered.
const FIELDS := [
    [-655.0, -307.0, -560.0, -382.0, 0],
    [-645.0, -332.0, -319.0, -144.0, 1],
    [-650.0, -311.0, -82.0, 124.0, 2],
    [-652.0, -308.0, 201.0, 321.0, 0],
    [313.0, 659.0, -570.0, -381.0, 1],
    [319.0, 650.0, -320.0, -139.0, 0],
    [312.0, 650.0, -81.0, 133.0, 2],
    [306.0, 658.0, 199.0, 313.0, 1],
    [-362.0, -40.0, -629.0, -468.0, 2],
    [48.0, 381.0, 490.0, 631.0, 0],
    [-379.0, -49.0, 481.0, 624.0, 1],
    [52.0, 384.0, -638.0, -474.0, 2]
]

var land = PROFILE.new()
var rng := RandomNumberGenerator.new()
var placements: Dictionary = {}
var planted_trees := 0
var planted_scrub := 0
var belts_authored := 0
var planted_groves := 0
var field_patches := 0
var field_triangles := 0
var draw_batches := 0
var road_margin_checks := 0
var prototypes_used := 0


func _ready() -> void:
    build()


func build() -> void:
    if has_node("LandscapeComposition"):
        return
    var root := Node3D.new()
    root.name = "LandscapeComposition"
    add_child(root)
    var patches := Node3D.new()
    patches.name = "PatchworkFields"
    root.add_child(patches)
    var vegetation := Node3D.new()
    vegetation.name = "BatchedVegetation"
    root.add_child(vegetation)

    rng.seed = 231118
    placements.clear()
    planted_trees = 0
    planted_scrub = 0
    belts_authored = 0
    planted_groves = 0
    field_patches = 0
    field_triangles = 0
    draw_batches = 0
    road_margin_checks = 0
    prototypes_used = 0
    _field_mosaic(patches)
    _shelterbelts()
    _small_woodlands()
    _field_margins()
    _road_edges()
    _build_batches(vegetation)


func _ground(x: float, z: float) -> float:
    # Outer fields have a 15m collision grid. Sample the *actual triangle
    # planes*, not the analytic height function, so tree roots sit on the
    # physical ground and no low shrub hovers in a coarse field triangle.
    if absf(x) <= PROFILE.WIDTH * 0.5 and absf(z) <= PROFILE.DEPTH * 0.5:
        return land.surface_height_at(x, z)
    if z < -210.0:
        return _field_height(x, z, -700.0, 700.0, -750.0, -210.0, 92, 36)
    if z > 210.0:
        return _field_height(x, z, -700.0, 700.0, 210.0, 750.0, 92, 36)
    if x < -180.0:
        return _field_height(x, z, -700.0, -180.0, -210.0, 210.0, 36, 30)
    return _field_height(x, z, 180.0, 700.0, -210.0, 210.0, 36, 30)


func _field_height(x: float, z: float, west: float, east: float, north: float, south: float, cols: int, rows: int) -> float:
    var dx := (east - west) / float(cols)
    var dz := (south - north) / float(rows)
    var gx := clampf((x - west) / dx, 0.0, float(cols) - 0.00001)
    var gz := clampf((z - north) / dz, 0.0, float(rows) - 0.00001)
    var col := int(floor(gx))
    var row := int(floor(gz))
    var tx := gx - float(col)
    var tz := gz - float(row)
    var x0 := west + float(col) * dx
    var z0 := north + float(row) * dz
    var a := land.outer_height_at(x0, z0)
    var b := land.outer_height_at(x0 + dx, z0)
    var c := land.outer_height_at(x0, z0 + dz)
    var d := land.outer_height_at(x0 + dx, z0 + dz)
    if tx + tz <= 1.0:
        return a * (1.0 - tx - tz) + b * tx + c * tz
    return d * (tx + tz - 1.0) + b * (1.0 - tz) + c * (1.0 - tx)


func _open_route(point: Vector2, radius: float = 0.0) -> bool:
    road_margin_checks += 1
    # Road shoulders, rear cart tracks and all twelve private approaches
    # stay traversable. The belts form no invisible walls.
    if land.distance_to_line(point, PROFILE.MAIN_ROAD) < 10.0 + radius:
        return true
    if land.distance_to_line(point, PROFILE.WEST_CART_TRACK) < 7.0 + radius:
        return true
    if land.distance_to_line(point, PROFILE.EAST_FARM_LANE) < 7.0 + radius:
        return true
    if absf(point.x) <= 178.0 and absf(point.y) <= 205.0:
        for site in PROFILE.HOMES:
            if point.distance_to(Vector2(float(site["x"]), float(site["z"]))) < 21.0 + radius:
                return true
    return false


func _plant(kind: String, pos: Vector2, size: float = 1.0, ignore_road: bool = false) -> void:
    if absf(pos.x) > 670.0 or absf(pos.y) > 710.0:
        return
    if not ignore_road and _open_route(pos):
        return
    var cx := int(floor(pos.x / CELL))
    var cz := int(floor(pos.y / CELL))
    var key := "%s|%d|%d" % [kind, cx, cz]
    if not placements.has(key):
        placements[key] = []
    var items: Array = placements[key]
    var angle := rng.randf_range(-PI, PI)
    var scale_vec := Vector3(
        size * rng.randf_range(0.92, 1.06),
        size * rng.randf_range(0.94, 1.10),
        size * rng.randf_range(0.91, 1.05)
    )
    var position := Vector3(pos.x, _ground(pos.x, pos.y) - 0.035, pos.y)
    items.append(Transform3D(Basis(Vector3.UP, angle).scaled(scale_vec), position))
    if kind == "Pine" or kind == "Bare":
        planted_trees += 1
    else:
        planted_scrub += 1


func _shelterbelts() -> void:
    for spec in BELTS:
        var a: Vector2 = spec[0]
        var b: Vector2 = spec[1]
        var rows: int = spec[2]
        var stride: float = spec[3]
        var along := (b - a).normalized()
        var across := Vector2(-along.y, along.x)
        var count := int(ceil(a.distance_to(b) / stride))
        for row in range(rows):
            for k in range(count):
                # Irregular omissions look like years of storm damage, yet
                # most of each belt still reads as a continuous windbreak.
                if (k * 13 + row * 17 + belts_authored) % 29 == 0:
                    continue
                var t := clampf((float(k) + rng.randf_range(-0.21, 0.21)) / float(count), 0.0, 1.0)
                var point := a.lerp(b, t) + across * (float(row) - float(rows - 1) * 0.5) * 3.8
                point += Vector2(rng.randf_range(-1.45, 1.45), rng.randf_range(-1.45, 1.45))
                var kind := "Bare" if (k + 2 * row + belts_authored) % 5 < 3 else "Pine"
                _plant(kind, point, rng.randf_range(1.35, 2.00))
                if (k + row) % 4 == 0:
                    _plant("Shrub", point + across * rng.randf_range(3.0, 6.3), rng.randf_range(1.1, 1.75))
        belts_authored += 1


func _small_woodlands() -> void:
    var woods := [
        Vector2(-353, -185), Vector2(360, 194),
        Vector2(-347, 188), Vector2(357, -192),
        Vector2(-435, -474), Vector2(431, 479),
        Vector2(-403, 463), Vector2(417, -460),
        Vector2(-153, -489), Vector2(170, 473)
    ]
    for index in range(woods.size()):
        var center: Vector2 = woods[index]
        var count := 50 if index < 4 else 32
        for j in range(count):
            var angle := rng.randf_range(-PI, PI)
            var r := sqrt(rng.randf()) * (34.0 if index < 4 else 26.0)
            var point := center + Vector2(cos(angle), sin(angle)) * r
            var kind := "Pine" if (j + index) % 4 == 0 else "Bare"
            _plant(kind, point, rng.randf_range(1.05, 1.75))
            if j % 3 == 0:
                _plant("Bramble", point + Vector2(1.5, -1.9), rng.randf_range(0.8, 1.25))
        planted_groves += 1


func _field_margins() -> void:
    # Scrub remains near planted field borders, the backs of yards and old
    # hedgerows. Don't form uniform dots or fill the cropped field centres.
    for parcel in FIELDS:
        var west: float = parcel[0]
        var east: float = parcel[1]
        var north: float = parcel[2]
        var south: float = parcel[3]
        var perimeter := 2.0 * ((east - west) + (south - north))
        var count := int(perimeter / 7.0)
        for n in range(count):
            var t := rng.randf()
            var x := west if n % 4 == 0 else (east if n % 4 == 1 else lerpf(west, east, t))
            var z := lerpf(north, south, t) if n % 4 < 2 else (north if n % 4 == 2 else south)
            var p := Vector2(x + rng.randf_range(-4.0, 4.0), z + rng.randf_range(-4.0, 4.0))
            _plant("Grass" if n % 2 == 0 else "Bramble", p, rng.randf_range(1.0, 1.65))
            if n % 5 == 0:
                _plant("Shrub", p + Vector2(2.1, -1.6), rng.randf_range(0.9, 1.3))
    # Original village has existing shrubs; this fills the dead gap between
    # its last fences and the first proper field shelterbelts.
    for k in range(930):
        var x := rng.randf_range(-315.0, 315.0)
        var z := rng.randf_range(-385.0, 385.0)
        if absf(x) < 102.0 and absf(z) < 210.0:
            continue
        var p := Vector2(x, z)
        if _open_route(p, 2.0):
            continue
        var kind := "Grass" if k % 3 != 0 else ("Shrub" if k % 5 == 0 else "Bramble")
        _plant(kind, p, rng.randf_range(0.80, 1.35))


func _road_edges() -> void:
    # Distant approaches need everyday plant life, not an asphalt ribbon
    # extending into open empty space. Keep a clear carriageway and verges.
    for sign in [-1.0, 1.0]:
        for j in range(235):
            var z: float = float(sign) * (226.0 + float(j) * 1.85)
            var x := land.main_road_x(z)
            var side := -1.0 if j % 2 == 0 else 1.0
            var offset := side * rng.randf_range(11.5, 23.5)
            var pos := Vector2(x + offset, z)
            if j % 12 == 0:
                _plant("Bare", pos + Vector2(side * 4.0, 0.0), rng.randf_range(1.05, 1.5))
            elif j % 4 == 0:
                _plant("Shrub", pos, rng.randf_range(0.7, 1.2))
            else:
                _plant("Grass" if j % 3 else "Bramble", pos, rng.randf_range(0.9, 1.35))


func _field_mosaic(parent: Node3D) -> void:
    for index in range(FIELDS.size()):
        var spec: Array = FIELDS[index]
        var west: float = spec[0]
        var east: float = spec[1]
        var north: float = spec[2]
        var south: float = spec[3]
        var kind: int = spec[4]
        var material := ShaderMaterial.new()
        material.shader = FIELD_SHADER
        material.set_shader_parameter("soil_albedo", SOIL)
        material.set_shader_parameter("plot_type", kind)
        material.set_shader_parameter("furrow_angle", 0.12 + 0.36 * float(index % 3))
        var columns := maxi(2, int(ceil((east - west) / 9.0)))
        var rows := maxi(2, int(ceil((south - north) / 9.0)))
        var mesh := SurfaceTool.new()
        mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
        mesh.set_material(material)
        for row in range(rows):
            var z0 := lerpf(north, south, float(row) / float(rows))
            var z1 := lerpf(north, south, float(row + 1) / float(rows))
            for col in range(columns):
                var x0 := lerpf(west, east, float(col) / float(columns))
                var x1 := lerpf(west, east, float(col + 1) / float(columns))
                var a := _plot_vertex(x0, z0)
                var b := _plot_vertex(x1, z0)
                var c := _plot_vertex(x0, z1)
                var d := _plot_vertex(x1, z1)
                for v in [a, b, c, b, d, c]:
                    mesh.set_uv(Vector2(v.x / 5.0, v.z / 5.0))
                    mesh.add_vertex(v)
                field_triangles += 2
        mesh.generate_normals()
        var visual := MeshInstance3D.new()
        visual.name = "HarvestedParcel_%02d" % index
        visual.mesh = mesh.commit()
        visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        parent.add_child(visual)
        field_patches += 1


func _plot_vertex(x: float, z: float) -> Vector3:
    return Vector3(x, _ground(x, z) + 0.066, z)


func _build_batches(parent: Node3D) -> void:
    # Each source PackedScene is constructed exactly once, then its already
    # authored mesh and material resources are shared by every instance.
    # No clones of a 950KB tree scene per trunk or serialized GLBs.
    for kind in SOURCES.keys():
        var packed: PackedScene = SOURCES[kind]
        var sample := packed.instantiate() as Node3D
        if sample == null:
            push_error("Crossroads missing existing vegetation: " + str(kind))
            continue
        prototypes_used += 1
        var meshes: Array = sample.find_children("*", "MeshInstance3D", true, false)
        var group := Node3D.new()
        group.name = str(kind) + "ShelterbeltBatches"
        parent.add_child(group)
        for key in placements.keys():
            var parts := str(key).split("|")
            if parts[0] != str(kind):
                continue
            var instances: Array = placements[key]
            for part in range(meshes.size()):
                var source := meshes[part] as MeshInstance3D
                if source.mesh == null:
                    continue
                var mm := MultiMesh.new()
                mm.transform_format = MultiMesh.TRANSFORM_3D
                mm.mesh = source.mesh
                mm.instance_count = instances.size()
                for i in range(instances.size()):
                    var tf: Transform3D = instances[i]
                    mm.set_instance_transform(i, tf * source.transform)
                var batch := MultiMeshInstance3D.new()
                batch.name = "Chunk_%s_Mesh%d" % [str(key).replace("|", "_"), part]
                batch.multimesh = mm
                batch.material_override = source.material_override
                batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
                batch.visibility_range_end = 770.0
                group.add_child(batch)
                draw_batches += 1
        sample.free()
