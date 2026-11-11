extends SceneTree
## Station 04 terrain placement regression test.
## Run from Ashfall root:
## godot --headless --path . --script res://tests/check_station_grounding.gd

func _initialize() -> void:
    var failures: Array[String] = []
    var packed := load("res://scenes/ashfall_station_main.tscn") as PackedScene
    if packed == null:
        push_error("Station 04 scene did not load")
        quit(1)
        return

    var level := packed.instantiate()
    var ground_body := level.get_node_or_null("EditableWorld/Terrain/WalkableGround") as StaticBody3D
    var ground_visual := level.get_node_or_null("EditableWorld/Terrain/WalkableGround/VisibleGround") as MeshInstance3D
    var ground_collision := level.get_node_or_null("EditableWorld/Terrain/WalkableGround/GroundCollision") as CollisionShape3D
    var road := level.get_node_or_null("EditableWorld/Terrain/ApproachRoad") as MeshInstance3D
    var yard := level.get_node_or_null("EditableWorld/Terrain/ServiceYardSurface") as MeshInstance3D
    var mushrooms := level.get_node_or_null("MushroomCluster") as Node3D
    var horizon := level.get_node_or_null("EditableWorld/Terrain/HorizonRelief") as Node3D
    var treeline := level.get_node_or_null("EditableWorld/Terrain/DistantTreeLine") as Node3D
    var near_canopies := level.get_node_or_null("EditableWorld/Vegetation/NearCanopyFill") as Node3D
    var litter := level.get_node_or_null("EditableWorld/GroundLitter") as Node3D

    if ground_body == null or ground_visual == null or ground_collision == null:
        failures.append("Ground visual, physics body or collision is missing")
    else:
        var mesh := ground_visual.mesh as BoxMesh
        var shape := ground_collision.shape as BoxShape3D
        if mesh == null or shape == null:
            failures.append("Ground is no longer composed of known box mesh and shape")
        else:
            if mesh.size.x < 420.0 or mesh.size.z < 420.0:
                failures.append("Ground visual does not extend beyond camera horizon")
            if not mesh.size.is_equal_approx(shape.size):
                failures.append("Ground mesh and collision footprints differ")
            if absf(ground_body.position.y + mesh.size.y * 0.5) > 0.01:
                failures.append("Walkable ground is not level with world y = 0")
        var ground_material := ground_visual.material_override as ShaderMaterial
        if ground_material == null or ground_material.shader == null:
            failures.append("Ground has no surface blending shader")
        elif not ground_material.shader.resource_path.ends_with("station04_ground.gdshader"):
            failures.append("Ground has unexpected shader resource")
        elif ground_material.get_shader_parameter("forest_albedo") == null:
            failures.append("Forest albedo was not assigned")
        elif ground_material.get_shader_parameter("concrete_albedo") == null:
            failures.append("Road albedo was not assigned")
        for pbr_key in ["forest_normal", "forest_roughness", "forest_ao", "concrete_normal", "concrete_roughness", "concrete_ao"]:
            if ground_material != null and ground_material.get_shader_parameter(pbr_key) == null:
                failures.append("Missing terrain PBR texture: " + pbr_key)

    if road == null or yard == null:
        failures.append("Legacy road/yard reference nodes have been removed")
    elif road.visible or yard.visible:
        failures.append("Raised road or yard mesh is still visible")

    if mushrooms == null:
        failures.append("Mushroom scene instance is missing")
    elif mushrooms.scale.distance_to(Vector3.ONE) > 0.05:
        failures.append("Mushroom instance remains at an abnormal scale")

    if horizon == null or horizon.get_script() == null:
        failures.append("Distant terrain relief script is not attached")
    elif horizon is CollisionObject3D:
        failures.append("Distant terrain must be visual only")
    if horizon != null and horizon.get_script() != null:
        # Test the rectangle-aware relief boundary, not only the node's presence.
        var probe_noise := FastNoiseLite.new()
        for angle_idx in range(32):
            var angle := TAU * float(angle_idx) / 32.0
            var relief_point: Vector3 = horizon.call("_point", angle, 9.0, probe_noise)
            if absf(relief_point.x) <= 86.0 and absf(relief_point.z) <= 81.0:
                failures.append("Horizon terrain entered playable district at angle " + str(angle_idx))
                break

    if treeline == null or treeline.get_script() == null:
        failures.append("Distant tree line is missing")
    else:
        var terrain_noise: FastNoiseLite = horizon.call("_make_noise") as FastNoiseLite if horizon != null else null
        if terrain_noise == null:
            failures.append("Horizon must expose shared terrain noise for trees")
        else:
            for angle_idx in range(24):
                var angle := TAU * float(angle_idx) / 24.0
                var outside_point: Vector3 = horizon.call("_point", angle, 52.0, terrain_noise)
                if not is_finite(outside_point.y):
                    failures.append("Distant tree ground sampling yielded invalid height")
                    break
        treeline.call("_build")
        var forest := treeline.get_node_or_null("ForestBatches") as Node3D
        if forest == null:
            failures.append("Distant forest did not create its spatial batches")
        else:
            var total_trees := 0
            var living_profiles: Dictionary = {}
            var dead_trees := 0
            var original_batches := forest.get_child_count()
            for child in forest.get_children():
                var layer := child as MultiMeshInstance3D
                if layer == null or layer.multimesh == null or layer.multimesh.mesh == null:
                    failures.append("Forest contains an invalid mesh batch")
                    continue
                var batch := layer.multimesh
                total_trees += batch.instance_count
                if batch.custom_aabb.size.length_squared() < 1.0:
                    failures.append("Forest sector has an invalid culling extent")
                var type_id := int(str(layer.name).get_slice("Profile", 1))
                if type_id == 3:
                    dead_trees += batch.instance_count
                    if batch.mesh.get_surface_count() != 1:
                        failures.append("Dead trees should have bare wooden branches")
                else:
                    living_profiles[type_id] = true
                    if batch.mesh.get_surface_count() != 2:
                        failures.append("Living trees need separate bark and foliage geometry")
            if total_trees != int(treeline.get("tree_count")):
                failures.append("Forest total differs from configured tree count")
            # Godot's headless dummy rendering server cannot reliably read
            # MultiMesh transforms back. Validate the generator's actual
            # logical placements, then separately assert MultiMesh counts.
            var placed_bases: Array = treeline.get("generated_tree_bases")
            if placed_bases.size() != int(treeline.get("tree_count")):
                failures.append("Forest generated an unexpected number of tree bases")
            for entry in placed_bases:
                var position: Vector3 = entry
                if absf(position.x) <= 86.0 and absf(position.z) <= 81.0:
                    failures.append("A forest tree entered the playable district")
                    break
                if not is_finite(position.x) or not is_finite(position.y) or not is_finite(position.z):
                    failures.append("Distant forest generated invalid coordinates")
                    break
                if terrain_noise != null:
                    var angle := wrapf(atan2(position.z, position.x), 0.0, TAU)
                    var radius := Vector2(position.x, position.z).length()
                    var offset: float = radius - float(treeline.call("_edge_radius", angle))
                    var ground_point: Vector3 = horizon.call("_point", angle, offset, terrain_noise)
                    if absf(position.y - (ground_point.y - 0.12)) > 0.03:
                        failures.append("Distant tree roots do not follow terrain")
                        break
            if living_profiles.size() < 2:
                failures.append("Forest has insufficient conifer silhouette variety")
            if float(treeline.get("dead_tree_share")) > 0.0 and dead_trees == 0:
                failures.append("Expected occasional dead trees in the deterministic forest")
            treeline.call("_build")
            if forest.get_child_count() != original_batches:
                failures.append("Forest builder is not idempotent")

    if treeline != null and treeline.get_script() != null:
        var young := treeline.get_node_or_null("YoungGrowth") as Node3D
        if young == null:
            failures.append("Forest edge is missing its low sapling tier")
        else:
            var young_total := 0
            for child in young.get_children():
                var young_batch := child as MultiMeshInstance3D
                if young_batch == null or young_batch.multimesh == null:
                    failures.append("Forest sapling batch was invalid")
                    continue
                young_total += young_batch.multimesh.instance_count
                if young_batch.multimesh.custom_aabb.size.length_squared() < 1.0:
                    failures.append("Forest sapling culling bounds were not generated")
            if young_total != int(treeline.get("sapling_count")):
                failures.append("Forest sapling count differs from configured value")

    # Existing 46 manually placed pines should receive visual crowns only.
    # Never rewrite their scenes, positions, collisions or game scripts.
    if near_canopies == null or near_canopies.get_script() == null:
        failures.append("Authored forest canopy overlay is missing")
    else:
        near_canopies.call("_build")
        var crown_group := near_canopies.get_node_or_null("CanopyBatches") as Node3D
        if crown_group == null:
            failures.append("Near forest canopy batches failed to build")
        else:
            var sum_canopies := 0
            for child in crown_group.get_children():
                var crowns := child as MultiMeshInstance3D
                if crowns == null or crowns.multimesh == null:
                    failures.append("Near canopy batch is invalid")
                    continue
                sum_canopies += crowns.multimesh.instance_count
                if crowns.multimesh.mesh == null or crowns.multimesh.mesh.get_surface_count() != 2:
                    failures.append("Near canopy foliage mesh does not contain bark and needles")
            if sum_canopies != 46:
                failures.append("Existing pine canopy coverage changed unexpectedly")
            if int(near_canopies.get("generated_canopy_count")) != 46:
                failures.append("Near canopy builder did not locate all authored pines")
            var before := crown_group.get_child_count()
            near_canopies.call("_build")
            if crown_group.get_child_count() != before:
                failures.append("Near canopy builder is not idempotent")

    if horizon != null and horizon.get_script() != null:
        var ridge_noise: FastNoiseLite = horizon.call("_make_noise") as FastNoiseLite
        var ridge_near: Vector3 = horizon.call("_point", 0.42, 9.0, ridge_noise)
        var ridge_far: Vector3 = horizon.call("_point", 0.42, 550.0, ridge_noise)
        if ridge_far.y <= ridge_near.y + 8.0:
            failures.append("Far ridge does not rise above the flat-ground horizon")
        if absf(ridge_far.x) <= 230.0 and absf(ridge_far.z) <= 230.0:
            failures.append("Visual relief no longer extends beyond the flat ground edge")

    if litter == null or litter.get_script() == null:
        failures.append("Collision-free ground dressing script is not attached")
    elif litter is CollisionObject3D:
        failures.append("Ground dressing must not create physics bodies")

    # Run the same mesh/dressing builders as the playable scene and verify
    # their outputs. This catches parser and missing-resource errors that a
    # node-reference-only test would miss.
    if horizon != null and horizon.get_script() != null:
        horizon.call("_build")
        var relief_mesh := horizon.get_node_or_null("DistantTerrain") as MeshInstance3D
        if relief_mesh == null or relief_mesh.mesh == null:
            failures.append("Distant relief failed to build a mesh")
        elif relief_mesh.mesh.get_surface_count() == 0:
            failures.append("Distant relief generated no visible surfaces")
        else:
            # Godot treats clockwise winding as the visible front face.
            # Previously the hill had valid triangles but back-face culling
            # hid the top from the player, so a surface-count test passed.
            var surface: Array = relief_mesh.mesh.surface_get_arrays(0)
            var vertices: PackedVector3Array = surface[Mesh.ARRAY_VERTEX]
            var normals: PackedVector3Array = surface[Mesh.ARRAY_NORMAL]
            var indices: PackedInt32Array = surface[Mesh.ARRAY_INDEX]
            if vertices.is_empty() or indices.size() < 3 or normals.size() != vertices.size():
                failures.append("Distant terrain mesh is missing vertices, faces or normals")
            else:
                var p0: Vector3 = vertices[indices[0]]
                var p1: Vector3 = vertices[indices[1]]
                var p2: Vector3 = vertices[indices[2]]
                if (p1 - p0).cross(p2 - p0).y >= -0.05:
                    failures.append("Hills have backward-facing top triangles for Godot's clockwise convention")
                if normals[indices[0]].y <= 0.0:
                    failures.append("Hilltop normals point below the surface")
                var sealed := false
                for point in vertices:
                    if point.y <= -24.9:
                        sealed = true
                        break
                if not sealed:
                    failures.append("Hills are missing the lower edge skirts sealing the backdrop")
    if litter != null and litter.get_script() != null:
        litter.call("_make_layer", true)
        litter.call("_make_layer", false)
        for layer_name in ["LeafFragments", "ScatteredGravel"]:
            var layer := litter.get_node_or_null(layer_name) as MultiMeshInstance3D
            if layer == null or layer.multimesh == null or layer.multimesh.instance_count < 100:
                failures.append("Ground microdressing layer missing or empty: " + layer_name)

    level.free()
    if failures.is_empty():
        print("STATION 04 GROUNDING CHECK PASSED")
        print("Ground PBR textures, scripted visual-only relief, microdressing and legacy mesh safety checked")
        print("Visual appearance and walking/collision must still be confirmed in Godot")
        quit(0)
    else:
        for failure in failures:
            push_error(failure)
        print("STATION 04 GROUNDING CHECK FAILED: ", failures.size(), " issues")
        quit(1)
