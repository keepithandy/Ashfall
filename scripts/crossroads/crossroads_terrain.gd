@tool
extends StaticBody3D
## Walkable Crossroads terrain. Actual 2m triangles AND matching collision:
## house foundations, road vertices and decoration sample the same profile.
const PROFILE = preload("res://scripts/crossroads/crossroads_profile.gd")
const SOIL = preload("res://assets/materials/forest_ground_05/albedo.jpg")
const SOIL_NORMAL = preload("res://assets/materials/forest_ground_05/normal.jpg")
const SOIL_ROUGH = preload("res://assets/materials/forest_ground_05/roughness.jpg")
var terrain = PROFILE.new()
var vertex_count: int = 0
var cell_count: int = 0


func _ready() -> void:
    # Keep authored node name stable for scene editing and path-based acceptance checks.
    collision_layer = 1
    collision_mask = 0
    rebuild()


func get_height(x: float, z: float) -> float:
    return terrain.surface_height_at(x, z)


func rebuild() -> void:
    if has_node("WalkableTerrainVisual"):
        return
    var width := PROFILE.WIDTH
    var depth := PROFILE.DEPTH
    var columns := PROFILE.COLUMNS
    var rows := PROFILE.ROWS
    var dx := width / float(columns)
    var dz := depth / float(rows)
    var stride := columns + 1
    var count := stride * (rows + 1)
    var vertices := PackedVector3Array()
    var normals := PackedVector3Array()
    var uv := PackedVector2Array()
    var colors := PackedColorArray()
    vertices.resize(count)
    normals.resize(count)
    uv.resize(count)
    colors.resize(count)
    for row in range(rows + 1):
        var z := -depth * 0.5 + float(row) * dz
        for col in range(columns + 1):
            var x := -width * 0.5 + float(col) * dx
            var index := row * stride + col
            var y := terrain.height_at(x, z)
            var grad_x := (terrain.height_at(x + dx, z) - terrain.height_at(x - dx, z)) / (2.0 * dx)
            var grad_z := (terrain.height_at(x, z + dz) - terrain.height_at(x, z - dz)) / (2.0 * dz)
            vertices[index] = Vector3(x, y, z)
            normals[index] = Vector3(-grad_x, 1.0, -grad_z).normalized()
            uv[index] = Vector2(x / 8.0, z / 8.0)
            var hue := clampf(0.91 + terrain.noise.get_noise_2d(x * 2.0, z * 2.0) * 0.12, 0.78, 1.0)
            colors[index] = Color(hue, hue * 0.96, hue * 0.89, 1)
    var tris := PackedInt32Array()
    tris.resize(rows * columns * 6)
    var cursor := 0
    for row in range(rows):
        for col in range(columns):
            var a := row * stride + col
            var b := a + 1
            var c := a + stride
            var d := c + 1
            tris[cursor] = a
            tris[cursor + 1] = c
            tris[cursor + 2] = b
            tris[cursor + 3] = b
            tris[cursor + 4] = c
            tris[cursor + 5] = d
            cursor += 6
    var arrays: Array = []
    arrays.resize(Mesh.ARRAY_MAX)
    arrays[Mesh.ARRAY_VERTEX] = vertices
    arrays[Mesh.ARRAY_NORMAL] = normals
    arrays[Mesh.ARRAY_TEX_UV] = uv
    arrays[Mesh.ARRAY_COLOR] = colors
    arrays[Mesh.ARRAY_INDEX] = tris
    var mesh := ArrayMesh.new()
    mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
    var material := StandardMaterial3D.new()
    material.albedo_texture = SOIL
    material.normal_texture = SOIL_NORMAL
    material.normal_enabled = true
    material.normal_scale = 0.44
    material.roughness_texture = SOIL_ROUGH
    material.roughness = 1.0
    material.vertex_color_use_as_albedo = true
    material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
    material.uv1_triplanar = true
    material.uv1_world_triplanar = true
    material.uv1_scale = Vector3(0.45, 0.45, 0.45)
    mesh.surface_set_material(0, material)
    var visual := MeshInstance3D.new()
    visual.name = "WalkableTerrainVisual"
    visual.mesh = mesh
    add_child(visual)
    var collision := CollisionShape3D.new()
    collision.name = "WalkableTerrainCollision"
    var hit_shape := mesh.create_trimesh_shape() as ConcavePolygonShape3D
    # A traversable heightfield must respond from both sides at intersecting
    # slopes and shared borders; the visible mesh stays unchanged.
    hit_shape.backface_collision = true
    collision.shape = hit_shape
    add_child(collision)
    vertex_count = count
    cell_count = rows * columns
