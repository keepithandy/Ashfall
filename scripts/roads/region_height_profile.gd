extends RefCounted
## Shared deterministic regional heightfield for mesh, roads, destinations,
## bridge landings and regression tests. Units are metres in Godot X/Z.
## This is a terrain BLOCKOUT, not a final erosion simulation or LOD system.

const WIDTH := 2400.0
const DEPTH := 2000.0
const WATER_LEVEL := -9.0
const BRIDGE_DECK_HEIGHT := 7.5
const RIVER_HALF_WIDTH := 45.0
const GRID_COLUMNS := 200
const GRID_ROWS := 168
const GRID_STEP_X := WIDTH / GRID_COLUMNS
const GRID_STEP_Z := DEPTH / GRID_ROWS

const SITE_COORDS := [
    Vector2(-720.0, -700.0), Vector2(-170.0, -820.0),
    Vector2(320.0, -490.0), Vector2(800.0, -780.0),
    Vector2(-920.0, -150.0), Vector2(-760.0, 650.0),
    Vector2(350.0, 700.0), Vector2(1080.0, 290.0)
]

# Match the river points used by the regional layout.
const RIVER_PATH := [
    Vector2(865.0, -985.0),
    Vector2(881.0, -755.0),
    Vector2(849.0, -475.0),
    Vector2(872.0, -215.0),
    Vector2(850.0, 70.0),
    Vector2(920.0, 400.0),
    Vector2(990.0, 995.0)
]

var broad_noise: FastNoiseLite
var detail_noise: FastNoiseLite

func _init() -> void:
    broad_noise = FastNoiseLite.new()
    broad_noise.seed = 10419
    broad_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
    broad_noise.frequency = 0.0016
    broad_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
    broad_noise.fractal_octaves = 4
    broad_noise.fractal_gain = 0.48

    detail_noise = FastNoiseLite.new()
    detail_noise.seed = 58133
    detail_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
    detail_noise.frequency = 0.005
    detail_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
    detail_noise.fractal_octaves = 3
    detail_noise.fractal_gain = 0.43

func _smooth(a: float, b: float, value: float) -> float:
    var p := clampf((value - a) / maxf(b - a, 0.0001), 0.0, 1.0)
    return p * p * (3.0 - 2.0 * p)

func _hill(x: float, z: float, center: Vector2, x_radius: float, z_radius: float, elevation: float) -> float:
    var dx := (x - center.x) / x_radius
    var dz := (z - center.y) / z_radius
    return elevation * exp(-2.0 * (dx * dx + dz * dz))

func river_distance(x: float, z: float) -> float:
    var sample := Vector2(x, z)
    var nearest := 1.0e12
    for i in range(RIVER_PATH.size() - 1):
        var a: Vector2 = RIVER_PATH[i]
        var b: Vector2 = RIVER_PATH[i + 1]
        var delta := b - a
        var projection := clampf((sample - a).dot(delta) / delta.length_squared(), 0.0, 1.0)
        nearest = minf(nearest, sample.distance_to(a + projection * delta))
    return nearest

func height_at(x: float, z: float) -> float:
    # Large rolling country, ridge to the northeast, rocky highland northwest,
    # and a low southern farmland/marsh basin.
    var broad := broad_noise.get_noise_2d(x, z)
    var detail := detail_noise.get_noise_2d(x, z)
    var elevation := 11.0 + broad * 10.0 + detail * 2.8
    elevation += _hill(x, z, Vector2(785.0, -745.0), 420.0, 365.0, 76.0)
    elevation += _hill(x, z, Vector2(-960.0, -750.0), 430.0, 385.0, 53.0)
    elevation += _hill(x, z, Vector2(-340.0, -940.0), 600.0, 220.0, 24.0)
    elevation += _hill(x, z, Vector2(300.0, 770.0), 365.0, 290.0, 15.0)
    elevation -= _hill(x, z, Vector2(-920.0, -145.0), 330.0, 260.0, 15.0)
    elevation = maxf(-3.0, elevation)

    # The river has a CUT riverbed, not a blue strip on a flat plane. A smooth
    # channel depression leaves visible banks on either side.
    var distance_to_river := river_distance(x, z)
    var valley := _smooth(34.0, 135.0, distance_to_river)
    elevation = lerpf(minf(elevation, -14.0), elevation, valley)

    # A flat installation reserve keeps the existing Station 04 hub centred
    # at y=0, ready to be integrated after the regional gameplay design.
    var hub_extent := maxf(absf(x), absf(z))
    elevation *= _smooth(142.0, 280.0, hub_extent)

    # Local pads, not sweeping levelled terrain: preserve the distinct hills
    # around future buildings and set reasonable heights for future props.
    for site in SITE_COORDS:
        var radial := Vector2(x, z).distance_to(site)
        if radial < 82.0:
            # Use a large-radius smooth elevation at the location as a
            # baseline and avoid flattening any area to world zero.
            var baseline := 11.0 + broad_noise.get_noise_2d(site.x, site.y) * 10.0
            if site.x > 700.0 and site.y < -550.0:
                baseline += 55.0
            if site.x < -800.0 and absf(site.y) < 300.0:
                baseline = 0.5
            elevation = lerpf(baseline, elevation, _smooth(24.0, 82.0, radial))

    # Two bridge abutments and their approach roads are graded to one deck
    # elevation. The span itself still hangs over the river channel.
    for landing_x in [760.0, 930.0]:
        var landing_distance := Vector2(x - landing_x, z - 70.0).length()
        if landing_distance < 52.0:
            elevation = lerpf(BRIDGE_DECK_HEIGHT, elevation,
                _smooth(14.0, 52.0, landing_distance))

    return elevation

func height_near(x: float, z: float, spacing: float = 4.0) -> Vector3:
    var step := maxf(spacing, 0.01)
    var east := height_at(x + step, z) - height_at(x - step, z)
    var south := height_at(x, z + step) - height_at(x, z - step)
    return Vector3(-east / (2.0 * step), 1.0, -south / (2.0 * step)).normalized()

# Return the exact height of the rendered triangulated terrain cell. Roads,
# markers and bridge landings use this instead of the smooth analytic profile
# so there can be no hovering caused by coarse terrain mesh interpolation.
func surface_height_at(x: float, z: float) -> float:
    var gx := clampf((x + WIDTH * 0.5) / GRID_STEP_X, 0.0, float(GRID_COLUMNS))
    var gz := clampf((z + DEPTH * 0.5) / GRID_STEP_Z, 0.0, float(GRID_ROWS))
    var ix := mini(int(floor(gx)), GRID_COLUMNS - 1)
    var iz := mini(int(floor(gz)), GRID_ROWS - 1)
    var tx := gx - float(ix)
    var tz := gz - float(iz)
    var x0 := -WIDTH * 0.5 + float(ix) * GRID_STEP_X
    var z0 := -DEPTH * 0.5 + float(iz) * GRID_STEP_Z

    var h00 := height_at(x0, z0)
    var h10 := height_at(x0 + GRID_STEP_X, z0)
    var h01 := height_at(x0, z0 + GRID_STEP_Z)
    var h11 := height_at(x0 + GRID_STEP_X, z0 + GRID_STEP_Z)
    if tx + tz <= 1.0:
        return h00 + (h10 - h00) * tx + (h01 - h00) * tz
    return h11 + (h01 - h11) * (1.0 - tx) + (h10 - h11) * (1.0 - tz)
