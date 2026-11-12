extends RefCounted
## Shared map geometry and homestead dimensions for Crossroads 2.3.
## North=-Z, east=+X. All coordinates are metres.
## Hand-set occupancy and road points, not random city generation.

const WIDTH := 360.0
const DEPTH := 420.0
const SPACING := 2.0
const COLUMNS := 180
const ROWS := 210
const MAIN_WIDTH := 5.8
const TRACK_WIDTH := 3.25

const HOMES := [
    {"name": "SouthWhiteYard", "x": -31.0, "z": 143.0, "kind": "white", "side": -1, "yaw": 1.57, "garden": "chicken-yard"},
    {"name": "BlueSillSouth", "x": 30.0, "z": 122.0, "kind": "blue_sill", "side": 1, "yaw": -1.57, "garden": "small-vegetable"},
    {"name": "LonghouseNorthGarden", "x": -33.0, "z": 92.0, "kind": "green", "side": -1, "yaw": 1.53, "garden": "firewood"},
    {"name": "OchreOrchard", "x": 31.0, "z": 66.0, "kind": "ochre", "side": 1, "yaw": -1.61, "garden": "orchard"},
    {"name": "BrickAndLeanTo", "x": -32.0, "z": 40.0, "kind": "lane_brick", "side": -1, "yaw": 1.62, "garden": "workyard"},
    {"name": "GreenWellsYard", "x": 32.0, "z": 9.0, "kind": "green", "side": 1, "yaw": -1.52, "garden": "well"},
    {"name": "WornWhiteHouse", "x": -30.0, "z": -16.0, "kind": "white", "side": -1, "yaw": 1.48, "garden": "laundry"},
    {"name": "BluePorchNorth", "x": 31.0, "z": -47.0, "kind": "blue_sill", "side": 1, "yaw": -1.64, "garden": "vegetable"},
    {"name": "OchreCollapsedFence", "x": -32.0, "z": -73.0, "kind": "ochre", "side": -1, "yaw": 1.55, "garden": "bramble"},
    {"name": "TheOldBrick", "x": 30.0, "z": -105.0, "kind": "lane_brick", "side": 1, "yaw": -1.50, "garden": "equipment"},
    {"name": "LastGreenCottage", "x": -33.0, "z": -130.0, "kind": "green", "side": -1, "yaw": 1.63, "garden": "garden"},
    {"name": "NorthernWhiteResidence", "x": 32.0, "z": -160.0, "kind": "white", "side": 1, "yaw": -1.53, "garden": "stacked-wood"}
]

const MAIN_ROAD = [
    # Uninterrupted country road keeps going beyond the village; avoid a
    # dead-end texture edge in the 650m camera view.
    Vector2(-3.0, -730.0), Vector2(-5.0, -570.0),
    Vector2(-4.0, -390.0), Vector2(-2.0, -206.0),
    Vector2(-4.0, -160.0), Vector2(-1.0, -108.0),
    Vector2(2.0, -55.0), Vector2(4.0, 9.0), Vector2(2.0, 67.0),
    Vector2(-3.0, 127.0), Vector2(-2.0, 206.0),
    Vector2(1.0, 380.0), Vector2(-1.0, 570.0), Vector2(3.0, 730.0)
]
const WEST_CART_TRACK = [
    Vector2(-2.0, 198.0), Vector2(-28.0, 195.0), Vector2(-87.0, 192.0),
    Vector2(-96.0, 128.0), Vector2(-94.0, 59.0), Vector2(-94.0, -20.0),
    Vector2(-90.0, -98.0), Vector2(-89.0, -188.0), Vector2(-29.0, -199.0),
    Vector2(-4.0, -205.0)
]
const EAST_FARM_LANE = [
    Vector2(-2.0, 198.0), Vector2(26.0, 194.0), Vector2(93.0, 187.0),
    Vector2(97.0, 117.0), Vector2(99.0, 47.0), Vector2(96.0, -32.0),
    Vector2(94.0, -111.0), Vector2(92.0, -195.0), Vector2(25.0, -200.0),
    Vector2(-4.0, -205.0)
]

var noise: FastNoiseLite


func _init() -> void:
    noise = FastNoiseLite.new()
    noise.seed = 233742
    noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
    noise.frequency = 0.010
    noise.fractal_type = FastNoiseLite.FRACTAL_FBM
    noise.fractal_octaves = 3
    noise.fractal_gain = 0.45


func _smooth(a: float, b: float, value: float) -> float:
    var f := clampf((value - a) / maxf(0.01, b - a), 0.0, 1.0)
    return f * f * (3.0 - 2.0 * f)


func _base(x: float, z: float) -> float:
    var slope := 0.0045 * z + 0.003 * x
    var undulation := 0.65 * sin(x * 0.022 + 0.6) * sin(z * 0.015 - 0.4)
    var low_country := 0.45 * noise.get_noise_2d(x, z)
    var raised_west := 1.8 * exp(-0.00050 * ((x + 138.0) * (x + 138.0) + (z - 95.0) * (z - 95.0)))
    var raised_east := 1.3 * exp(-0.00062 * ((x - 142.0) * (x - 142.0) + (z + 90.0) * (z + 90.0)))
    return slope + undulation + low_country + raised_west + raised_east


func main_road_x(z: float) -> float:
    for i in range(MAIN_ROAD.size() - 1):
        var a: Vector2 = MAIN_ROAD[i]
        var b: Vector2 = MAIN_ROAD[i + 1]
        if z >= a.y and z <= b.y:
            return lerpf(a.x, b.x, (z - a.y) / (b.y - a.y))
    return MAIN_ROAD[0].x if z < MAIN_ROAD[0].y else MAIN_ROAD[MAIN_ROAD.size() - 1].x


