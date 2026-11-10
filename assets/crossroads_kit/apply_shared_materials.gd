@tool
extends Node3D

# Resolve imported surfaces to the same project materials for every kit instance.
func _ready() -> void:
    _apply_to(get_node_or_null("Visual"))

func _apply_to(node: Node) -> void:
    if node == null:
        return
    if node is MeshInstance3D:
        var mesh_instance := node as MeshInstance3D
        for surface in mesh_instance.mesh.get_surface_count():
            var original := mesh_instance.mesh.surface_get_material(surface)
            if original == null:
                continue
            var mat_name := original.resource_name.to_lower()
            var file := ""
            if "concrete" in mat_name: file = "concrete"
            elif "plaster" in mat_name: file = "plaster"
            elif "corroded" in mat_name: file = "steel"
            elif "enamel" in mat_name: file = "paint"
            elif "blackened" in mat_name: file = "dark"
            if file != "":
                mesh_instance.set_surface_override_material(surface, load("res://assets/crossroads_kit/materials/" + file + ".tres"))
    for child in node.get_children():
        _apply_to(child)
