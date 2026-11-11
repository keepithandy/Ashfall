extends SceneTree
## Road kit and regional layout smoke check.
## godot --headless --path . --script res://tests/check_region_road_network.gd
const KIT := [
    "res://scenes/roads/road_straight.tscn",
    "res://scenes/roads/road_bend.tscn",
    "res://scenes/roads/road_t_junction.tscn",
    "res://scenes/roads/road_crossroads.tscn",
    "res://scenes/roads/road_service_bridge.tscn",
    "res://scenes/roads/road_model_gallery.tscn"
]
const SITES := [
    "STATION_04___HUB_Marker",
    "INDUSTRIAL_PLANT_Marker",
    "ANOMALY_FIELD_Marker",
    "NORTH_RELAY_Marker",
    "SIGNAL_RIDGE_Marker",
    "MARSH_OUTPOST_Marker",
    "FARMSTEADS_Marker",
    "CRASH_CLEARING_Marker",
    "BRIDGE_CROSSING_Marker",
    "EAST_TUNNEL_Marker"
]
const ROUTES := [
    "Station_Hub_Spine",
    "Station_North_Exit",
    "Station_South_Exit",
    "Northern_Industrial_Route",
    "Anomaly_Access_Track",
    "Relay_Service_Road",
    "Signal_Ridge_Climb",
    "West_Marsh_Road",
    "Forest_West_Loop",
    "Farmsteads_Lane",
    "Crash_Site_Road",
    "South_Riverside_Track",
    "Bridge_West_Approach",
    "North_Riverside_Service",
    "Tunnel_East_Approach",
    "River_Mill_Spur"
]

func _initialize() -> void:
    call_deferred("_run_checks")

func _run_checks() -> void:
    var errors: Array[String] = []
    for scene_path in KIT:
        var kit_scene := load(scene_path) as PackedScene
        if kit_scene == null:
            errors.append("Cannot load road prefab: " + scene_path)
            continue
        var piece := kit_scene.instantiate()
        root.add_child(piece)
        if piece.get_script() != null and not piece.has_node("CompactedRoadSurface") and scene_path.ends_with("road_straight.tscn"):
            errors.append("Straight road did not create its visual road surface")
        piece.queue_free()

    var packed := load("res://scenes/world/ashfall_region_roads.tscn") as PackedScene
    if packed == null:
        errors.append("Regional road layout cannot load")
    else:
        var world := packed.instantiate() as Node3D
        root.add_child(world)
        var layout: Node3D = world.get_node_or_null("GeneratedRoadsAndAreaAnchors")
        if layout == null:
            errors.append("Procedural road network was not created")
        else:
            for route_name in ROUTES:
                var road := layout.get_node_or_null(route_name) as Node3D
                if road == null:
                    errors.append("Missing road route: " + route_name)
                elif road.get_node_or_null("CompactedRoadSurface") == null:
                    errors.append("Road surface missing: " + route_name)
            for site in SITES:
                if layout.get_node_or_null(site) == null:
                    errors.append("Area destination marker missing: " + site)
            if layout.get_node_or_null("EasternRiver_VisualOnly") == null:
                errors.append("River corridor missing")
            if layout.get_node_or_null("EasternServiceBridge/BridgeDeckAndCollision/DeckCollision") == null:
                errors.append("Bridge collision missing")
        var cam := world.get_node_or_null("OverviewCamera") as Camera3D
        if cam == null or cam.projection != Camera3D.PROJECTION_ORTHOGONAL:
            errors.append("Overview camera missing or not orthogonal")
        var ground := world.get_node_or_null("RegionGround") as StaticBody3D
        var visual := world.get_node_or_null("RegionGround/HeightfieldVisual") as MeshInstance3D
        var collider := world.get_node_or_null("RegionGround/HeightfieldCollision") as CollisionShape3D
        if ground == null or visual == null or collider == null:
            errors.append("Regional heightfield mesh or collision is missing")
        else:
            if visual.mesh == null or visual.mesh.get_surface_count() == 0:
                errors.append("Heightfield visual has no generated triangles")
            if not (collider.shape is ConcavePolygonShape3D):
                errors.append("Heightfield collision is not generated from the terrain triangle mesh")
            var station_y: float = ground.call("get_height", 0.0, 0.0)
            var ridge_y: float = ground.call("get_height", 800.0, -780.0)
            var marsh_y: float = ground.call("get_height", -920.0, -150.0)
            var riverbed_y: float = ground.call("get_height", 850.0, 70.0)
            if absf(station_y) > 0.1:
                errors.append("Station 04 central reserve is no longer at world height zero")
            if ridge_y < station_y + 30.0:
                errors.append("Signal ridge elevation is too flat for an elevated terrain area")
            if marsh_y > 8.0:
                errors.append("Western marsh region is no longer lowland")
            if riverbed_y > -6.0:
                errors.append("The river corridor is not carved into the heightfield")
            if layout != null:
                var approach := layout.get_node_or_null("Station_North_Exit/CompactedRoadSurface") as MeshInstance3D
                if approach != null and approach.mesh != null:
                    var road_vertices: PackedVector3Array = approach.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
                    if not road_vertices.is_empty():
                        var first: Vector3 = road_vertices[0]
                        var expected: float = ground.call("get_height", first.x, first.z)
                        if absf(first.y - expected - 0.036) > 0.08:
                            errors.append("North road strip is not seated against the rendered terrain")
                var bridge := layout.get_node_or_null("EasternServiceBridge") as Node3D
                if bridge != null and absf(bridge.position.y - 7.5) > 0.1:
                    errors.append("Bridge deck is not raised over the carved river valley")
        world.queue_free()

    if errors.is_empty():
        print("ASHFALL ROAD NETWORK CHECK PASSED")
        print("Five road models, sixteen terrain-aligned routes, ten elevated area anchors and heightfield collision")
        print("Manual Godot 3D / F6 performance and visual verification still required")
        quit(0)
    else:
        for issue in errors:
            push_error(issue)
        print("ASHFALL ROAD NETWORK CHECK FAILED: ", errors.size(), " issue(s)")
        quit(1)
