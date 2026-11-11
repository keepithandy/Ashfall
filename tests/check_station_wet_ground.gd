extends SceneTree
## Validate wet-ground accents without requiring a player or changed collision.
func _initialize() -> void:
    var errors: Array[String] = []
    var packed := load("res://scenes/ashfall_station_main.tscn") as PackedScene
    if packed == null:
        push_error("Station 04 scene missing")
        quit(1)
        return
    var level := packed.instantiate()
    var wet := level.get_node_or_null("EditableWorld/WetGround") as Node3D
    if wet == null or wet.get_script() == null:
        errors.append("WetGround script is not attached")
    else:
        wet.call("_build")
        if wet.get_child_count() != 9:
            errors.append("Expected nine authored wet-ground accents")
        for node in wet.get_children():
            if not (node is MeshInstance3D):
                errors.append("Wet-ground child is not a visual mesh")
                continue
            var mesh_node := node as MeshInstance3D
            if mesh_node.mesh == null:
                errors.append("Wet-ground mesh missing")
            elif not (mesh_node.mesh.surface_get_material(0) is ShaderMaterial):
                errors.append("Wet-ground material missing")
            if mesh_node.position.y < 0.005 or mesh_node.position.y > 0.05:
                errors.append("Wet-ground patch is not just above the walkable ground")
    level.free()
    if errors.is_empty():
        print("STATION 04 WET GROUND CHECK PASSED: nine decorative patches without collision")
        quit(0)
    else:
        for e in errors:
            push_error(e)
        quit(1)