func _site_footprint(site: Dictionary) -> Vector2:
    # Half extents of the actual existing house foundations (or the two
    # Crossroads modular floor plans), including a small earth apron.
    match str(site["kind"]):
        "white":
            return Vector2(4.65, 5.15)
        "green":
            return Vector2(6.15, 3.65)
        "ochre":
            return Vector2(4.15, 4.15)
        "blue_sill":
            return Vector2(6.0, 4.0)
        "lane_brick":
            return Vector2(4.0, 6.0)
    return Vector2(6.0, 6.0)


func site_floor_height(site: Dictionary) -> float:
    # Terrain sits slightly below the prefab's floor/foundation datum.
    # The house itself is placed 4 cm above this pad in crossroads_village.
    return _base(float(site["x"]), float(site["z"])) - 0.045


func house_pad_weight(site: Dictionary, x: float, z: float) -> float:
    var dx := x - float(site["x"])
    var dz := z - float(site["z"])
    var yaw := float(site["yaw"])
    # Inverse of Node3D's yaw: local X / local Z aligned with the real walls.
    var local_x := cos(yaw) * dx - sin(yaw) * dz
    var local_z := sin(yaw) * dx + cos(yaw) * dz
    var extents := _site_footprint(site)
    var outside := maxf(absf(local_x) - extents.x, absf(local_z) - extents.y)
    # Keep the footprint + 1.2 m of surrounding soil level, then feather
    # naturally out over 9 m; no radial mounds beneath wall corners.
    return 1.0 - _smooth(1.2, 10.0, maxf(0.0, outside))


func height_at(x: float, z: float) -> float:
    var base := _base(x, z)
    # Preserve a graded crown and shoulders on the main road. The asphalt
    # uses this same physical height profile, not a raised fake collision.
    var road_x := main_road_x(z)
    var road_grade := _base(road_x, z) + 0.040
    base = lerpf(road_grade, base, _smooth(3.6, 11.0, absf(x - road_x)))
    for site in HOMES:
        var influence := house_pad_weight(site, x, z)
        if influence > 0.0:
            base = lerpf(base, site_floor_height(site), influence)
    return base

func outer_height_at(x: float, z: float) -> float:
    # Distant open farmland connects exactly to the walkable village rim,
    # without a cliff or black void. Physical outer-country mesh uses this
    # same function; the main 2m settlement heightfield is unchanged.
    var rim_x := clampf(x, -WIDTH * 0.5, WIDTH * 0.5)
    var rim_z := clampf(z, -DEPTH * 0.5, DEPTH * 0.5)
    var outside := maxf(
        maxf(absf(x) - WIDTH * 0.5, 0.0),
        maxf(absf(z) - DEPTH * 0.5, 0.0)
    )
    var fade := _smooth(0.0, 140.0, outside)
    var country_roll := 3.1 * sin(x * 0.009 + 0.6) * sin(z * 0.011 - 0.3)
    var farmland_rise := 4.5 * noise.get_noise_2d(x * 0.7, z * 0.7)
    return height_at(rim_x, rim_z) + fade * (country_roll + farmland_rise)


func surface_height_at(x: float, z: float) -> float:
    if absf(x) > WIDTH * 0.5 or absf(z) > DEPTH * 0.5:
        return outer_height_at(x, z)
    # The same two triangle halves used by CrossroadsGround.
    var dx := WIDTH / float(COLUMNS)
    var dz := DEPTH / float(ROWS)
    var gx := clampf((x + WIDTH * 0.5) / dx, 0.0, float(COLUMNS) - 0.000001)
    var gz := clampf((z + DEPTH * 0.5) / dz, 0.0, float(ROWS) - 0.000001)
    var ix := int(floor(gx))
    var iz := int(floor(gz))
    var tx := gx - float(ix)
    var tz := gz - float(iz)
    var x0 := -WIDTH * 0.5 + float(ix) * dx
    var z0 := -DEPTH * 0.5 + float(iz) * dz
    var h00 := height_at(x0, z0)
    var h10 := height_at(x0 + dx, z0)
    var h01 := height_at(x0, z0 + dz)
    var h11 := height_at(x0 + dx, z0 + dz)
    if tx + tz <= 1.0:
        return h00 + (h10 - h00) * tx + (h01 - h00) * tz
    return h11 + (h01 - h11) * (1.0 - tx) + (h10 - h11) * (1.0 - tz)


func distance_to_line(point: Vector2, route: Array) -> float:
    var closest := INF
    for i in range(route.size() - 1):
        var a: Vector2 = route[i]
        var b: Vector2 = route[i + 1]
        var v := b - a
        var t := clampf((point - a).dot(v) / maxf(v.length_squared(), 0.01), 0, 1)
        closest = minf(closest, point.distance_to(a + v * t))
    return closest


func is_thoroughfare(x: float, z: float, margin: float = 0.0) -> bool:
    var at := Vector2(x, z)
    if distance_to_line(at, MAIN_ROAD) < MAIN_WIDTH * 0.5 + 2.6 + margin:
        return true
    if distance_to_line(at, WEST_CART_TRACK) < TRACK_WIDTH * 0.5 + 2.0 + margin:
        return true
    return distance_to_line(at, EAST_FARM_LANE) < TRACK_WIDTH * 0.5 + 2.0 + margin
