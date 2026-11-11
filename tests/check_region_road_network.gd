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
        var collider := world.get_node_or_null("RegionGround/GroundCollider") as CollisionShape3D
        if collider == null:
            errors.append("Regional ground collision missing")
        elif collider.shape is BoxShape3D:
            var box := collider.shape as BoxShape3D
            if box.size.x < 2400.0 or box.size.z < 2000.0:
                errors.append("Region footprint smaller than 2.4 km x 2.0 km")
        world.queue_free()

    if errors.is_empty():
        print("ASHFALL ROAD NETWORK CHECK PASSED")
        print("Five editable road models + gallery, sixteen routes and ten area anchors")
        print("Manual Godot 3D / F6 performance and visual verification still required")
        quit(0)
    else:
        for issue in errors:
            push_error(issue)
        print("ASHFALL ROAD NETWORK CHECK FAILED: ", errors.size(), " issue(s)")
        quit(1)
