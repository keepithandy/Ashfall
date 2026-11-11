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

    if litter == null or litter.get_script() == null:
        failures.append("Collision-free ground dressing script is not attached")
    elif litter is CollisionObject3D:
        failures.append("Ground dressing must not create physics bodies")

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
