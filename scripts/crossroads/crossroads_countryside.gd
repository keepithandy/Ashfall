@tool
extends Node3D
## Crossroads outer farm belt, not a new level or new art kit.
## Four touching coarse collision-matched fields extend the authored 2m
## settlement: no distant see-through cliffs and no fake road-end void.
const PROFILE = preload("res://scripts/crossroads/crossroads_profile.gd")
const EARTH_SURFACE = preload("res://assets/materials/crossroads_earth.tres")
const BARE = preload("res://scenes/nature/bare_tree.tscn")
const PINE = preload("res://scenes/nature/forest_pine.tscn")
var land = PROFILE.new()
var fields: int = 0
var distant_trees: int = 0


func _ready() -> void:
    rebuild()


func rebuild() -> void:
    if has_node("Farmland"):
        return
    var root := Node3D.new()
    root.name = "Farmland"
    add_child(root)
    fields = 0
    # Every inner border shares the exact height function with the original
    # settlement; strips don't overlap its collision or each other.
    _field(root, "NorthernFields", -700.0, 700.0, -750.0, -210.0, 92, 36)
    _field(root, "SouthernFields", -700.0, 700.0, 210.0, 750.0, 92, 36)
    _field(root, "WesternFields", -700.0, -180.0, -210.0, 210.0, 36, 30)
    _field(root, "EasternFields", 180.0, 700.0, -210.0, 210.0, 36, 30)
    _tree_belt(root)


func _field(parent: Node3D, label: String, west: float, east: float, north: float, south: float, cols: int, rows: int) -> void:
    var vertices := PackedVector3Array()
    var normals := PackedVector3Array()
    var uv := PackedVector2Array()
    var colors := PackedColorArray()
    var stride := cols + 1
    for row in range(rows + 1):
        var z := lerpf(north, south, float(row) / float(rows))
        for col in range(cols + 1):
            var x := lerpf(west, east, float(col) / float(cols))
            var y := land.outer_height_at(x, z)
            vertices.append(Vector3(x, y, z))
            var slope_x := (land.outer_height_at(x + 3.0, z) - land.outer_height_at(x - 3.0, z)) / 6.0
            var slope_z := (land.outer_height_at(x, z + 3.0) - land.outer_height_at(x, z - 3.0)) / 6.0
            normals.append(Vector3(-slope_x, 1.0, -slope_z).normalized())
            uv.append(Vector2(x / 13.0, z / 13.0))
            var tint: float = 0.83 + float(land.noise.get_noise_2d(x, z)) * 0.11
            colors.append(Color(tint, tint * 0.93, tint * 0.81, 1.0))
    var triangles := PackedInt32Array()
    for row in range(rows):
        for col in range(cols):
            var a := row * stride + col
            var b := a + 1
            var c := a + stride
            var d := c + 1
            # Match the central terrain's front-facing clockwise winding.
            # The old reversed order made all four outer fields invisible.
            triangles.append_array(PackedInt32Array([a, b, c, b, d, c]))
    var arrays: Array = []
    arrays.resize(Mesh.ARRAY_MAX)
    arrays[Mesh.ARRAY_VERTEX] = vertices
    arrays[Mesh.ARRAY_NORMAL] = normals
    arrays[Mesh.ARRAY_TEX_UV] = uv
    arrays[Mesh.ARRAY_COLOR] = colors
    arrays[Mesh.ARRAY_INDEX] = triangles
    var mesh := ArrayMesh.new()
    mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
    # Identical world-space material eliminates the grey/white outer-field seam.
    mesh.surface_set_material(0, EARTH_SURFACE)
    var ground := StaticBody3D.new()
    ground.name = label
    ground.collision_layer = 1
    ground.collision_mask = 0
    parent.add_child(ground)
    var visual := MeshInstance3D.new()
    visual.name = "FieldGround"
    visual.mesh = mesh
    visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    ground.add_child(visual)
    var shape := CollisionShape3D.new()
    shape.name = "CountryGroundCollision"
    var hit_shape := mesh.create_trimesh_shape() as ConcavePolygonShape3D
    hit_shape.backface_collision = true
    shape.shape = hit_shape
    ground.add_child(shape)
    fields += 1


func _tree_belt(parent: Node3D) -> void:
    var forest := Node3D.new()
    forest.name = "FarTreeLine"
    parent.add_child(forest)
    var rng := RandomNumberGenerator.new()
    rng.seed = 23877
    distant_trees = 0
    for i in range(125):
        # Long staggered belts outside individual village fences. Avoid
        # blocking the main-road vanishing point to the north and south.
        var at_x := 0.0
        var at_z := 0.0
        if i < 80:
            var side := -1.0 if i % 2 == 0 else 1.0
            at_x = side * rng.randf_range(205.0, 490.0)
            at_z = rng.randf_range(-600.0, 600.0)
        else:
            at_x = rng.randf_range(-590.0, 590.0)
            at_z = (-1.0 if i % 2 == 0 else 1.0) * rng.randf_range(252.0, 590.0)
        if absf(at_x) < 24.0:
            continue
        var packed := BARE if i % 3 == 0 else PINE
        var tree := packed.instantiate() as Node3D
        tree.name = "FarTree%03d" % i
        tree.position = Vector3(at_x, land.outer_height_at(at_x, at_z), at_z)
        tree.rotation.y = rng.randf_range(-PI, PI)
        var s := rng.randf_range(0.85, 1.42)
        tree.scale = Vector3.ONE * s
        forest.add_child(tree)
        if tree is CollisionObject3D:
            tree.collision_layer = 0
            tree.collision_mask = 0
        for body in tree.find_children("*", "CollisionObject3D", true, false):
            var hit := body as CollisionObject3D
            hit.collision_layer = 0
            hit.collision_mask = 0
        for visual in tree.find_children("*", "GeometryInstance3D", true, false):
            var mesh_item := visual as GeometryInstance3D
            mesh_item.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
            mesh_item.visibility_range_end = 740.0
        distant_trees += 1
