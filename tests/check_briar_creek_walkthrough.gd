extends SceneTree
## Briar Creek walkabout smoke test.
## Godot 4.7: godot --headless --path . --script res://tests/check_briar_creek_walkthrough.gd
## This verifies construction, not visual acceptance or an actual human playtest.
const PROFILE = preload("res://scripts/briar_creek/briar_creek_profile.gd")

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    var issues: Array[String] = []
    if str(ProjectSettings.get_setting("application/run/main_scene")) != "res://scenes/crossroads_main.tscn":
        issues.append("Area 02 must not change the existing startup scene")
    var resource := load("res://scenes/briar_creek/briar_creek_walkthrough.tscn") as PackedScene
    if resource == null:
        push_error("Briar Creek walkthrough scene failed to load")
        quit(1)
        return
    var level := resource.instantiate() as Node3D
    root.add_child(level)
    await physics_frame
    var ground := level.get_node_or_null("TerrainPlan/Generated/WalkableTerrain") as StaticBody3D
    var forest := level.get_node_or_null("Forest") as Node3D
    var structures := level.get_node_or_null("Structures") as Node3D
    var creek := level.get_node_or_null("TerrainPlan/Generated/WesternCreekVisualOnly") as MeshInstance3D
    var walker := level.get_node_or_null("Controller/Walker") as CharacterBody3D
    if ground == null or ground.get_node_or_null("TerrainCollision") == null:
        issues.append("Terrain is missing physically walkable collision")
    if creek == null or creek.mesh == null:
        issues.append("Western creek visual ribbon absent")
    if forest == null:
        issues.append("Forest generator missing")
    else:
        var count := int(forest.get("trees_planted"))
        if count < 600:
            issues.append("Woodland is not sufficiently populated for a forest walkabout")
        if int(forest.get("trunk_colliders")) != count:
            issues.append("Each batch-rendered tree must retain a physical trunk")
        var forest_meshes := forest.get_node_or_null("GeneratedForest/BatchedCanopy") as Node3D
        if forest_meshes == null or forest_meshes.get_child_count() < 6:
            issues.append("No batched forest meshes generated")
    if structures == null:
        issues.append("Logging district generator missing")
    else:
        if int(structures.get("buildings_created")) < 14:
            issues.append("Missing logging industry structures or worker cabins")
        var mill := structures.get_node_or_null("GeneratedDistrict/MainSawmill") as StaticBody3D
        if mill == null:
            issues.append("Main sawmill missing")
    if walker == null:
        issues.append("No first-person walker constructed")
    elif walker.get_node_or_null("CollisionShape3D") == null and walker.get_child_count() == 0:
        issues.append("Player has no collision or character nodes")
    # Sampling a real terrain ray at the south road should hit the ground,
    # not a hidden floating road slab or an unrelated gameplay trigger.
    if ground != null:
        var profile = PROFILE.new()
        var at := profile.to_world(305.0,44.0)
        at.y=profile.surface_height_at(at.x,at.z)
        var ray := PhysicsRayQueryParameters3D.create(at+Vector3.UP*8.0,at-Vector3.UP*8.0)
        var hit := level.get_world_3d().direct_space_state.intersect_ray(ray)
        if hit.is_empty():
            issues.append("South entrance has no ground ray hit")
        elif hit.collider != ground:
            issues.append("South entrance ray collides with something other than physical terrain")
    level.queue_free()
    if issues.is_empty():
        print("BRIAR CREEK WALKTHROUGH: PASS (construction only; Godot visual/FPS review still needed)")
        quit(0)
    else:
        for issue in issues:
            push_error(issue)
        quit(1)
