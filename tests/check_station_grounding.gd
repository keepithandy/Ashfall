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
                for tree_index in range(batch.instance_count):
                    var position: Vector3 = batch.get_instance_transform(tree_index).origin
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
            if total_trees != int(treeline.get("tree_count")):
                failures.append("Forest total differs from configured tree count")
            if living_profiles.size() < 2:
                failures.append("Forest has insufficient conifer silhouette variety")
            if float(treeline.get("dead_tree_share")) > 0.0 and dead_trees == 0:
                failures.append("Expected occasional dead trees in the deterministic forest")
            treeline.call("_build")
            if forest.get_child_count() != original_batches:
                failures.append("Forest builder is not idempotent")

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
