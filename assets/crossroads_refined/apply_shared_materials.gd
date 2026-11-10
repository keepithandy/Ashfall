@tool
extends EditorScenePostImport

# Reuse the project's scanned texture sets across Blender-exported modules.
# The GLBs keep embedded fallback textures for editing outside Godot.
const PLASTER = preload("res://assets/crossroads_kit/materials/plaster.tres")
const ROOF = preload("res://assets/crossroads_refined/roof_material.tres")

func _post_import(scene: Node) -> Object:
	apply_to(scene)
	return scene

func apply_to(node: Node) -> void:
	if node is MeshInstance3D and node.mesh is ArrayMesh:
		for index in node.mesh.get_surface_count():
			var material: Material = node.mesh.surface_get_material(index)
			if material == null:
				continue
			if material.resource_name.begins_with("Weathered maintenance wall"):
				node.mesh.surface_set_material(index, PLASTER)
			elif material.resource_name.begins_with("Weathered corrugated steel"):
				node.mesh.surface_set_material(index, ROOF)
	for child in node.get_children():
		apply_to(child)
