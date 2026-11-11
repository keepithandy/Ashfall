@tool
extends Node3D
## Visual regional road plan based on the Station 04 expanded-area concept.
## This is a separate map-preview scene: it does not load gameplay or replace F5.
## Approximate map footprint: X [-1200,1200], Z [-1000,1000], surface Y=0.

const ROAD = preload("res://scenes/roads/road_straight.tscn")
const BRIDGE = preload("res://scenes/roads/road_service_bridge.tscn")
const RIVER_MATERIAL = preload("res://assets/roads/dark_river.tres")
const ROAD_MATERIAL = preload("res://assets/roads/worn_road.tres")
const PROFILE = preload("res://scripts/roads/region_height_profile.gd")

var terrain_profile = PROFILE.new()

# All route nodes are in map metres. The same node used by multiple paths is
# a future junction; roads intentionally avoid occupied Station 04 interiors.
const ROUTES = [
    {"name": "Station_Hub_Spine", "points": [Vector3(0, 0, -130), Vector3(0, 0, -55), Vector3(0, 0, 55), Vector3(0, 0, 130)], "width": 6.8},
    {"name": "Station_North_Exit", "points": [Vector3(0, 0, -130), Vector3(0, 0, -220), Vector3(-30, 0, -320)], "width": 6.8},
    {"name": "Station_South_Exit", "points": [Vector3(0, 0, 130), Vector3(0, 0, 210), Vector3(0, 0, 320)], "width": 6.8},
    {"name": "Northern_Industrial_Route", "points": [Vector3(-30, 0, -320), Vector3(-230, 0, -455), Vector3(-500, 0, -610), Vector3(-720, 0, -700)], "width": 6.0},
    {"name": "Anomaly_Access_Track", "points": [Vector3(-30, 0, -320), Vector3(-112, 0, -585), Vector3(-170, 0, -820)], "width": 4.5},
    {"name": "Relay_Service_Road", "points": [Vector3(-30, 0, -320), Vector3(160, 0, -415), Vector3(320, 0, -490)], "width": 5.6},
    {"name": "Signal_Ridge_Climb", "points": [Vector3(320, 0, -490), Vector3(540, 0, -600), Vector3(680, 0, -705), Vector3(800, 0, -780)], "width": 4.7},
    {"name": "West_Marsh_Road", "points": [Vector3(0, 0, 210), Vector3(-230, 0, 80), Vector3(-510, 0, -70), Vector3(-745, 0, -163), Vector3(-920, 0, -150)], "width": 5.2},
    {"name": "Forest_West_Loop", "points": [Vector3(-500, 0, -610), Vector3(-770, 0, -480), Vector3(-840, 0, -345), Vector3(-920, 0, -150)], "width": 4.4},
    {"name": "Farmsteads_Lane", "points": [Vector3(0, 0, 320), Vector3(-218, 0, 405), Vector3(-440, 0, 540), Vector3(-760, 0, 650)], "width": 4.5},
    {"name": "Crash_Site_Road", "points": [Vector3(0, 0, 320), Vector3(160, 0, 470), Vector3(350, 0, 700)], "width": 4.5},
    {"name": "South_Riverside_Track", "points": [Vector3(350, 0, 700), Vector3(545, 0, 495), Vector3(620, 0, 270)], "width": 4.5},
    {"name": "Bridge_West_Approach", "points": [Vector3(160, 0, 470), Vector3(425, 0, 385), Vector3(620, 0, 270), Vector3(760, 0, 70)], "width": 5.6},
    {"name": "North_Riverside_Service", "points": [Vector3(320, 0, -490), Vector3(555, 0, -235), Vector3(690, 0, -58), Vector3(760, 0, 70)], "width": 5.1},
    {"name": "Tunnel_East_Approach", "points": [Vector3(930, 0, 70), Vector3(1010, 0, 140), Vector3(1080, 0, 290)], "width": 5.6},
    {"name": "River_Mill_Spur", "points": [Vector3(1080, 0, 290), Vector3(1090, 0, 530), Vector3(1015, 0, 760)], "width": 4.2}
]

