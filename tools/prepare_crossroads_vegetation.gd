extends SceneTree
## Rebuild only the saved vegetation batches intersecting the station footprint.
## Use a real rendering driver: Godot's headless dummy driver cannot read GPU buffers.
const OUTPUT := "res://assets/crossroads_integration/vegetation/"
func _initialize() -> void:
    call_deferred("run")
func run() -> void:
    if DisplayServer.get_name() == "headless":
        push_error("Use a rendering driver to read the saved vegetation buffers.")
        quit(1)
        return
    var world = load("res://scenes/ashfall_editable.tscn").instantiate()
    root.add_child(world)
    await process_frame
    var station: Node3D = world.get_node("CrossroadsMaintenanceStation")
    var expected := Transform3D(Basis(Vector3(-0.005705965, 0, 0.9999837), Vector3(0, 1, 0), Vector3(-0.9999837, 0, -0.005705965)), Vector3(26.564575, 0.20690918, 23.674866))
    if not station.global_transform.is_equal_approx(expected):
        push_error("Station moved; review vegetation batches and scene overrides before regenerating.")
        quit(1)
        return
    # Start from the untouched source world, not the already-cleared overrides.
    var source_world: Node3D = load("res://scenes/editable_world.tscn").instantiate()
    root.add_child(source_world)
    source_world.global_transform = world.get_node("EditableWorld").global_transform
    var nature: Node = source_world.get_node("Vegetation/NaturalDressing")
    DirAccess.make_dir_recursive_absolute(OUTPUT)
    var written := 0
    for node in nature.find_children("*", "MultiMeshInstance3D", true, false):
        var source: MultiMesh = node.multimesh
        if source == null or source.instance_count == 0: continue
        var keep: Array[int] = []
        for i in source.instance_count:
            var world_pos: Vector3 = (node.global_transform * source.get_instance_transform(i)).origin
            var p: Vector3 = station.to_local(world_pos)
            var in_building := absf(p.x) < 6.15 and absf(p.z) < 4.15
            var in_apron := p.x > -6.2 and p.x < 6.2 and p.z >= 4.15 and p.z < 6.0
            if not in_building and not in_apron:
                keep.append(i)
        if keep.size() == source.instance_count: continue
        var batch := MultiMesh.new()
        batch.transform_format = source.transform_format
        batch.use_colors = source.use_colors
        batch.use_custom_data = source.use_custom_data
        batch.mesh = source.mesh
        batch.custom_aabb = source.custom_aabb
        batch.instance_count = keep.size()
        for i in keep.size():
            var old_index: int = keep[i]
            batch.set_instance_transform(i, source.get_instance_transform(old_index))
            if source.use_colors: batch.set_instance_color(i, source.get_instance_color(old_index))
            if source.use_custom_data: batch.set_instance_custom_data(i, source.get_instance_custom_data(old_index))
        var path := OUTPUT + str(node.name) + ".res"
        var err := ResourceSaver.save(batch,path)
        if err != OK:
            push_error("Unable to save " + path)
            quit(1)
            return
        print("CLEARED ", node.name, ": ", source.instance_count - keep.size(), " instances; saved ", path)
        written += 1
    print("VEGETATION_BATCHES ",written)
    source_world.queue_free()
    world.queue_free()
    await process_frame
    quit()
