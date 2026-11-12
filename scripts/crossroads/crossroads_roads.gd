@tool
extends Node3D
## Three connected, terrain-following rural routes.
## Real ground collision owns walking; the road surfaces are thin visual skins.
## At corners use joined/mitered edge vectors, not disconnected asphalt cards.
const PROFILE = preload("res://scripts/crossroads/crossroads_profile.gd")
const OLD_ASPHALT = preload("res://assets/roads/worn_road.tres")
const GRAVEL = preload("res://assets/roads/gravel_shoulder.tres")
const WET_SHADER = preload("res://assets/shaders/station04_wet_ground.gdshader")
var land = PROFILE.new()
var road_surfaces := 0
var puddles := 0
var route_samples: Array[Vector3] = []


func _ready() -> void:
    name = "CrossroadsRoadNetwork"
    rebuild()


func rebuild() -> void:
    if has_node("Routes"):
        return
    var roots := Node3D.new()
    roots.name = "Routes"
    add_child(roots)
    _route(roots, "VillageMainRoad", PROFILE.MAIN_ROAD, PROFILE.MAIN_WIDTH, 1.25, OLD_ASPHALT)
    _route(roots, "WestCartTrack", PROFILE.WEST_CART_TRACK, PROFILE.TRACK_WIDTH, 0.8, GRAVEL)
    _route(roots, "EastFieldLane", PROFILE.EAST_FARM_LANE, PROFILE.TRACK_WIDTH, 0.8, GRAVEL)
    _puddles(roots)


func _subdivide(path: Array) -> Array[Vector2]:
    var samples: Array[Vector2] = []
    samples.append(path[0])
    for index in range(path.size() - 1):
        var first: Vector2 = path[index]
        var second: Vector2 = path[index + 1]
        var slices := maxi(1, int(ceil(first.distance_to(second) / 2.0)))
        for piece in range(1, slices + 1):
            samples.append(first.lerp(second, float(piece) / float(slices)))
    return samples


func _side(points: Array[Vector2], index: int) -> Vector2:
    var incoming := Vector2.ZERO
    var outgoing := Vector2.ZERO
    if index > 0:
        incoming = (points[index] - points[index - 1]).normalized()
    if index + 1 < points.size():
        outgoing = (points[index + 1] - points[index]).normalized()
    if incoming.is_zero_approx():
        incoming = outgoing
    if outgoing.is_zero_approx():
        outgoing = incoming
    var a := Vector2(-incoming.y, incoming.x)
    var b := Vector2(-outgoing.y, outgoing.x)
    var joined := (a + b).normalized()
    if joined.length_squared() < 0.1:
        return b
    return joined * minf(1.35, 1.0 / maxf(0.60, joined.dot(b)))


func _vertex(point: Vector2, side: Vector2, offset: float, raise: float) -> Vector3:
    var x := point.x + side.x * offset
    var z := point.y + side.y * offset
    return Vector3(x, land.surface_height_at(x, z) + raise, z)


func _add_triangle(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, u0: float, u1: float, v0: float, v1: float) -> void:
    st.set_uv(Vector2(u0, v0))
    st.add_vertex(a)
    st.set_uv(Vector2(u1, v0))
    st.add_vertex(b)
    st.set_uv(Vector2(u0, v1))
    st.add_vertex(c)


func _make_strip(points: Array[Vector2], near: float, far: float, raise: float, material: Material) -> ArrayMesh:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    st.set_material(material)
    var traveled := 0.0
    for i in range(points.size() - 1):
        var left_a := _side(points, i)
        var left_b := _side(points, i + 1)
        var a := _vertex(points[i], left_a, near, raise)
        var b := _vertex(points[i], left_a, far, raise)
        var c := _vertex(points[i + 1], left_b, near, raise)
        var d := _vertex(points[i + 1], left_b, far, raise)
        var next_distance := traveled + points[i].distance_to(points[i + 1])
        # The material has both faces, so winding won't erase winding lanes.
        _add_triangle(st, a, c, b, near / 4.0, near / 4.0, traveled / 5.0, next_distance / 5.0)
        _add_triangle(st, b, c, d, far / 4.0, near / 4.0, traveled / 5.0, next_distance / 5.0)
        traveled = next_distance
    st.generate_normals()
    return st.commit()


func _mesh(parent: Node3D, label: String, mesh: ArrayMesh) -> void:
    if mesh == null or mesh.get_surface_count() == 0:
        return
    var visual := MeshInstance3D.new()
    visual.name = label
    visual.mesh = mesh
    visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    parent.add_child(visual)
    road_surfaces += 1


func _route(root: Node3D, label: String, path: Array, width: float, shoulder: float, material: Material) -> void:
    var holder := Node3D.new()
    holder.name = label
    root.add_child(holder)
    var points := _subdivide(path)
    var half := width * 0.5
    _mesh(holder, "CompactedSurface", _make_strip(points, -half, half, 0.034, material))
    _mesh(holder, "WestVerge", _make_strip(points, -half - shoulder, -half, 0.026, GRAVEL))
    _mesh(holder, "EastVerge", _make_strip(points, half, half + shoulder, 0.026, GRAVEL))
    for p in points:
        route_samples.append(Vector3(p.x, land.surface_height_at(p.x, p.y), p.y))


func _puddles(parent: Node3D) -> void:
    var wet := ShaderMaterial.new()
    wet.shader = WET_SHADER
    wet.set_shader_parameter("opacity", 0.22)
    var rng := RandomNumberGenerator.new()
    rng.seed = 57219
    var mesh := PlaneMesh.new()
    mesh.size = Vector2.ONE
    mesh.material = wet
    for i in range(25):
        var z := rng.randf_range(-178.0, 172.0)
        var side := -1.0 if i % 2 == 0 else 1.0
        var x := land.main_road_x(z) + side * rng.randf_range(3.0, 4.3)
        var drop := MeshInstance3D.new()
        drop.name = "OldRainwater%02d" % i
        drop.mesh = mesh
        drop.position = Vector3(x, land.surface_height_at(x, z) + 0.047, z)
        drop.rotation.y = rng.randf_range(-0.7, 0.7)
        drop.scale = Vector3(rng.randf_range(0.55, 1.25), 1.0, rng.randf_range(1.2, 2.9))
        drop.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        parent.add_child(drop)
        puddles += 1
