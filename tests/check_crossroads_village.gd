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
        elif not _top_faces_visible(terrain_mesh.mesh):
            issues.append("Village ground triangles are backwards: top surface is culled")
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
                else:
                    var field_visual := country.get_node_or_null("FieldGround") as MeshInstance3D
                    if field_visual == null or field_visual.mesh == null or not _top_faces_visible(field_visual.mesh):
                        issues.append("Country field %s faces are backwards or missing" % field_name)
        # Analytic country surface joins the inner shared map height exactly.
        for border in [Vector2(-180.0, -90.0), Vector2(180.0, 91.0), Vector2(35.0, -210.0), Vector2(-55.0, 210.0)]:
            var inside := land.height_at(border.x, border.y)
            var outside := land.outer_height_at(border.x, border.y)
            if absf(inside - outside) > 0.001:
                issues.append("Distant farm and settlement surface is discontinuous at " + str(border))
                break
    # Countryside composition regression: visual density, authentic field
    # mosaic, GPU batching, physical ground-snapped vegetation and road gaps.
    var composition := level.get_node_or_null("Landscape/CountryComposition") as Node3D
    if composition == null:
        issues.append("Crossroads has no authored outer-country composition")
    else:
        if int(composition.get("belts_authored")) != 10:
            issues.append("Missing field shelterbelt corridors")
        if int(composition.get("planted_groves")) != 10:
            issues.append("Distant woodlands do not surround the settlement")
        if int(composition.get("planted_trees")) < 1450:
            issues.append("Midground and distant woodland silhouettes are too sparse")
        if int(composition.get("planted_scrub")) < 1400:
            issues.append("Field-edge hedge and roadside undergrowth missing")
        if int(composition.get("field_patches")) != 12 or int(composition.get("field_triangles")) < 5000:
            issues.append("Twelve varied harvested field parcels did not build")
        if int(composition.get("prototypes_used")) != 5:
            issues.append("Background failed to reuse all five vegetation source scenes")
        var count_batches := int(composition.get("draw_batches"))
        if count_batches < 40 or count_batches > 900:
            issues.append("Countryside instancing is not batched efficiently")
        var field_root := composition.get_node_or_null("LandscapeComposition/PatchworkFields") as Node3D
        var vegetation_root := composition.get_node_or_null("LandscapeComposition/BatchedVegetation") as Node3D
        if field_root == null or field_root.get_child_count() != 12:
            issues.append("The playable outer fields are blank again")
        else:
            for field_part in field_root.get_children():
                var field_visual := field_part as MeshInstance3D
                if field_visual.mesh == null or not _top_faces_visible(field_visual.mesh):
                    issues.append("Harvest field has backward-facing or missing triangles")
                    break
        if vegetation_root == null or vegetation_root.get_child_count() != 5:
            issues.append("Countryside vegetation batching nodes are missing")
        else:
            for batch_type in vegetation_root.get_children():
                if batch_type.get_child_count() == 0:
                    issues.append("One type of countryside vegetation has no visible meshes")
                for segment in batch_type.get_children():
                    var batch := segment as MultiMeshInstance3D
                    if batch.multimesh == null or batch.multimesh.instance_count < 1:
                        issues.append("A countryside vegetation batch contains no instances")
                        break
                    if segment is CollisionObject3D:
                        issues.append("Scenery vegetation must be visual-only")
                        break
        # The original old-route roadway and gates remain clear of trees.
        var groups: Dictionary = composition.get("placements")
        var checked := 0
        for key in groups.keys():
            var values: Array = groups[key]
            for planted in values:
                var transform: Transform3D = planted
                var point := Vector2(transform.origin.x, transform.origin.z)
                if land.distance_to_line(point, PROFILE.MAIN_ROAD) < 9.5:
                    issues.append("Country tree or shrub intersects the main road")
                    break
                checked += 1
                if checked >= 350:
                    break
            if checked >= 350:
                break
        if checked < 350:
            issues.append("Too few countryside vegetation instances were sampled")

    var climate := level.get_node_or_null("WorldEnvironment") as WorldEnvironment
    if climate == null or climate.environment == null or climate.environment.sky == null:
        issues.append("Overcast village lighting or sky missing")
    else:
        var sky_material := climate.environment.sky.sky_material as ShaderMaterial
        if sky_material == null or float(sky_material.get_shader_parameter("cloud_contrast")) > 1.1:
            issues.append("Crossroads sky lost its subdued overcast palette")

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
        # Verify old asphalt and both rural tracks hug the physical
        # collision terrain instead of floating or disappearing beneath it.
        var routes_node := roads.get_node_or_null("Routes") as Node3D
        if routes_node != null:
            for label in ["VillageMainRoad", "WestCartTrack", "EastFieldLane"]:
                var route := routes_node.get_node_or_null(label) as Node3D
                if route == null:
                    continue
                var layer := route.get_node_or_null("CompactedSurface") as MeshInstance3D
                if layer == null or layer.mesh == null:
                    issues.append("Missing physical road surface for " + label)
                    continue
                var arrays: Array = layer.mesh.surface_get_arrays(0)
                var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
                for n in range(0, vertices.size(), 36):
                    var point: Vector3 = vertices[n]
                    var above_ground := point.y - land.surface_height_at(point.x, point.z)
                    if absf(above_ground - 0.034) > 0.02:
                        issues.append("Road intersects the terrain at " + label)
                        break

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
            # Grade audit: compare the ACTUAL instanced house floor
            # positions and the four rotated foundation corners with the
            # exact same terrain profile used to build the collision mesh.
            for site in PROFILE.HOMES:
                var plot := homesteads.get_node_or_null(str(site["name"])) as Node3D
                if plot == null:
                    issues.append("Missing authored homestead: " + str(site["name"]))
                    continue
                var home := plot.get_node_or_null("Residence") as Node3D
                if home == null:
                    issues.append("Missing residence at " + str(site["name"]))
                    continue
                var pad_height := land.site_floor_height(site)
                if absf(home.position.y - (pad_height + 0.04)) > 0.015:
                    issues.append("Foundation not on graded pad at " + str(site["name"]))
                var footprint := land._site_footprint(site)
                var yaw := float(site["yaw"])
                for x_side in [-0.90, 0.90]:
                    for z_side in [-0.90, 0.90]:
                        var lx := footprint.x * float(x_side)
                        var lz := footprint.y * float(z_side)
                        var wx := float(site["x"]) + cos(yaw) * lx + sin(yaw) * lz
                        var wz := float(site["z"]) - sin(yaw) * lx + cos(yaw) * lz
                        if absf(land.surface_height_at(wx, wz) - pad_height) > 0.08:
                            issues.append("Terrain intersects rotated house footprint at " + str(site["name"]))
                            break
            # Long fence rails/collision must follow the land in short
            # segments, not form a high invisible dam over a sloping yard.
            var contoured_fences := 0
            var contoured_beds := 0
            for plot in homesteads.get_children():
                for child in plot.get_children():
                    if str(child.name).begins_with("PrivacyFence_"):
                        contoured_fences += 1
                        var segments := 0
                        for part in child.get_children():
                            if str(part.name).begins_with("FenceSegmentCollision_"):
                                segments += 1
                                var fence_body := child as Node3D
                                var collision_piece := part as CollisionShape3D
                                var world_pos := fence_body.to_global(collision_piece.position)
                                var expected_y := land.surface_height_at(world_pos.x, world_pos.z) + 0.76
                                if absf(world_pos.y - expected_y) > 0.15:
                                    issues.append("Fence has buried/floating collision at " + str(plot.name))
                                    break
                        if segments < 1:
                            issues.append("Fence missing terrain-following collision at " + str(plot.name))
                    elif str(child.name).begins_with("TendedThenAbandonedBed"):
                        contoured_beds += 1
                        var bed := child as MeshInstance3D
                        if bed.mesh == null:
                            issues.append("Garden bed lacks surface mesh at " + str(plot.name))
                            continue
                        var arrays: Array = bed.mesh.surface_get_arrays(0)
                        var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
                        for k in range(0, vertices.size(), 3):
                            var v: Vector3 = vertices[k]
                            var delta := v.y - land.surface_height_at(v.x, v.z)
                            if delta < 0.018 or delta > 0.12:
                                issues.append("Garden bed intersects ground at " + str(plot.name))
                                break
            if contoured_fences != 60 or contoured_beds != 36:
                issues.append("Incomplete terrain-following surfaces: %d fences / %d garden beds" % [contoured_fences, contoured_beds])
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
    # Hidden fullscreen GUI must not swallow camera mouse movement.
    var pause_card := level.get("menu") as Control
    if pause_card == null or pause_card.mouse_filter != Control.MOUSE_FILTER_IGNORE:
        issues.append("Fullscreen menu intercepts first-person mouse look")
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
        var visible_ground := field.get_node("WalkableTerrainVisual") as MeshInstance3D
        if visible_ground.mesh.surface_get_material(0) == null:
            issues.append("Walkable terrain has no soil material")
        elif not visible_ground.mesh.surface_get_material(0) is ShaderMaterial:
            issues.append("Walkable terrain is missing weathered soil shader")
        var farmland := level.get_node("Landscape/FarmlandAndHorizon/Farmland/NorthernFields/FieldGround") as MeshInstance3D
        if farmland.mesh.surface_get_material(0) == null or not farmland.mesh.surface_get_material(0) is ShaderMaterial:
            issues.append("Distant farmland is missing the shared earth material")
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


# Front-facing terrain triangles on an X/Z grid face toward a player above
# the landscape. Inspect actual mesh indices: a physics-only test missed the
# previous defect because the concave collision accepted back faces.
func _top_faces_visible(mesh: Mesh) -> bool:
    if mesh == null or mesh.get_surface_count() < 1:
        return false
    var arrays: Array = mesh.surface_get_arrays(0)
    var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
    var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
    if vertices.size() < 3:
        return false
    # SurfaceTool may commit either indexed or non-indexed triangles.
    var a: Vector3 = vertices[indices[0]] if indices.size() >= 3 else vertices[0]
    var b: Vector3 = vertices[indices[1]] if indices.size() >= 3 else vertices[1]
    var c: Vector3 = vertices[indices[2]] if indices.size() >= 3 else vertices[2]
    return (b - a).cross(c - a).y < -0.0001
