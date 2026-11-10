extends SceneTree
var failures := 0
func _initialize() -> void:
    call_deferred("run")
func check(ok: bool, message: String) -> void:
    if ok: print("PASS: ", message)
    else:
        failures += 1
        push_error("FAIL: " + message)
func frames(count: int) -> void:
    for i in count: await physics_frame
func run() -> void:
    var packed := load("res://scenes/ashfall_editable.tscn") as PackedScene
    var game = packed.instantiate()
    var station = game.get_node_or_null("CrossroadsMaintenanceStation")
    check(station != null and station.owner == game, "station saved in main scene")
    check(station.owner == game, "station placement belongs to the main scene")
    root.add_child(game)
    game.smoke_test = true
    game.resume_game()
    var player = game.player
    await frames(3)
    check(game.find_children("CrossroadsMaintenanceStation", "Node3D", true, false).size() == 1, "exactly one station at runtime")
    var missing_tangents := 0
    for mesh_node in station.find_children("*", "MeshInstance3D", true, false):
        if mesh_node.mesh == null: continue
        for surface in mesh_node.mesh.get_surface_count():
            var arrays = mesh_node.mesh.surface_get_arrays(surface)
            if arrays[Mesh.ARRAY_NORMAL] == null or arrays[Mesh.ARRAY_TANGENT] == null:
                missing_tangents += 1
    check(missing_tangents == 0, "station meshes have normals and tangent space")
    var concrete_mesh = station.get_node("Foundation/Floor_00/Visual/world/concrete_combined").mesh
    var surface = concrete_mesh.surface_get_arrays(0)
    var vertices: PackedVector3Array = surface[Mesh.ARRAY_VERTEX]
    var normals: PackedVector3Array = surface[Mesh.ARRAY_NORMAL]
    var top_triangles := 0
    var top_faces_flat := true
    for i in range(0, vertices.size(), 3):
        if absf(vertices[i].y) < 0.0001 and absf(vertices[i + 1].y) < 0.0001 and absf(vertices[i + 2].y) < 0.0001:
            top_triangles += 1
            for corner in 3:
                top_faces_flat = top_faces_flat and normals[i + corner].y > 0.99
    check(top_triangles >= 2 and top_faces_flat, "floor has correctly oriented, flat top normals")
    check(station.has_node("MaintenanceDressing/Interior/SparePartsShelf") and station.has_node("MaintenanceDressing/ServiceYard/Pallet"), "interior and yard dressing load in the playable scene")
    check(station.has_node("BlenderArchitecturalRefinement") and not station.get_node("Roof").visible, "Blender roof replaces the old roof visuals")
    var space = game.get_world_3d().direct_space_state
    var roof_hit = space.intersect_ray(PhysicsRayQueryParameters3D.create(station.to_global(Vector3(0,2.6,0)), station.to_global(Vector3(0,4.2,0))))
    check(not roof_hit.is_empty() and station.get_node("Roof").is_ancestor_of(roof_hit.collider), "roof collision remains active")
    for offset in [Vector3(-5.5,0,-3.5), Vector3(5.5,0,-3.5), Vector3(-5.5,0,3.5), Vector3(5.5,0,3.5)]:
        var p: Vector3 = station.to_global(offset)
        var hit = space.intersect_ray(PhysicsRayQueryParameters3D.create(p+Vector3(0,0.1,0), p-Vector3(0,1,0)))
        check(not hit.is_empty() and absf(hit.position.y - station.global_position.y) < 0.08, "foundation supports player at " + str(offset))
    var door = station.get_node("Equipment/PersonnelDoor/DoorHinge")
    player.position = station.to_global(Vector3(4, -station.global_position.y + 0.05, 5.5))
    player.velocity = Vector3.ZERO
    player.set_view_direction(station.global_basis * Vector3.FORWARD)
    await frames(4)
    check(game.get_target() == door, "player can target closed door")
    if game.get_target() == door:
        game.interact_with(door)
    await frames(70)
    check(door.opened and door.rotation.y > 1.5, "game interaction opens hinged door")
    Input.action_press("move_forward")
    await frames(55)
    Input.action_release("move_forward")
    check(station.to_local(player.global_position).z < 3.7, "standing player walks through doorway: " + str(player.global_position))
    check(absf(player.global_position.y - station.global_position.y) < 0.1, "player remains on station floor")
    Input.action_press("move_back")
    await frames(80)
    Input.action_release("move_back")
    check(station.to_local(player.global_position).z > 4.7, "standing player can leave across the ramp: " + str(station.to_local(player.global_position)))
    var wall = space.intersect_ray(PhysicsRayQueryParameters3D.create(station.to_global(Vector3(-5.2,1.5,5)), station.to_global(Vector3(-5.2,1.5,3))))
    check(not wall.is_empty(), "front wall blocks passage")
    game.queue_free()
    await process_frame
    print("CROSSROADS_INTEGRATION: ", failures, " failure(s)")
    quit(1 if failures else 0)

