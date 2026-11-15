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
        var workshop := structures.get_node_or_null("GeneratedDistrict/MaintenanceWorkshop") as StaticBody3D
        if workshop == null:
            issues.append("Maintenance workshop missing")
        else:
            # Validate the small wooden workshop pass independently from a
            # visual review: the original entry must remain physically open.
            for part in ["TimberFrontHeader","RoofRidgeCap","DoorUpperTrack"]:
                if workshop.get_node_or_null(part) == null:
                    issues.append("Workshop exterior timber detail missing: " + part)
            var door := workshop.get_node_or_null("ParkedSlidingDoor") as MeshInstance3D
            if door == null or not door.mesh is BoxMesh:
                issues.append("Workshop parked timber equipment door missing")
            else:
                var panel := door.mesh as BoxMesh
                if door.position.x - panel.size.x * 0.5 <= 2.1:
                    issues.append("Workshop sliding door obstructs the 4.2m entry")
                if door.position.x + panel.size.x * 0.5 >= 8.0:
                    issues.append("Workshop sliding door extends beyond the existing shell")
            var solid_shapes := 0
            var battens := 0
            var fascia := 0
            for part in workshop.get_children():
                if part is CollisionShape3D:
                    solid_shapes += 1
                if part is MeshInstance3D:
                    var detail := part as MeshInstance3D
                    if str(detail.name).begins_with("TimberSideBatten_"):
                        battens += 1
                        if absf(detail.position.x) < 8.12:
                            issues.append("Workshop side siding must be outside the shell wall")
                    if str(detail.name).begins_with("TimberRearBatten_"):
                        battens += 1
                        if detail.position.z < 6.12:
                            issues.append("Workshop rear siding must be outside the shell wall")
                    if str(detail.name).begins_with("TimberGableFascia_"):
                        fascia += 1
                        if absf(detail.position.z) < 6.54 or detail.position.y < 4.5:
                            issues.append("Workshop gable fascia must stay outside and above the entrance")
            if battens != 16 or fascia != 4:
                issues.append("Workshop side/rear wooden siding or gable trim count changed")
            if solid_shapes != 8:
                issues.append("Workshop decoration must not change the original eight shell colliders")
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
        # Player occupies this very spawn position. Exclude its capsule when
        # checking the underlying terrain, but keep the rest of the world.
        if walker != null:
            ray.exclude = [walker.get_rid()]
        var hit := level.get_world_3d().direct_space_state.intersect_ray(ray)
        if hit.is_empty():
            issues.append("South entrance has no ground ray hit")
        elif hit.collider != ground:
            issues.append("South entrance hit %s instead of physical terrain" % str(hit.collider))
    _check_site_clearances(level, issues)
    level.queue_free()
    if issues.is_empty():
        print("BRIAR CREEK WALKTHROUGH: PASS (construction only; Godot visual/FPS review still needed)")
        quit(0)
    else:
        for issue in issues:
            push_error(issue)
        quit(1)

func _check_site_clearances(level: Node3D, issues: Array[String]) -> void:
    # Foundations and their visible slab extents must not overlap any
    # carriageway, including the northbound workshop access and exit gate.
    var profile = PROFILE.new()
    var district := level.get_node_or_null("Structures/GeneratedDistrict") as Node3D
    if district == null:
        issues.append("Cannot inspect building/road clearance without the generated district")
        return
    var checked := 0
    for name in [
        "MainSawmill","MillOffice","LogSortingShelter","FinishedTimberShelter",
        "WorkerCabinA","WorkerCabinB","WorkerCabinC","WorkerCabinD",
        "MaintenanceWorkshop","EquipmentShelter","CheckpointBooth"
    ]:
        var building := district.get_node_or_null(name) as StaticBody3D
        if building == null:
            issues.append("Missing important district building: " + name)
            continue
        var slab := building.get_node_or_null("Floor") as MeshInstance3D
        if slab == null:
            slab = building.get_node_or_null("GroundSlab") as MeshInstance3D
        if slab == null or not slab.mesh is BoxMesh:
            issues.append("Building has no measurable foundation: " + name)
            continue
        var box := slab.mesh as BoxMesh
        var dimensions := Vector2(box.size.x,box.size.z)
        var height := profile.surface_height_at(building.position.x,building.position.z)
        if absf(building.position.y - height - 0.035) > 0.01:
            issues.append("Building is not anchored to its physical ground: " + name)
        checked += 1
        var overlap := false
        for route in PROFILE.ROUTES:
            var points: Array = route["points"]
            var clearance := float(route["width"])*0.5 + 0.85
            for i in range(points.size()-1):
                var a: Vector3 = points[i]
                var b: Vector3 = points[i+1]
                var distance := Vector2(b.x-a.x,b.z-a.z).length()
                var steps := maxi(1,ceili(distance/2.0))
                for j in range(steps+1):
                    var along := a.lerp(b,float(j)/float(steps))
                    var center := profile.to_world(along.x,along.z)
                    var dx := maxf(0.0,absf(center.x - building.position.x) - dimensions.x*0.5)
                    var dz := maxf(0.0,absf(center.z - building.position.z) - dimensions.y*0.5)
                    if Vector2(dx,dz).length() < clearance:
                        issues.append("Building %s intersects %s road clearance" % [name,str(route["id"])])
                        overlap = true
                        break
                if overlap:
                    break
            if overlap:
                break
    if checked != 11:
        issues.append("Not all eleven measured structure foundations were inspected")
