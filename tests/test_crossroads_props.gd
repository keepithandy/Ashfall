extends SceneTree
var fails := 0
func check(test: bool, message: String) -> void:
    if not test: fails += 1; push_error(message)
    else: print("PASS: ", message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
    var index := 0
    for id in ["hydraulic_jack", "work_trestle", "exposed_roots", "mushroom_cluster"]:
        var asset := load("res://scenes/crossroads_props/" + id + ".tscn") as PackedScene
        check(asset != null, "load " + id)
        if asset == null: continue
        var n := asset.instantiate()
        root.add_child(n)
        n.position.x = index * 4.0
        index += 1
        await process_frame
        var visual := n.get_node("Visual")
        var meshes := visual.find_children("*", "MeshInstance3D", true, false)
        check(meshes.size() > 0, "mesh present " + id)
        if meshes.size() > 0:
            var mesh := meshes[0] as MeshInstance3D
            var mapped := 0
            for i in range(mesh.mesh.get_surface_count()):
                if mesh.get_surface_override_material(i) != null: mapped += 1
            check(mapped == mesh.mesh.get_surface_count(), "shared materials mapped " + id)
            var transform: Transform3D = n.global_transform.affine_inverse() * mesh.global_transform
            var vertices := mesh.mesh.get_faces()
            var bounds := AABB(transform * vertices[0], Vector3.ZERO)
            for point in vertices: bounds = bounds.expand(transform * point)
            print("BOUNDS ", id, " ", bounds)
            check(bounds.position.y >= -0.02 and bounds.position.y < 0.05, "ground origin " + id)
            if id == "hydraulic_jack": check(bounds.size.y > .9 and bounds.size.y < 1.1, "jack metre scale")
            if id == "work_trestle": check(bounds.size.y > .8 and bounds.size.y < .95, "trestle metre scale")
            if id == "exposed_roots": check(bounds.size.y < .5 and bounds.size.x > .7, "roots metre scale")
            if id == "mushroom_cluster": check(bounds.size.y > .18 and bounds.size.y < .3, "mushroom metre scale")
        check(n.has_node("Collision") == (id in ["hydraulic_jack", "work_trestle"]), "collision policy " + id)
        check(n.find_children("*", "Label3D", true, false).is_empty(), "no prop text " + id)
        await physics_frame
        await physics_frame
        var space = n.get_world_3d().direct_space_state
        var hit: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(n.position + Vector3(0,1.3,0),n.position + Vector3(0,.05,0)))
        check(hit.is_empty() == (id in ["exposed_roots", "mushroom_cluster"]), "vertical physics ray " + id)

    var gallery := load("res://scenes/crossroads_props/gallery.tscn") as PackedScene
    check(gallery != null,"gallery scene loads")
    print("PROP_RESULT: ", fails, " failure(s)")
    quit(1 if fails else 0)







