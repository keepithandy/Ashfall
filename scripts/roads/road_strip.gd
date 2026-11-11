@tool
extends Node3D
## Reusable editable Ashfall road/river strip.
## In the regional map, the strip is tessellated and samples the exact
## TRIANGULATED terrain surface under both its centre and side edges.
## Legacy road model gallery remains flat unless follow_region_terrain = true.

const PROFILE = preload("res://scripts/roads/region_height_profile.gd")
const DEFAULT_SURFACE = preload("res://assets/roads/worn_road.tres")
const DEFAULT_SHOULDER = preload("res://assets/roads/gravel_shoulder.tres")

var region_height = PROFILE.new()

@export var path_points: PackedVector3Array = PackedVector3Array([
    Vector3(-12.0, 0.0, 0.0),
    Vector3(12.0, 0.0, 0.0)
]):
    set(value):
        path_points = value
        _rebuild()

@export_range(2.0, 140.0, 0.25) var road_width := 5.8:
    set(value):
        road_width = value
        _rebuild()

@export_range(0.0, 4.0, 0.1) var shoulder_width := 1.15:
    set(value):
        shoulder_width = value
        _rebuild()

@export_range(0.002, 0.20, 0.002) var surface_height := 0.036:
    set(value):
        surface_height = value
        _rebuild()

@export var follow_region_terrain := false:
    set(value):
        follow_region_terrain = value
        _rebuild()

@export_range(2.0, 18.0, 1.0) var segment_length := 6.0:
    set(value):
        segment_length = value
        _rebuild()

@export var surface_material: Material = DEFAULT_SURFACE:
    set(value):
        surface_material = value
        _rebuild()

@export var shoulder_material: Material = DEFAULT_SHOULDER:
    set(value):
        shoulder_material = value
        _rebuild()

func _ready() -> void:
    _rebuild()

func _direction(a: Vector3, b: Vector3) -> Vector2:
    var vector := Vector2(b.x - a.x, b.z - a.z)
    if vector.length_squared() < 0.000001:
        return Vector2.RIGHT
    return vector.normalized()

func _working_points() -> PackedVector3Array:
    if not follow_region_terrain or path_points.size() < 2:
        return path_points
    var expanded := PackedVector3Array()
    expanded.append(path_points[0])
    for i in range(path_points.size() - 1):
        var a: Vector3 = path_points[i]
        var b: Vector3 = path_points[i + 1]
        var length := Vector2(b.x - a.x, b.z - a.z).length()
        var segments := maxi(1, int(ceil(length / segment_length)))
        for step in range(1, segments + 1):
            expanded.append(a.lerp(b, float(step) / float(segments)))
    return expanded

func _side_at(index: int, points: PackedVector3Array) -> Vector2:
    var last := points.size() - 1
    if index == 0:
        var first := _direction(points[0], points[1])
        return Vector2(-first.y, first.x)
    if index == last:
        var final_segment := _direction(points[last - 1], points[last])
        return Vector2(-final_segment.y, final_segment.x)

    var incoming := _direction(points[index - 1], points[index])
    var outgoing := _direction(points[index], points[index + 1])
    var left_a := Vector2(-incoming.y, incoming.x)
    var left_b := Vector2(-outgoing.y, outgoing.x)
    var bisector := left_a + left_b
    if bisector.length_squared() < 0.001:
        return left_b
    var joined := bisector.normalized()
    var denominator := maxf(absf(joined.dot(left_b)), 0.52)
    return joined * minf(1.0 / denominator, 1.8)

func _position_at(point: Vector3, side: Vector2, offset: float, elevation: float) -> Vector3:
    var x := point.x + side.x * offset
    var z := point.z + side.y * offset
    var y := point.y
    if follow_region_terrain:
        y = region_height.surface_height_at(x, z)
    return Vector3(x, y + elevation, z)

func _emit(st: SurfaceTool, point: Vector3, uv: Vector2) -> void:
    st.set_normal(Vector3.UP)
    st.set_uv(uv)
    st.add_vertex(point)

func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, u0: float, u1: float, v0: float, v1: float) -> void:
    _emit(st, a, Vector2(u0, v0))
    _emit(st, b, Vector2(u1, v0))
    _emit(st, c, Vector2(u0, v1))
    _emit(st, b, Vector2(u1, v0))
    _emit(st, d, Vector2(u1, v1))
    _emit(st, c, Vector2(u0, v1))

func _make_strip(points: PackedVector3Array, start: float, end: float, elevation: float, material: Material) -> ArrayMesh:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    st.set_material(material)
    var distance := 0.0
    for i in range(points.size() - 1):
        var a: Vector3 = points[i]
        var b: Vector3 = points[i + 1]
        var length := Vector2(b.x - a.x, b.z - a.z).length()
        if length < 0.001:
            continue
        var side_a := _side_at(i, points)
        var side_b := _side_at(i + 1, points)
        _quad(st,
            _position_at(a, side_a, start, elevation),
            _position_at(a, side_a, end, elevation),
            _position_at(b, side_b, start, elevation),
            _position_at(b, side_b, end, elevation),
            start / 5.0, end / 5.0,
            distance / 5.0, (distance + length) / 5.0)
        distance += length
    return st.commit()

func _visual(label: String, mesh: ArrayMesh) -> void:
    if mesh == null or mesh.get_surface_count() == 0:
        return
    var instance := MeshInstance3D.new()
    instance.name = label
    instance.mesh = mesh
    instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    instance.set_meta("ashfall_generated_road", true)
    add_child(instance)

func _rebuild() -> void:
    if not is_inside_tree():
        return
    for child in get_children():
        if child.get_meta("ashfall_generated_road", false):
            child.free()
    if path_points.size() < 2:
        return

    var points := _working_points()
    var half := road_width * 0.5
    if shoulder_width > 0.0:
        _visual("LeftGravelShoulder",
            _make_strip(points, -half - shoulder_width, -half, surface_height - 0.010, shoulder_material))
        _visual("RightGravelShoulder",
            _make_strip(points, half, half + shoulder_width, surface_height - 0.010, shoulder_material))
    _visual("CompactedRoadSurface",
        _make_strip(points, -half, half, surface_height, surface_material))