const RIVER_POINTS = [
    Vector3(865, 0, -985),
    Vector3(881, 0, -755),
    Vector3(849, 0, -475),
    Vector3(872, 0, -215),
    Vector3(850, 0, 70),
    Vector3(920, 0, 400),
    Vector3(990, 0, 995)
]

const SITES = [
    {"name": "STATION 04 / HUB", "point": Vector3(0, 0, 0), "radius": 16.0, "tint": Color(0.68, 0.74, 0.63)},
    {"name": "INDUSTRIAL PLANT", "point": Vector3(-720, 0, -700), "radius": 12.0, "tint": Color(0.63, 0.56, 0.43)},
    {"name": "ANOMALY FIELD", "point": Vector3(-170, 0, -820), "radius": 12.0, "tint": Color(0.56, 0.59, 0.78)},
    {"name": "NORTH RELAY", "point": Vector3(320, 0, -490), "radius": 12.0, "tint": Color(0.65, 0.62, 0.44)},
    {"name": "SIGNAL RIDGE", "point": Vector3(800, 0, -780), "radius": 12.0, "tint": Color(0.75, 0.49, 0.40)},
    {"name": "MARSH OUTPOST", "point": Vector3(-920, 0, -150), "radius": 12.0, "tint": Color(0.43, 0.62, 0.51)},
    {"name": "FARMSTEADS", "point": Vector3(-760, 0, 650), "radius": 12.0, "tint": Color(0.70, 0.65, 0.42)},
    {"name": "CRASH CLEARING", "point": Vector3(350, 0, 700), "radius": 12.0, "tint": Color(0.69, 0.45, 0.37)},
    {"name": "BRIDGE CROSSING", "point": Vector3(845, 0, 70), "radius": 10.0, "tint": Color(0.63, 0.60, 0.53)},
    {"name": "EAST TUNNEL", "point": Vector3(1080, 0, 290), "radius": 12.0, "tint": Color(0.61, 0.61, 0.57)}
]

@export var show_area_labels := true:
    set(value):
        show_area_labels = value
        _rebuild()

@export var show_river := true:
    set(value):
        show_river = value
        _rebuild()

func _ready() -> void:
    _rebuild()

func _add_route(parent: Node3D, route: Dictionary) -> void:
    var road: Node3D = ROAD.instantiate()
    road.name = String(route["name"])
    road.set("path_points", PackedVector3Array(route["points"]))
    road.set("road_width", float(route["width"]))
    road.set("follow_region_terrain", true)
    parent.add_child(road)

func _new_site(parent: Node3D, info: Dictionary) -> void:
    var position_3d: Vector3 = info["point"]
    var pad := MeshInstance3D.new()
    pad.name = String(info["name"]).replace(" ", "_").replace("/", "_") + "_Marker"
    var cylinder := CylinderMesh.new()
    cylinder.top_radius = float(info["radius"])
    cylinder.bottom_radius = float(info["radius"])
    cylinder.height = 0.08
    pad.mesh = cylinder
    var pad_height: float = terrain_profile.surface_height_at(position_3d.x, position_3d.z)
    if String(info["name"]) == "BRIDGE CROSSING":
        pad_height = PROFILE.BRIDGE_DECK_HEIGHT
    pad.position = Vector3(position_3d.x, pad_height + 0.075, position_3d.z)
    var mat := StandardMaterial3D.new()
    mat.albedo_color = info["tint"]
    mat.roughness = 1.0
    pad.material_override = mat
    pad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    parent.add_child(pad)

    if show_area_labels:
        var label := Label3D.new()
        label.name = pad.name + "_Label"
        label.text = String(info["name"])
        label.font_size = 42
        label.pixel_size = 0.80
        label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
        label.modulate = Color(0.93, 0.93, 0.84)
        label.outline_modulate = Color(0.07, 0.09, 0.09)
        label.outline_size = 8
        label.position = Vector3(position_3d.x, pad_height + 9.0, position_3d.z)
        parent.add_child(label)

