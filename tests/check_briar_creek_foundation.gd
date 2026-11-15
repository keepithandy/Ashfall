extends SceneTree
## Area 02 design smoke check. Does not change Crossroads or its save state.
## Run: godot --headless --path . --script res://tests/check_briar_creek_foundation.gd
const PROFILE = preload("res://scripts/briar_creek/briar_creek_profile.gd")

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    var issues: Array[String] = []
    if str(ProjectSettings.get_setting("application/run/main_scene")) != "res://scenes/crossroads_main.tscn":
        issues.append("Briar Creek must not replace the existing Crossroads main scene")
    var profile = PROFILE.new()
    if PROFILE.GRID_CELLS != 150 or not is_equal_approx(PROFILE.GRID_STEP,4.0):
        issues.append("Terrain must retain the declared 600m / 4m control grid")
    if PROFILE.SITES.size() != 7:
        issues.append("Expected seven named Briar Creek exploration sites")
    if PROFILE.ROUTES.size() != 6:
        issues.append("Expected three vehicle roads and three woodland footpaths")
    var ids := {}
    for site in PROFILE.SITES:
        var site_id := str(site["id"])
        if ids.has(site_id):
            issues.append("Duplicate site id: " + site_id)
        ids[site_id] = true
        if float(site["x"]) < 0.0 or float(site["x"]) > 600.0:
            issues.append("Site outside east/west boundary: " + site_id)
        if float(site["n"]) < 0.0 or float(site["n"]) > 600.0:
            issues.append("Site outside south/north boundary: " + site_id)
    for route in PROFILE.ROUTES:
        var points: Array = route["points"]
        for i in range(points.size() - 1):
            var a: Vector3 = points[i]
            var b: Vector3 = points[i + 1]
            var distance := Vector2(b.x-a.x,b.z-a.z).length()
            var grade := absf(b.y-a.y) / maxf(distance,0.001)
            var grade_limit := 0.085 if str(route["kind"])=="vehicle" else 0.125
            if grade > grade_limit:
                issues.append("Control-point grade exceeds target: " + str(route["id"]))
            if a.x < 0.0 or a.x > 600.0 or a.z < 0.0 or a.z > 600.0:
                issues.append("Route control point exceeds footprint: " + str(route["id"]))
    var scene := load("res://scenes/briar_creek/briar_creek_blockout.tscn") as PackedScene
    if scene == null:
        issues.append("Briar Creek blockout scene failed to load")
    else:
        var level := scene.instantiate()
        root.add_child(level)
        await process_frame
        var visual := level.get_node_or_null("Generated/WalkableTerrain/TerrainVisual") as MeshInstance3D
        var collision := level.get_node_or_null("Generated/WalkableTerrain/TerrainCollision") as CollisionShape3D
        var roads := level.get_node_or_null("Generated/RoadSurfaces") as Node3D
        var sites := level.get_node_or_null("Generated/SiteFootprintMarkers") as Node3D
        if visual == null or visual.mesh == null:
            issues.append("Missing generated terrain mesh")
        else:
            var arrays := visual.mesh.surface_get_arrays(0)
            var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
            var triangles: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
            if verts.size() != 22801 or triangles.size() != 135000:
                issues.append("Incorrect heightfield vertex/triangle topology")
        if collision == null or collision.shape == null:
            issues.append("Missing static collision matching terrain mesh")
        if roads == null or roads.get_child_count() != 6:
            issues.append("Missing road/path surface geometry")
        else:
            # Every adjacent road quad must meet on both banks of the
            # carriageway; the original separate-segment skins could leave
            # splits at bends and junction approaches.
            for route in PROFILE.ROUTES:
                var strip := roads.get_node_or_null(str(route["id"])) as MeshInstance3D
                if strip == null or strip.mesh == null:
                    issues.append("Missing visible route strip: " + str(route["id"]))
                    continue
                var road_arrays := strip.mesh.surface_get_arrays(0)
                var v: PackedVector3Array = road_arrays[Mesh.ARRAY_VERTEX]
                if v.size() < 6 or v.size() % 6 != 0:
                    issues.append("Invalid road triangle structure: " + str(route["id"]))
                    continue
                for k in range(0,v.size()-6,6):
                    if v[k+2].distance_to(v[k+6]) > 0.005 or v[k+4].distance_to(v[k+7]) > 0.005:
                        issues.append("Road strip has a gap or overlapped edge: " + str(route["id"]))
                        break
        if sites == null or sites.get_child_count() != 7:
            issues.append("Missing seven site footprint markers")
        level.queue_free()
    if issues.is_empty():
        print("BRIAR CREEK FOUNDATION: PASS (geometry smoke only; visual playtest outstanding)")
        quit(0)
    else:
        for issue in issues:
            push_error(issue)
        quit(1)
