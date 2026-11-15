extends RefCounted
## Area 02 — Briar Creek deterministic design control points.
## Design map uses east X=0..600 and north N=0..600. In Godot use X-300 and Z=300-N.
const SIZE := 600.0
const GRID_STEP := 4.0
const GRID_CELLS := 150
const SITES := [
    {"id":"checkpoint","name":"Southern checkpoint","x":305.0,"n":65.0,"y":5.0,"w":4.0,"d":4.0},
    {"id":"mill","name":"Hawkins Lumber Mill (working name)","x":350.0,"n":305.0,"y":18.0,"w":28.0,"d":14.0},
    {"id":"cabins","name":"Workers' cabins","x":145.0,"n":390.0,"y":23.0,"w":8.0,"d":6.0},
    {"id":"depot","name":"Equipment depot","x":470.0,"n":445.0,"y":32.0,"w":16.0,"d":12.0},
    {"id":"lookout","name":"Northern lookout","x":335.0,"n":550.0,"y":60.0,"w":5.0,"d":5.0},
    {"id":"creek","name":"Creek crossing","x":110.0,"n":245.0,"y":8.0,"w":3.0,"d":3.0},
    {"id":"clearing","name":"Logging clearing","x":220.0,"n":460.0,"y":30.0,"w":8.0,"d":5.0}
]
## Vector3(design X, design elevation, design N).
const ROUTES := [
    {"id":"R01","name":"South access to mill","width":5.5,"kind":"vehicle","points":[
        Vector3(305,4,0), Vector3(305,5,65), Vector3(310,7,100),
        Vector3(325,10,145), Vector3(345,12,190), Vector3(365,15,245),
        Vector3(350,18,305)]},
    {"id":"R02","name":"Mill to equipment depot","width":4.5,"kind":"vehicle","points":[
        Vector3(350,18,305), Vector3(405,21,340), Vector3(448,25,380),
        Vector3(495,29,415), Vector3(470,32,445)]},
    {"id":"R03","name":"Workers' cabin road","width":3.7,"kind":"vehicle","points":[
        Vector3(325,10,145), Vector3(285,13,200), Vector3(230,17,260),
        Vector3(190,20,320), Vector3(145,23,390)]},
    {"id":"P01","name":"Depot to lookout footpath","width":1.6,"kind":"footpath","points":[
        Vector3(470,32,445), Vector3(465,36,488), Vector3(408,40,495),
        Vector3(388,44,525), Vector3(330,47,510), Vector3(290,52,542),
        Vector3(290,56,585), Vector3(335,60,550)]},
    {"id":"P02","name":"Cabins to creek pump path","width":1.6,"kind":"footpath","points":[
        Vector3(145,23,390), Vector3(170,20,355), Vector3(155,17,315),
        Vector3(172,14,285), Vector3(142,11,263), Vector3(110,8,245)]},
    {"id":"P03","name":"Mill to logged clearing path","width":1.5,"kind":"footpath","points":[
        Vector3(350,18,305), Vector3(365,18,350),
        Vector3(320,21,380), Vector3(270,25,410),
        Vector3(220,30,460)]}
]
const PADS := [
    {"x":305.0,"n":65.0,"y":5.0,"inner":13.0,"outer":29.0},
    {"x":350.0,"n":305.0,"y":18.0,"inner":59.0,"outer":88.0},
    {"x":145.0,"n":390.0,"y":23.0,"inner":42.0,"outer":64.0},
    {"x":470.0,"n":445.0,"y":32.0,"inner":33.0,"outer":60.0},
    {"x":335.0,"n":550.0,"y":60.0,"inner":12.0,"outer":28.0}
]

func to_world(design_x: float, north: float, elevation: float = 0.0) -> Vector3:
    return Vector3(design_x - 300.0, elevation, 300.0 - north)

func _smooth(a: float, b: float, value: float) -> float:
    var t := clampf((value - a) / maxf(b - a, 0.001), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)

func creek_x(north: float) -> float:
    return 100.0 + 10.0 * sin(north * 0.015)

