@tool
extends Node3D
## Station 04 distant silhouettes: VISUAL ONLY. Never modify walkable terrain,
## collisions, houses, entry route, creatures or expedition state.
##
## A square collision perimeter is centered at the level origin. We calculate
## the ray intersection with that rectangle, then begin the mesh OUTSIDE it.
## The relief never extends into the traversable district, even at corners.

@export_range(64, 192, 16) var angular_segments: int = 128
@export_range(0.0, 20.0, 0.5) var relief_height: float = 9.0
@export var show_relief: bool = true

const PLAY_X := 86.0
const PLAY_Z := 81.0
const OFFSETS := [9.0, 15.0, 23.0, 35.0, 52.0, 75.0, 100.0, 130.0]

func _ready() -> void:
    if show_relief:
        _build()

func _perimeter_radius(angle: float) -> float:
    var x := PLAY_X / maxf(absf(cos(angle)), 0.001)
    var z := PLAY_Z / maxf(absf(sin(angle)), 0.001)
    return minf(x, z)

func _height_at(angle: float, distance_from_wall: float, x: float, z: float, noise: FastNoiseLite) -> float:
    # Leave a lower-than-ground seam at the near edge; fade up outside the wall.
    var fade := smoothstep(15.0, 90.0, distance_from_wall)
    var relief_noise := noise.get_noise_2d(x, z)
    var eastern_ridge := maxf(0.0, cos(angle - 0.45))
    var western_ridge := maxf(0.0, cos(angle - 2.7))
    var shape := 3.2 + 3.0 * relief_noise + 3.5 * eastern_ridge * eastern_ridge + 1.6 * western_ridge
    return -0.045 + maxf(0.5, shape) * fade * relief_height / 9.0

func _point(angle: float, offset: float, noise: FastNoiseLite) -> Vector3:
    var r := _perimeter_radius(angle) + offset
    var x := cos(angle) * r
    var z := sin(angle) * r
    return Vector3(x, _height_at(angle, offset, x, z, noise), z)

func _vertex(tool: SurfaceTool, p: Vector3) -> void:
    tool.set_uv(Vector2(p.x, p.z) * 0.22)
    tool.add_vertex(p)

func _triangle(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
    _vertex(tool, a)
    _vertex(tool, b)
    _vertex(tool, c)

func _make_noise() -> FastNoiseLite:
    var noise := FastNoiseLite.new()
    noise.seed = 4404
    noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
    noise.frequency = 0.016
    noise.fractal_type = FastNoiseLite.FRACTAL_FBM
    noise.fractal_octaves = 3
    return noise

func _build() -> void:
    if has_node("DistantTerrain"):
        return
    var noise := _make_noise()
    var tool := SurfaceTool.new()
    tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    var segments := maxi(64, angular_segments)
    for ring in range(OFFSETS.size() - 1):
        for segment in range(segments):
            var a0 := TAU * float(segment) / float(segments)
            var a1 := TAU * float(segment + 1) / float(segments)
            var near0 := _point(a0, OFFSETS[ring], noise)
            var near1 := _point(a1, OFFSETS[ring], noise)
            var far0 := _point(a0, OFFSETS[ring + 1], noise)
            var far1 := _point(a1, OFFSETS[ring + 1], noise)
            # Counterclockwise when seen from above: visible top faces.
            _triangle(tool, near0, near1, far0)
            _triangle(tool, near1, far1, far0)

    # Normals must be generated before indexing; shared vertices across
    # triangle seams would otherwise be indexed without smoothing control.
    tool.generate_normals()
    tool.generate_tangents()
    tool.index()
    var mesh := tool.commit()
    if mesh == null:
        push_error("Station 04 distant relief mesh generation failed")
        return
    var vista := MeshInstance3D.new()
    vista.name = "DistantTerrain"
    vista.mesh = mesh
    vista.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    # Exactly reuse the terrain PBR shader to avoid mismatched horizon colors.
    var ground := get_node_or_null("../WalkableGround/VisibleGround") as MeshInstance3D
    if ground != null:
        vista.material_override = ground.material_override
    add_child(vista)
