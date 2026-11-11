@tool
extends Node3D
## Editable Ashfall road model built from centre-line points in local metres.
## Visuals only. Terrain underneath supplies physics, avoiding floating slabs.
## This can also draw a river corridor with alternate materials and width.

const DEFAULT_SURFACE = preload("res://assets/roads/worn_road.tres")
const DEFAULT_SHOULDER = preload("res://assets/roads/gravel_shoulder.tres")

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

func _direction(from_point: Vector3, to_point: Vector3) -> Vector2:
    var v := Vector2(to_point.x - from_point.x, to_point.z - from_point.z)
    if v.length_squared() < 0.000001:
        return Vector2.RIGHT
    return v.normalized()

func _side_at(index: int) -> Vector2:
    var last := path_points.size() - 1
    if index == 0:
        var first_direction := _direction(path_points[0], path_points[1])
        return Vector2(-first_direction.y, first_direction.x)
    if index == last:
        var last_direction := _direction(path_points[last - 1], path_points[last])
        return Vector2(-last_direction.y, last_direction.x)

    var incoming := _direction(path_points[index - 1], path_points[index])
    var outgoing := _direction(path_points[index], path_points[index + 1])
    var left_a := Vector2(-incoming.y, incoming.x)
    var left_b := Vector2(-outgoing.y, outgoing.x)
    var bisector := left_a + left_b
    if bisector.length_squared() < 0.001:
        return left_b
    var joined := bisector.normalized()
    var denominator := maxf(absf(joined.dot(left_b)), 0.52)
    return joined * minf(1.0 / denominator, 1.8)

func _position_at(point: Vector3, side: Vector2, offset: float, elevation: float) -> Vector3:
    return Vector3(point.x + side.x * offset, point.y + elevation, point.z + side.y * offset)

func _emit(st: SurfaceTool, point: Vector3, uv: Vector2) -> void:
    st.set_normal(Vector3.UP)
    st.set_uv(uv)
    st.add_vertex(point)

func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, va: float, vb: float, u0: float, u1: float) -> void:
    _emit(st, a, Vector2(u0, va))
    _emit(st, b, Vector2(u1, va))
    _emit(st, c, Vector2(u0, vb))
    _emit(st, b, Vector2(u1, va))
    _emit(st, d, Vector2(u1, vb))
    _emit(st, c, Vector2(u0, vb))

func _make_strip(left_offset: float, right_offset: float, elevation: float, material: Material) -> ArrayMesh:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    st.set_material(material)
    var distance := 0.0
    for i in range(path_points.size() - 1):
        var a: Vector3 = path_points[i]
        var b: Vector3 = path_points[i + 1]
        if Vector2(a.x - b.x, a.z - b.z).length_squared() < 0.000001:
            continue
        var side_a := _side_at(i)
        var side_b := _side_at(i + 1)
        var next_distance := distance + Vector2(b.x - a.x, b.z - a.z).length()
        _quad(st,
            _position_at(a, side_a, left_offset, elevation),
            _position_at(a, side_a, right_offset, elevation),
            _position_at(b, side_b, left_offset, elevation),
            _position_at(b, side_b, right_offset, elevation),
            distance / 5.0, next_distance / 5.0,
            left_offset / 5.0, right_offset / 5.0)
        distance = next_distance
    return st.commit()

func _visual(name: String, mesh: ArrayMesh) -> void:
    if mesh == null or mesh.get_surface_count() == 0:
        return
    var instance := MeshInstance3D.new()
    instance.name = name
    instance.mesh = mesh
    instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    instance.set_meta("ashfall_generated_road", true)
    add_child(instance)
    # No owner: generated road surfaces are rebuilt from saved spline data.

func _rebuild() -> void:
    if not is_inside_tree():
        return
    for child in get_children():
        if child.get_meta("ashfall_generated_road", false):
            child.free()
    if path_points.size() < 2:
        return

    var half := road_width * 0.5
    if shoulder_width > 0.0:
        _visual("LeftGravelShoulder", _make_strip(-half - shoulder_width, -half, surface_height - 0.010, shoulder_material))
        _visual("RightGravelShoulder", _make_strip(half, half + shoulder_width, surface_height - 0.010, shoulder_material))
    _visual("CompactedRoadSurface", _make_strip(-half, half, surface_height, surface_material))
