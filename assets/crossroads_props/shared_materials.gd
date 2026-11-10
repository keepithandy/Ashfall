@tool
extends Node3D

const SHARED := {
    "shared_iron": "res://assets/props/iron.tres",
    "shared_rust": "res://assets/crossroads_props/materials/aged_rust.tres",
    "shared_olive": "res://assets/crossroads_props/materials/jack_enamel.tres",
    "shared_rubber": "res://assets/props/rubber.tres",
    "shared_wood": "res://assets/props/wood.tres",
    "shared_bark": "res://assets/crossroads_props/materials/root_bark.tres",
    "shared_endgrain": "res://assets/nature/endgrain.tres",
    "fungus_cap": "res://assets/crossroads_props/materials/fungus_cap.tres",
    "fungus_gill_detail": "res://assets/crossroads_props/materials/fungus_gill_detail.tres",
    "fungus_gill": "res://assets/crossroads_props/materials/fungus_gill.tres",
    "root_soil": "res://assets/crossroads_props/materials/root_soil.tres",
    "root_moss": "res://assets/crossroads_props/materials/root_moss.tres"
}
func _ready() -> void:
    _apply(get_node_or_null("Visual"))
func _apply(node: Node) -> void:
    if node == null: return
    if node is MeshInstance3D:
        var mesh_node := node as MeshInstance3D
        for i in range(mesh_node.mesh.get_surface_count()):
            var source := mesh_node.mesh.surface_get_material(i)
            if source == null: continue
            var key := source.resource_name.to_lower()
            if SHARED.has(key): mesh_node.set_surface_override_material(i, load(SHARED[key]))
    for child in node.get_children(): _apply(child)