func _junction_cap(parent: Node3D, at: Vector3, width: float) -> void:
    # Rounded junction surface samples the actual terrain across its radius,
    # rather than placing a flat raised cylinder into a sloping hillside.
    var radius := width * 0.6
    var mesh := SurfaceTool.new()
    mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
    mesh.set_material(ROAD_MATERIAL)
    var sectors := 16
    var centre_height := terrain_profile.surface_height_at(at.x, at.z) + 0.045
    var centre := Vector3(at.x, centre_height, at.z)
    for index in range(sectors):
        var a := TAU * float(index) / float(sectors)
        var b := TAU * float(index + 1) / float(sectors)
        var p1 := Vector2(cos(a), sin(a)) * radius
        var p2 := Vector2(cos(b), sin(b)) * radius
        var v1 := Vector3(at.x + p1.x,
            terrain_profile.surface_height_at(at.x + p1.x, at.z + p1.y) + 0.045,
            at.z + p1.y)
        var v2 := Vector3(at.x + p2.x,
            terrain_profile.surface_height_at(at.x + p2.x, at.z + p2.y) + 0.045,
            at.z + p2.y)
        for vertex in [centre, v2, v1]:
            mesh.set_normal(Vector3.UP)
            mesh.set_uv(Vector2(vertex.x / 5.0, vertex.z / 5.0))
            mesh.add_vertex(vertex)
    var disk := MeshInstance3D.new()
    disk.name = "RouteJoin"
    disk.mesh = mesh.commit()
    disk.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    parent.add_child(disk)

func _rebuild() -> void:
    if not is_inside_tree():
        return
    for child in get_children():
        if child.get_meta("ashfall_region_generated", false):
            child.free()

    var container := Node3D.new()
    container.name = "GeneratedRoadsAndAreaAnchors"
    container.set_meta("ashfall_region_generated", true)
    add_child(container)

    if show_river:
        var river: Node3D = ROAD.instantiate()
        river.name = "EasternRiver_VisualOnly"
        var river_points := PackedVector3Array()
        for point in RIVER_POINTS:
            river_points.append(Vector3(point.x, PROFILE.WATER_LEVEL, point.z))
        river.set("path_points", river_points)
        river.set("road_width", 100.0)
        river.set("shoulder_width", 0.0)
        river.set("surface_height", 0.012)
        river.set("surface_material", RIVER_MATERIAL)
        container.add_child(river)

    for route in ROUTES:
        _add_route(container, route)

    # Cap intersections so independently authored splines do not have gaps.
    for location in [
        Vector3(-30, 0, -320), Vector3(-500, 0, -610),
        Vector3(320, 0, -490), Vector3(0, 0, 320),
        Vector3(160, 0, 470), Vector3(620, 0, 270),
        Vector3(760, 0, 70), Vector3(-920, 0, -150)
    ]:
        _junction_cap(container, location, 6.5)

    var bridge: Node3D = BRIDGE.instantiate()
    bridge.name = "EasternServiceBridge"
    bridge.set("span_length", 170.0)
    bridge.position = Vector3(845, PROFILE.BRIDGE_DECK_HEIGHT, 70)
    container.add_child(bridge)

    for info in SITES:
        _new_site(container, info)

func _process(delta: float) -> void:
    if Engine.is_editor_hint():
        return
    var camera := get_node_or_null("OverviewCamera") as Camera3D
    if camera == null:
        return
    var input_dir := Vector2.ZERO
    if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
        input_dir.x -= 1.0
    if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
        input_dir.x += 1.0
    if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
        input_dir.y -= 1.0
    if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
        input_dir.y += 1.0
    if input_dir.length_squared() > 0.0:
        var pan_speed := camera.size * 0.45
        camera.position.x = clampf(camera.position.x + input_dir.normalized().x * pan_speed * delta, -1170.0, 1170.0)
        camera.position.z = clampf(camera.position.z + input_dir.normalized().y * pan_speed * delta, -980.0, 980.0)

func _unhandled_input(event: InputEvent) -> void:
    if Engine.is_editor_hint():
        return
    if event is InputEventMouseButton and event.pressed:
        var camera := get_node_or_null("OverviewCamera") as Camera3D
        if camera == null:
            return
        if event.button_index == MOUSE_BUTTON_WHEEL_UP:
            camera.size = maxf(260.0, camera.size / 1.2)
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            camera.size = minf(2400.0, camera.size * 1.2)
