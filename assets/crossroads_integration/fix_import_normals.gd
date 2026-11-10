@tool
extends EditorScenePostImport

# The supplied Crossroads v0.2/v0.3 GLBs have UVs but no normals. Generate
# face normals and tangent space at import so their PBR normal maps render.
func _post_import(scene: Node) -> Object:
    _repair_meshes(scene)
    return scene

func _repair_meshes(node: Node) -> void:
    if node is MeshInstance3D and node.mesh is ArrayMesh:
        var source: ArrayMesh = node.mesh
        var repaired := ArrayMesh.new()
        var changed := false
        for index in source.get_surface_count():
            var arrays := source.surface_get_arrays(index)
            if arrays[Mesh.ARRAY_NORMAL] == null and source.surface_get_primitive_type(index) == Mesh.PRIMITIVE_TRIANGLES:
                var tool := SurfaceTool.new()
                tool.create_from(source, index)
                tool.deindex()
                var flat_arrays := tool.commit_to_arrays()
                var vertices: PackedVector3Array = flat_arrays[Mesh.ARRAY_VERTEX]
                var normals := PackedVector3Array()
                normals.resize(vertices.size())
                # Imported concrete boxes have hard edges. Smoothing by shared
                # position creates dark diagonal bands across their large faces.
                for triangle in range(0, vertices.size(), 3):
                    var normal := (vertices[triangle + 2] - vertices[triangle]).cross(vertices[triangle + 1] - vertices[triangle]).normalized()
                    for corner in 3:
                        normals[triangle + corner] = normal
                flat_arrays[Mesh.ARRAY_NORMAL] = normals
                flat_arrays[Mesh.ARRAY_TANGENT] = null
                var intermediate := ArrayMesh.new()
                intermediate.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, flat_arrays)
                tool.create_from(intermediate, 0)
                if flat_arrays[Mesh.ARRAY_TEX_UV] != null:
                    tool.generate_tangents()
                tool.set_material(source.surface_get_material(index))
                tool.commit(repaired)
                changed = true
            else:
                repaired.add_surface_from_arrays(source.surface_get_primitive_type(index), arrays)
                repaired.surface_set_material(repaired.get_surface_count() - 1, source.surface_get_material(index))
        if changed:
            node.mesh = repaired
    for child in node.get_children():
        _repair_meshes(child)