func _natural_height(x: float, north: float) -> float:
    var h := 5.0 + north * 0.026 + 1.1 * sin(x * 0.015) * cos(north * 0.016)
    var creek_distance := (x - creek_x(north)) / 33.0
    h -= 7.0 * exp(-creek_distance * creek_distance)
    var ridge_x := (x - 335.0) / 170.0
    h += 42.0 * _smooth(330.0, 600.0, north) * (0.6 + 0.4 * exp(-ridge_x * ridge_x))
    h += 8.0 * _smooth(360.0, 570.0, x) * _smooth(270.0, 530.0, north)
    return h

func height_at(world_x: float, world_z: float) -> float:
    var design_x := world_x + 300.0
    var north := 300.0 - world_z
    var h := _natural_height(design_x, north)
    for pad in PADS:
        var radius := Vector2(design_x - float(pad["x"]), north - float(pad["n"])).length()
        var blend := 1.0 - _smooth(float(pad["inner"]), float(pad["outer"]), radius)
        h = lerpf(h, float(pad["y"]), blend)
    # Grade footpaths first, then vehicle roads. A nearest-route-only
    # selection can let a narrow footpath override the carriageway at a
    # crossing, causing a severe, localized driving-grade discontinuity.
    # Separate smooth shoulder blends preserve the existing centerlines
    # while allowing vehicle access to take precedence at intersections.
    var nearest_foot := INF
    var nearest_vehicle := INF
    var foot_target := h
    var vehicle_target := h
    var foot_width := 1.6
    var vehicle_width := 5.0
    for route in ROUTES:
        var points: Array = route["points"]
        var is_vehicle := str(route["kind"]) == "vehicle"
        for i in range(points.size() - 1):
            var a: Vector3 = points[i]
            var b: Vector3 = points[i + 1]
            var start := Vector2(a.x, a.z)
            var delta := Vector2(b.x, b.z) - start
            var t := clampf((Vector2(design_x, north) - start).dot(delta) / maxf(delta.length_squared(), 0.001), 0.0, 1.0)
            var distance := Vector2(design_x, north).distance_to(start + delta * t)
            if is_vehicle:
                if distance < nearest_vehicle:
                    nearest_vehicle = distance
                    vehicle_target = lerpf(a.y, b.y, t)
                    vehicle_width = float(route["width"])
            elif distance < nearest_foot:
                nearest_foot = distance
                foot_target = lerpf(a.y, b.y, t)
                foot_width = float(route["width"])
    var foot_blend := 1.0 - _smooth(foot_width * 0.5 + 0.6, foot_width * 0.5 + 16.0, nearest_foot)
    h = lerpf(h, foot_target, foot_blend)
    var vehicle_blend := 1.0 - _smooth(vehicle_width * 0.5 + 0.6, vehicle_width * 0.5 + 9.0, nearest_vehicle)
    h = lerpf(h, vehicle_target, vehicle_blend)
    return h

func surface_height_at(world_x: float, world_z: float) -> float:
    # Interpolate the SAME triangles as the terrain mesh and collision.
    var gx := clampf((world_x + 300.0) / GRID_STEP, 0.0, GRID_CELLS - 0.00001)
    var gz := clampf((world_z + 300.0) / GRID_STEP, 0.0, GRID_CELLS - 0.00001)
    var ix := floori(gx)
    var iz := floori(gz)
    var tx := gx - ix
    var tz := gz - iz
    var x0 := -300.0 + ix * GRID_STEP
    var z0 := -300.0 + iz * GRID_STEP
    var h00 := height_at(x0, z0)
    var h10 := height_at(x0 + GRID_STEP, z0)
    var h01 := height_at(x0, z0 + GRID_STEP)
    var h11 := height_at(x0 + GRID_STEP, z0 + GRID_STEP)
    if tx + tz <= 1.0:
        return h00 + (h10 - h00) * tx + (h01 - h00) * tz
    return h11 + (h01 - h11) * (1.0 - tx) + (h10 - h11) * (1.0 - tz)
