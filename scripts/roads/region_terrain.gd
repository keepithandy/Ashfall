@tool
extends StaticBody3D
## Regional heightfield terrain with matching triangulated collision.
## The resolution is fixed by RegionHeightProfile, so roads can sample
## the exact SAME triangles rather than float above the rendered terrain.

const PROFILE = preload("res://scripts/roads/region_height_profile.gd")
const TERRAIN_SHADER = preload("res://assets/shaders/ashfall_region_terrain.gdshader")
const FOREST_TEX = preload("res://assets/materials/forest_ground_05/albedo.jpg")
const ROCK_TEX = preload("res://assets/materials/rough_plaster_brick_02/albedo.jpg")

var profile = PROFILE.new()

func _ready() -> void:
    _rebuild()

func get_height(x: float, z: float) -> float:
    return profile.surface_height_at(x, z)

func _rebuild() -> void:
    if not is_inside_tree():
        return
    for child in get_children():
        if child.get_meta("ashfall_heightfield_generated", false):
            child.free()

    var columns: int = PROFILE.GRID_COLUMNS
    var rows: int = PROFILE.GRID_ROWS
    var width: float = PROFILE.WIDTH
    var depth: float = PROFILE.DEPTH
    var step_x: float = PROFILE.GRID_STEP_X
    var step_z: float = PROFILE.GRID_STEP_Z
    var stride := columns + 1

    var heights := PackedFloat32Array()
    heights.resize((columns + 1) * (rows + 1))
    var vertices := PackedVector3Array()
    var normals := PackedVector3Array()
    var uvs := PackedVector2Array()
    vertices.resize(heights.size())
    normals.resize(heights.size())
    uvs.resize(heights.size())

    for iz in range(rows + 1):
        var z := -depth * 0.5 + float(iz) * step_z
        for ix in range(columns + 1):
            var x := -width * 0.5 + float(ix) * step_x
            var index := iz * stride + ix
            var y: float = profile.height_at(x, z)
            heights[index] = y
            vertices[index] = Vector3(x, y, z)
            uvs[index] = Vector2(x / 9.0, z / 9.0)

    # Smoothed vertex normals preserve a convincing continuous landscape,
    # even though collision and geometry remain simple deterministic triangles.
    for iz in range(rows + 1):
        for ix in range(columns + 1):
            var index := iz * stride + ix
            var west := maxi(0, ix - 1)
            var east := mini(columns, ix + 1)
            var north := maxi(0, iz - 1)
            var south := mini(rows, iz + 1)
            var dx := maxf(1.0, float(east - west) * step_x)
            var dz := maxf(1.0, float(south - north) * step_z)
            var gradient_x := (heights[iz * stride + east] - heights[iz * stride + west]) / dx
            var gradient_z := (heights[south * stride + ix] - heights[north * stride + ix]) / dz
            normals[index] = Vector3(-gradient_x, 1.0, -gradient_z).normalized()

    var triangles := PackedInt32Array()
    triangles.resize(columns * rows * 6)
    var cursor := 0
    for iz in range(rows):
        for ix in range(columns):
            var a := iz * stride + ix
            var b := a + 1
            var c := a + stride
            var d := c + 1
            # CCW winding for upward-facing normals in Godot's X/Z plane.
            triangles[cursor] = a
            triangles[cursor + 1] = c
            triangles[cursor + 2] = b
            triangles[cursor + 3] = b
            triangles[cursor + 4] = c
            triangles[cursor + 5] = d
            cursor += 6

    var arrays: Array = []
    arrays.resize(Mesh.ARRAY_MAX)
    arrays[Mesh.ARRAY_VERTEX] = vertices
    arrays[Mesh.ARRAY_NORMAL] = normals
    arrays[Mesh.ARRAY_TEX_UV] = uvs
    arrays[Mesh.ARRAY_INDEX] = triangles

    var terrain_mesh := ArrayMesh.new()
    terrain_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
    var terrain_material := ShaderMaterial.new()
    terrain_material.shader = TERRAIN_SHADER
    terrain_material.set_shader_parameter("forest_albedo", FOREST_TEX)
    terrain_material.set_shader_parameter("rock_albedo", ROCK_TEX)
    terrain_mesh.surface_set_material(0, terrain_material)

    var visual := MeshInstance3D.new()
    visual.name = "HeightfieldVisual"
    visual.mesh = terrain_mesh
    visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
    visual.set_meta("ashfall_heightfield_generated", true)
    add_child(visual)

    # A concave static collision uses precisely the same indexed mesh as the
    # visual terrain. This is for stationary world geometry only.
    var hit := CollisionShape3D.new()
    hit.name = "HeightfieldCollision"
    hit.shape = terrain_mesh.create_trimesh_shape()
    hit.set_meta("ashfall_heightfield_generated", true)
    add_child(hit)
