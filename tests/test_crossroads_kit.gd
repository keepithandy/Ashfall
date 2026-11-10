extends SceneTree
var failures := 0
func check(ok: bool, msg: String) -> void:
    if not ok:
        failures += 1
        push_error(msg)
    else:
        print("PASS: ",msg)
func _initialize() -> void:
    call_deferred("run")
func run() -> void:
    var names := ["floor_4m","wall_solid_4m","wall_solid_2m","wall_window_4m","wall_door_4m","corner_1m","roof_4m","metal_door"]
    for n in names:
        var scene := load("res://scenes/crossroads_kit/" + n + ".tscn") as PackedScene
        check(scene != null,"load " + n)
        if scene:
            var piece := scene.instantiate()
            root.add_child(piece)
            await process_frame
            var visual := piece.get_node("Visual")
            check(count_meshes(visual) > 0,"meshes present " + n)
            check(piece.get_node("Collision").get_child_count() > 0,"collision present " + n)
            if n == "wall_door_4m":
                check(piece.get_node("Collision").get_child_count() == 3,"door opening has three collision sections")
            if n == "wall_window_4m":
                check(piece.get_node("Collision").get_child_count() == 4,"window opening has four collision sections")
            piece.queue_free()
    var demo := load("res://scenes/crossroads_kit/demo.tscn") as PackedScene
    check(demo != null,"demo loads")
    if demo:
        var node := demo.instantiate()
        root.add_child(node)
        await process_frame
        check(node.get_node("OpenDoor") != null,"independent door in assembled scene")
        check(node.get_node("Floor_4_4").position == Vector3(4,0,-4),"floor uses four metre grid")
        check(is_equal_approx(node.get_node("Roof0").position.y, 3.2),"roof aligns to wall height")
        var mi := find_mesh(node.get_node("WallLarge0/Visual"))
        check(mi != null and mi.get_surface_override_material(0) != null,"shared materials applied")
        await physics_frame
        await physics_frame
        var space = node.get_world_3d().direct_space_state
        var doorway = space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(3,1.2,1),Vector3(3,1.2,-1)))
        var wall = space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(1.5,1.2,1),Vector3(1.5,1.2,-1)))
        var window = space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(7,1.5,-3),Vector3(9,1.5,-3)))
        check(doorway.is_empty(), "open doorway permits passage")
        check(not wall.is_empty(), "solid wall blocks passage")
        check(window.is_empty(), "window opening remains clear")
        node.queue_free()
    print("RESULT: ",failures," failure(s)")
    quit(1 if failures else 0)
func count_meshes(node: Node) -> int:
    var count := 1 if node is MeshInstance3D else 0
    for c in node.get_children(): count += count_meshes(c)
    return count
func find_mesh(node: Node) -> MeshInstance3D:
    if node is MeshInstance3D: return node
    for c in node.get_children():
        var found := find_mesh(c)
        if found != null: return found
    return null


