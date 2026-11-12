extends SceneTree
## Crossroads 2.3 map acceptance: actual first-person walkthrough rather than
## screenshot-only dressing. No Generator / Anomaly / objective loop.
## Run: godot --headless --path . --script res://tests/check_crossroads_village.gd
const PROFILE = preload("res://scripts/crossroads/crossroads_profile.gd")


func _initialize() -> void:
    call_deferred("_check")


func _check() -> void:
    var issues: Array[String] = []
    var scene := load("res://scenes/crossroads_main.tscn") as PackedScene
    if scene == null:
        push_error("Crossroads 2.3 main scene does not load")
        quit(1)
        return
    var level := scene.instantiate() as Node3D
    root.add_child(level)
    await physics_frame
    var field := level.get_node_or_null("Landscape/WalkableGround") as StaticBody3D
    var roads := level.get_node_or_null("Landscape/OldRoadNetwork") as Node3D
    var village := level.get_node_or_null("Landscape/SettledCountry") as Node3D
    var actor := level.get("player") as CharacterBody3D
    var land = PROFILE.new()
    if field == null or field.get_node_or_null("WalkableTerrainCollision") == null:
        issues.append("The terrain is not a physically walkable continuous mesh")
    elif int(field.get("vertex_count")) < 37000 or int(field.get("cell_count")) != 37800:
        issues.append("Missing the detailed 2m collision-matched landscape")
    else:
        var terrain_mesh := field.get_node("WalkableTerrainVisual") as MeshInstance3D
        var collision := field.get_node("WalkableTerrainCollision") as CollisionShape3D
        if terrain_mesh.mesh == null or collision.shape == null:
            issues.append("Terrain visual or matching collision is empty")
    var outskirts := level.get_node_or_null("Landscape/FarmlandAndHorizon") as Node3D
    if outskirts == null:
        issues.append("Extended country is absent beyond the village border")
    else:
        if int(outskirts.get("fields")) != 4:
            issues.append("Extended country does not contain four walkable attached fields")
        if int(outskirts.get("distant_trees")) < 110:
            issues.append("Outer tree belts do not frame the distant horizon")
        var fields_root := outskirts.get_node_or_null("Farmland")
        if fields_root == null:
            issues.append("Country fields did not load")
        else:
            for field_name in ["NorthernFields", "SouthernFields", "WesternFields", "EasternFields"]:
                var country := fields_root.get_node_or_null(field_name) as StaticBody3D
                if country == null or country.get_node_or_null("CountryGroundCollision") == null:
                    issues.append("No walkable country beyond %s" % field_name)
        # Analytic country surface joins the inner shared map height exactly.
        for border in [Vector2(-180.0, -90.0), Vector2(180.0, 91.0), Vector2(35.0, -210.0), Vector2(-55.0, 210.0)]:
            var inside := land.height_at(border.x, border.y)
            var outside := land.outer_height_at(border.x, border.y)
            if absf(inside - outside) > 0.001:
                issues.append("Distant farm and settlement surface is discontinuous at " + str(border))
                break
    if roads == null:
        issues.append("Three-road network missing")
    else:
        var routes := roads.get_node_or_null("Routes")
        if routes == null:
            issues.append("There are no connected physical route surfaces")
        else:
            for label in ["VillageMainRoad", "WestCartTrack", "EastFieldLane"]:
                if routes.get_node_or_null(label) == null:
                    issues.append("A road route is absent: " + label)
        if int(roads.get("road_surfaces")) != 9 or int(roads.get("puddles")) != 25:
            issues.append("Road, verge or rainwater detail is missing")
        if (roads.get("route_samples") as Array).size() < 300:
            issues.append("Road meshes have not been sampled densely enough")
    if village == null:
        issues.append("Homestead level dressing is absent")
    else:
        var homesteads := village.get_node_or_null("Authoring/Homesteads") as Node3D
        if homesteads == null or homesteads.get_child_count() != 12:
            issues.append("Twelve authored properties were not placed")
        if int(village.get("houses_placed")) != 12:
            issues.append("The collection of varied houses is incomplete")
        if int(village.get("walkable_gate_count")) != 12:
            issues.append("Each plot needs an open street gate")
        if int(village.get("fence_sections")) != 60:
            issues.append("A boundary fence is absent or duplicated")
        if int(village.get("garden_props")) < 150:
            issues.append("Real yard detail and planted beds did not populate")
        if int(village.get("trees_placed")) < 50 or int(village.get("undergrowth_placed")) < 330:
            issues.append("The dense tree belt, gardens, and neglected hedges are missing")
        if int(village.get("utility_poles")) != 8:
            issues.append("Eight ordinary roadside poles or connecting wires missing")
        if homesteads != null:
            var first_type := homesteads.get_node_or_null("BlueSillSouth/Residence") as Node3D
            var second_type := homesteads.get_node_or_null("BrickAndLeanTo/Residence") as Node3D
            for house in [first_type, second_type]:
                if house == null:
                    issues.append("One of the two independently designed houses was not placed")
                elif house.get_node_or_null("BuiltHouse/Shell/CorrugatedPitchedRoof") == null:
                    issues.append("A new house has no joined pitched roof")
                elif int(house.get("furnished_count")) < 6:
                    issues.append("A new house is an empty undecorated box")
            for plot in homesteads.get_children():
                var gate_count := 0
                for post in plot.get_children():
                    if str(post.name).begins_with("OpenGatePost"):
                        gate_count += 1
                if gate_count != 2:
                    issues.append("One property has a closed or incomplete gate: " + str(plot.name))
                    break
    # No old plot-driving systems are even present in this scene.
    for disallowed in ["Generator", "VillageStalker", "StationThreat", "ResearchSample", "Anomaly", "CrossroadsMaintenanceStation"]:
        if level.find_child(disallowed, true, false) != null:
            issues.append("Old gameplay system leaked into Crossroads: " + disallowed)
    for label in level.find_children("*", "Label3D", true, false):
        if label.visible:
            issues.append("Floating gameplay label leaked into the environment")
            break
    if actor == null:
        issues.append("No actual player controller in the new village")
    else:
        if not is_equal_approx(actor.camera.far, 650.0):
            issues.append("Long village view distance was not configured")
        if actor.position.y < land.surface_height_at(actor.position.x, actor.position.z) - 0.2:
            issues.append("Walker begins beneath the terrain")
        level.call("start_walking")
        if not actor.active or level.get("cover").visible:
            issues.append("Opening the environment does not restore physical control")
        var old_position: Vector3 = actor.position
        Input.action_press("move_forward")
        for frame in range(70):
            await physics_frame
        Input.action_release("move_forward")
        if not actor.is_on_floor():
            var probe := PhysicsRayQueryParameters3D.create(
                actor.global_position + Vector3.UP * 3.0,
                actor.global_position - Vector3.UP * 5.0)
            probe.exclude = [actor.get_rid()]
            var ground_hit := level.get_world_3d().direct_space_state.intersect_ray(probe)
            var ground_shape: ConcavePolygonShape3D = null
            if field != null:
                ground_shape = (field.get_node("WalkableTerrainCollision") as CollisionShape3D).shape as ConcavePolygonShape3D
            var surface_count := ground_shape.get_faces().size() if ground_shape != null else -1
            var slide_detail := "no slides"
            if actor.get_slide_collision_count() > 0:
                var slide := actor.get_slide_collision(0)
                slide_detail = "normal=%s collider=%s" % [slide.get_normal(), slide.get_collider()]
            print("CROSSROADS_WALK_DIAGNOSTIC: floor=false ray=%s faces=%s slide=%s" % [ground_hit, surface_count, slide_detail])
        if actor.global_position.distance_to(old_position) < 1.0:
            issues.append("The first-person walker cannot traverse the road: delta=%.3f active=%s floor=%s direction=%s velocity=%s pos=%s start=%s overlay=%s" % [
                actor.global_position.distance_to(old_position), actor.active,
                actor.is_on_floor(), Input.get_vector("move_left", "move_right", "move_forward", "move_back"),
                actor.velocity, actor.position, level.get("started"), level.get("cover").visible
            ])
        if not actor.active:
            issues.append("Walker unexpectedly lost control during the walking test")
        if absf(actor.global_position.y - land.surface_height_at(actor.global_position.x, actor.global_position.z)) > 1.5:
            issues.append("Movement on the actual ground is physically unstable")
        level.call("pause_walking")
        if actor.active or not level.get("cover").visible:
            issues.append("Pause does not release player control")
        # Entrance clearance through the new East Blue Sill homestead gate.
        var test_z := 122.0
        var test_start_x := land.main_road_x(test_z) + 4.7
        var test_end_x := float(PROFILE.HOMES[1]["x"]) - 6.0
        var direct := PhysicsRayQueryParameters3D.create(
            Vector3(test_start_x, land.surface_height_at(test_start_x, test_z) + 1.10, test_z),
            Vector3(test_end_x, land.surface_height_at(test_end_x, test_z) + 1.10, test_z))
        direct.exclude = [actor.get_rid()]
        var barrier := level.get_world_3d().direct_space_state.intersect_ray(direct)
        if not barrier.is_empty():
            issues.append("Invisible obstacle blocks the first home's open gate or path: " + str(barrier.get("collider")))
    level.queue_free()
    await process_frame
    if issues.is_empty():
        print("CROSSROADS 2.3 ENVIRONMENT FIRST-PLAYTEST PASSED: 12 lots / 2 new buildings / walkable terrain and gates")
        quit(0)
    else:
        for item in issues:
            push_error(item)
        print("CROSSROADS 2.3 ENVIRONMENT TEST FAILED: ", issues.size())
        quit(1)
