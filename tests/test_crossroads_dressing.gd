extends SceneTree
## Run with a rendering driver so Godot can read MultiMesh instance buffers.
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, description: String) -> void:
    if ok: print("PASS: ", description)
    else:
        failures += 1
        push_error("FAIL: " + description)
func run() -> void:
    if DisplayServer.get_name() == "headless":
        push_error("This test requires a rendering driver for MultiMesh data")
        quit(1)
        return
    var game = load("res://scenes/ashfall_editable.tscn").instantiate()
    root.add_child(game)
    var source_world = load("res://scenes/editable_world.tscn").instantiate()
    root.add_child(source_world)
    source_world.global_transform = game.get_node("EditableWorld").global_transform
    await process_frame
    var station: Node3D = game.get_node("CrossroadsMaintenanceStation")
    var actual = game.get_node("EditableWorld/Vegetation/NaturalDressing")
    var original = source_world.get_node("Vegetation/NaturalDressing")
    var changed := 0
    for baseline in original.find_children("*", "MultiMeshInstance3D", true, false):
        var source: MultiMesh = baseline.multimesh
        var result_node: MultiMeshInstance3D = actual.get_node(str(baseline.name))
        var result: MultiMesh = result_node.multimesh
        if source == null: continue
        var expected: Array[int] = []
        for i in source.instance_count:
            var world_pos: Vector3 = (baseline.global_transform * source.get_instance_transform(i)).origin
            var p: Vector3 = station.to_local(world_pos)
            var in_building := absf(p.x) < 6.15 and absf(p.z) < 4.15
            var in_apron := p.x > -6.2 and p.x < 6.2 and p.z >= 4.15 and p.z < 6.0
            if not in_building and not in_apron: expected.append(i)
        if expected.size() == source.instance_count: continue
        changed += 1
        check(result != null and result.instance_count == expected.size(), str(baseline.name) + " excludes only the station and apron")
        if result == null or result.instance_count != expected.size(): continue
        var preserved := true
        for i in expected.size():
            var original_index: int = expected[i]
            if not result.get_instance_transform(i).is_equal_approx(source.get_instance_transform(original_index)):
                preserved = false
                break
            if source.use_colors and not result.get_instance_color(i).is_equal_approx(source.get_instance_color(original_index)):
                preserved = false
                break
            if source.use_custom_data and not result.get_instance_custom_data(i).is_equal_approx(source.get_instance_custom_data(original_index)):
                preserved = false
                break
        check(preserved, str(baseline.name) + " preserves every outside instance")
    check(changed == 4, "four local vegetation batches adjusted")
    game.queue_free()
    source_world.queue_free()
    await process_frame
    print("CROSSROADS_DRESSING: ",failures," failure(s)")
    quit(1 if failures else 0)
