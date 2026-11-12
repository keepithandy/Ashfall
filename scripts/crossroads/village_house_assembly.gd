@tool
extends Node3D
## Crossroads 2.3: TWO original building configurations assembled solely
## from the existing Crossroads modular kit, existing material textures and
## existing packaged furnishings. No new meshes downloaded or authored.
## Variant 0: three-bay Blue Sill Cottage, 12 x 8 metres.
## Variant 1: two-bay Lane Brick House, 8 x 12 metres, with rear utility wing.

@export_enum("Blue Sill Cottage", "Lane Brick House") var house_type: int = 0

const WALL = preload("res://scenes/crossroads_kit/wall_solid_4m.tscn")
const WINDOW = preload("res://scenes/crossroads_kit/wall_window_4m.tscn")
const DOOR = preload("res://scenes/crossroads_kit/wall_door_4m.tscn")
const SMALL = preload("res://scenes/crossroads_kit/wall_solid_2m.tscn")
const FLOOR = preload("res://scenes/crossroads_kit/floor_4m.tscn")
const METAL_DOOR = preload("res://scenes/crossroads_kit/metal_door.tscn")
const MATERIAL_PLASTER = preload("res://assets/materials/grey_plaster/albedo.jpg")
const MATERIAL_PLASTER_NORMAL = preload("res://assets/materials/grey_plaster/normal.jpg")
const MATERIAL_PLASTER_ROUGH = preload("res://assets/materials/grey_plaster/roughness.jpg")
const MATERIAL_BRICK = preload("res://assets/materials/rough_plaster_brick_02/albedo.jpg")
const MATERIAL_BRICK_NORMAL = preload("res://assets/materials/rough_plaster_brick_02/normal.jpg")
const MATERIAL_BRICK_ROUGH = preload("res://assets/materials/rough_plaster_brick_02/roughness.jpg")
const MATERIAL_ROOF = preload("res://assets/materials/rusty_corrugated_iron/albedo.jpg")
const MATERIAL_ROOF_NORMAL = preload("res://assets/materials/rusty_corrugated_iron/normal.jpg")
const MATERIAL_ROOF_ROUGH = preload("res://assets/materials/rusty_corrugated_iron/roughness.jpg")
const MATERIAL_WOOD = preload("res://assets/materials/wood_peeling_paint_weathered/albedo.jpg")

const FURNISHINGS := {
    "bench": "res://scenes/props/wooden_bench.tscn",
    "cot": "res://scenes/props/field_cot.tscn",
    "shelf": "res://scenes/props/shelving_unit.tscn",
    "bucket": "res://scenes/props/metal_bucket.tscn",
    "dresser": "res://scenes/decorative_interiors/tilted_wooden_dresser.tscn",
    "chair": "res://scenes/decorative_world/sagging_porch_chair.tscn",
    "wood": "res://scenes/extra_dressing/firewood_stack.tscn",
    "crate": "res://scenes/workshop/open_wood_crate.tscn",
    "stove": "res://scenes/props/radiator.tscn",
    "rug": "res://scenes/decorative_interiors/threadbare_area_rug.tscn",
    "table": "res://scenes/decorative_interiors/splintered_dining_table.tscn",
    "kettle": "res://scenes/decorative_interiors/rusted_enamel_kettle.tscn",
}

var door_clearance := 1.3
var footprints: Vector2 = Vector2(12.0, 8.0)
var room_roof: MeshInstance3D
var authored_modules: int = 0
var furnished_count: int = 0
var exterior_wall_material: StandardMaterial3D
var roof_material: StandardMaterial3D
var timber_material: StandardMaterial3D
var paint_material: StandardMaterial3D


func _ready() -> void:
    rebuild()


func _material(color: Color, texture: Texture2D, normal_map: Texture2D = null, rough_map: Texture2D = null) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.albedo_texture = texture
    mat.roughness = 0.93
    mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
    mat.uv1_triplanar = true
    mat.uv1_world_triplanar = true
    mat.uv1_scale = Vector3(0.58, 0.58, 0.58)
    if normal_map != null:
        mat.normal_enabled = true
        mat.normal_scale = 0.35
        mat.normal_texture = normal_map
    if rough_map != null:
        mat.roughness_texture = rough_map
    return mat


func rebuild() -> void:
    if has_node("BuiltHouse"):
        return
    var root := Node3D.new()
    root.name = "BuiltHouse"
    add_child(root)
    var shell := Node3D.new()
    shell.name = "Shell"
    root.add_child(shell)
    var living := Node3D.new()
    living.name = "LivingSpaces"
    root.add_child(living)
    var finish := Node3D.new()
    finish.name = "ExteriorDetails"
    root.add_child(finish)
    var width := 12.0 if house_type == 0 else 8.0
    var depth := 8.0 if house_type == 0 else 12.0
    footprints = Vector2(width, depth)
    exterior_wall_material = _material(
        Color(0.88, 0.87, 0.80) if house_type == 0 else Color(0.79, 0.65, 0.54),
        MATERIAL_PLASTER if house_type == 0 else MATERIAL_BRICK,
        MATERIAL_PLASTER_NORMAL if house_type == 0 else MATERIAL_BRICK_NORMAL,
        MATERIAL_PLASTER_ROUGH if house_type == 0 else MATERIAL_BRICK_ROUGH
    )
    roof_material = _material(Color(0.56, 0.55, 0.52), MATERIAL_ROOF, MATERIAL_ROOF_NORMAL, MATERIAL_ROOF_ROUGH)
    roof_material.cull_mode = BaseMaterial3D.CULL_DISABLED
    roof_material.uv1_scale = Vector3(0.42, 0.42, 0.42)
    timber_material = _material(Color(0.53, 0.45, 0.37), MATERIAL_WOOD)
    paint_material = _material(
        Color(0.31, 0.51, 0.58) if house_type == 0 else Color(0.39, 0.47, 0.38),
        MATERIAL_WOOD
    )
    authored_modules = 0
    furnished_count = 0
    _build_floor(shell, width, depth)
    _build_wall_ring(shell, finish, width, depth)
    _build_gable(shell, width, depth)
    _build_threshold(finish, width, depth)
    if house_type == 1:
        _build_utility_wing(shell, finish)
    _furnish(living, width, depth)


func _add_module(where: Node3D, packed: PackedScene, name: String, at: Vector3, yaw: float, plaster: bool = true) -> Node3D:
    var part := packed.instantiate() as Node3D
    part.name = name
    part.position = at
    part.rotation.y = yaw
    where.add_child(part)
    if plaster:
        for visual in part.find_children("*", "MeshInstance3D", true, false):
            var mesh_visual := visual as MeshInstance3D
            mesh_visual.material_override = exterior_wall_material
    authored_modules += 1
    return part


func _build_floor(shell: Node3D, width: float, depth: float) -> void:
    for x in range(int(width / 4.0)):
        for z in range(int(depth / 4.0)):
            # Floor prefab occupies [0,4] X and [-4,0] Z.
            _add_module(shell, FLOOR, "GroundFloor_%d_%d" % [x, z],
                Vector3(-width * 0.5 + float(x) * 4.0, 0.01, depth * 0.5 - float(z) * 4.0), 0.0, false)


func _build_wall_ring(shell: Node3D, finish: Node3D, width: float, depth: float) -> void:
    var front_bays := int(width / 4.0)
    var side_bays := int(depth / 4.0)
    for i in range(front_bays):
        var base_x := -width * 0.5 + float(i) * 4.0
        var entrance := i == (1 if house_type == 0 else 0)
        var front_type: PackedScene = DOOR if entrance else WINDOW
        _add_module(shell, front_type, "Facade_%d" % i,
            Vector3(base_x, 0.0, depth * 0.5), 0.0)
        if not entrance:
            _window_infill(finish, base_x + 2.0, depth * 0.5 + 0.06, 0.0)
        _add_module(shell, WINDOW if i % 2 == 0 else WALL, "Back_%d" % i,
            Vector3(base_x + 4.0, 0.0, -depth * 0.5), PI)
        if i % 2 == 0:
            _window_infill(finish, base_x + 2.0, -depth * 0.5 - 0.06, PI)
    for i in range(side_bays):
        var base_z := -depth * 0.5 + float(i) * 4.0
        _add_module(shell, WINDOW if i == 0 else WALL, "Left_%d" % i,
            Vector3(-width * 0.5, 0.0, base_z), -PI / 2.0)
        if i == 0:
            _window_infill(finish, -width * 0.5 - 0.06, base_z + 2.0, PI / 2.0)
        _add_module(shell, WINDOW if i == side_bays - 1 else WALL, "Right_%d" % i,
            Vector3(width * 0.5, 0.0, base_z + 4.0), PI / 2.0)
        if i == side_bays - 1:
            _window_infill(finish, width * 0.5 + 0.06, base_z + 2.0, PI / 2.0)
    # Functional entrance: no closed door collider obstructs the doorway.
    # A visibly swung door, using the existing modular steel-door visual,
    # sits just beside the frame rather than across the opening.
    var door_x := (-width * 0.5 + 6.0) if house_type == 0 else (-width * 0.5 + 2.0)
    var door := _add_module(finish, METAL_DOOR, "WeatheredOpenDoor",
        Vector3(door_x - 0.63, 0.0, depth * 0.5 + 0.21), -1.34, false)
    _nonblocking(door)
    _box(finish, "DoorLintelPaint", Vector3(door_x, 2.46, depth * 0.5 + 0.16),
        Vector3(1.64, 0.12, 0.13), paint_material)


func _window_infill(parent: Node3D, x: float, z: float, yaw: float) -> void:
    var pane_mat := StandardMaterial3D.new()
    pane_mat.albedo_color = Color(0.19, 0.25, 0.22, 0.41)
    pane_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    pane_mat.roughness = 0.43
    pane_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    var mount := Node3D.new()
    mount.position = Vector3(x, 0, z)
    mount.rotation.y = yaw
    parent.add_child(mount)
    _box(mount, "OldGlazing", Vector3(0, 1.53, 0),
        Vector3(1.62, 1.13, 0.02), pane_mat)
    _box(mount, "PaintedSill", Vector3(0, 0.965, 0.075),
        Vector3(1.85, 0.11, 0.17), paint_material)
    _box(mount, "SashCentre", Vector3(0, 1.55, 0.08),
        Vector3(0.07, 1.18, 0.07), paint_material)
    _box(mount, "SashRail", Vector3(0, 1.54, 0.08),
        Vector3(1.78, 0.075, 0.07), paint_material)


func _box(parent: Node3D, name: String, at: Vector3, dimensions: Vector3, material: Material) -> MeshInstance3D:
    var part := MeshInstance3D.new()
    part.name = name
    var box := BoxMesh.new()
    box.size = dimensions
    part.mesh = box
    part.position = at
    part.material_override = material
    parent.add_child(part)
    return part


func _add_roof_quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
    for point in [a, b, c, b, d, c]:
        st.set_uv(Vector2(point.x / 2.8, point.z / 2.8))
        st.add_vertex(point)


func _build_gable(shell: Node3D, width: float, depth: float) -> void:
    var overhang := 0.58
    var eave := 3.23
    var peak := 4.85 if house_type == 0 else 5.13
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    st.set_material(roof_material)
    if house_type == 0:
        var l := -width * 0.5 - overhang
        var r := width * 0.5 + overhang
        var north := -depth * 0.5 - overhang
        var south := depth * 0.5 + overhang
        _add_roof_quad(st, Vector3(l, eave, south), Vector3(r, eave, south),
            Vector3(l, peak, 0), Vector3(r, peak, 0))
        _add_roof_quad(st, Vector3(l, peak, 0), Vector3(r, peak, 0),
            Vector3(l, eave, north), Vector3(r, eave, north))
    else:
        var l := -width * 0.5 - overhang
        var r := width * 0.5 + overhang
        var north := -depth * 0.5 - overhang
        var south := depth * 0.5 + overhang
        _add_roof_quad(st, Vector3(l, eave, south), Vector3(l, eave, north),
            Vector3(0, peak, south), Vector3(0, peak, north))
        _add_roof_quad(st, Vector3(0, peak, south), Vector3(0, peak, north),
            Vector3(r, eave, south), Vector3(r, eave, north))
    st.generate_normals()
    room_roof = MeshInstance3D.new()
    room_roof.name = "CorrugatedPitchedRoof"
    room_roof.mesh = st.commit()
    room_roof.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
    shell.add_child(room_roof)
    # Gable closures ensure there are no transparent triangles above the walls.
    _fill_gables(shell, width, depth, peak)


func _fill_gables(parent: Node3D, width: float, depth: float, peak: float) -> void:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    st.set_material(exterior_wall_material)
    if house_type == 0:
        for x in [-width * 0.5, width * 0.5]:
            for point in [Vector3(x, 3.18, -depth * 0.5), Vector3(x, 3.18, depth * 0.5), Vector3(x, peak, 0)]:
                st.set_uv(Vector2(point.z / 2.0, point.y / 2.0))
                st.add_vertex(point)
    else:
        for z in [-depth * 0.5, depth * 0.5]:
            for point in [Vector3(-width * 0.5, 3.18, z), Vector3(0, peak, z), Vector3(width * 0.5, 3.18, z)]:
                st.set_uv(Vector2(point.x / 2.0, point.y / 2.0))
                st.add_vertex(point)
    st.generate_normals()
    var end_caps := MeshInstance3D.new()
    end_caps.name = "SolidGableEnds"
    end_caps.mesh = st.commit()
    parent.add_child(end_caps)


func _build_threshold(parent: Node3D, width: float, depth: float) -> void:
    var entry_x := 0.0 if house_type == 0 else -2.0
    _box(parent, "WornThreshold", Vector3(entry_x, 0.014, depth * 0.5 + 0.6),
        Vector3(2.2, 0.025, 1.15), timber_material)
    # Painted eave on short timber posts, not a futuristic marquee.
    for x in [-1.4, 1.4]:
        _box(parent, "PorchSupport", Vector3(entry_x + x, 1.24, depth * 0.5 + 1.75),
            Vector3(0.14, 2.45, 0.14), timber_material)
    _box(parent, "SmallPorchRoof", Vector3(entry_x, 2.54, depth * 0.5 + 0.98),
        Vector3(3.5, 0.14, 2.1), roof_material)


func _build_utility_wing(shell: Node3D, finish: Node3D) -> void:
    var side := 4.0
    var left := 4.1
    var back := -6.0
    _add_module(shell, FLOOR, "UtilitySlab", Vector3(left, 0.005, back + 4.0), 0.0, false)
    _add_module(shell, WALL, "UtilityEastWall", Vector3(left + side, 0, back + side), PI / 2.0)
    _add_module(shell, WALL, "UtilityRearWall", Vector3(left + side, 0, back), PI)
    _box(finish, "LeanToRoof", Vector3(left + side * 0.5, 3.12, back + side * 0.5),
        Vector3(side + 0.35, 0.17, side + 0.45), roof_material)
    _furnishing(finish, "wood", Vector3(left + 1.2, 0.02, back + 1.0), 1.0)
    _furnishing(finish, "bucket", Vector3(left + 2.8, 0.03, back + 2.9), 0.2)


func _furnishing(parent: Node3D, item: String, at: Vector3, yaw: float = 0.0) -> void:
    var packed := load(FURNISHINGS[item]) as PackedScene
    if packed == null:
        push_warning("Crossroads 2.3 home missing furniture: " + item)
        return
    var part := packed.instantiate() as Node3D
    part.name = item.capitalize() + str(furnished_count)
    part.position = at
    part.rotation.y = yaw
    parent.add_child(part)
    furnished_count += 1


func _furnish(parent: Node3D, width: float, depth: float) -> void:
    if house_type == 0:
        _furnishing(parent, "cot", Vector3(-4.30, 0.02, -1.8), 1.57)
        _furnishing(parent, "dresser", Vector3(4.1, 0.02, -2.9), PI)
        _furnishing(parent, "table", Vector3(2.75, 0.03, 0.8), 0.20)
        _furnishing(parent, "chair", Vector3(3.4, 0.03, 2.45), -0.5)
        _furnishing(parent, "shelf", Vector3(-4.9, 0.02, 0.3), PI / 2.0)
        _furnishing(parent, "bucket", Vector3(-4.65, 0.02, 2.7), 0.5)
        _furnishing(parent, "rug", Vector3(-0.8, 0.032, -1.6), -0.1)
        _furnishing(parent, "bench", Vector3(-2.8, 0.02, 2.9), 0.0)
    else:
        # A half-width partition makes a rear work/sleeping area, but leaves
        # a doorway in the middle; no artificial sealed prefab cube.
        _add_module(parent, SMALL, "RoomPartitionLeft", Vector3(-4, 0, 0), 0.0)
        _add_module(parent, SMALL, "RoomPartitionRight", Vector3(2, 0, 0), 0.0)
        _furnishing(parent, "cot", Vector3(-2.1, 0.02, -3.7), 0.0)
        _furnishing(parent, "dresser", Vector3(2.5, 0.02, -4.2), PI)
        _furnishing(parent, "table", Vector3(1.6, 0.03, 2.15), -0.23)
        _furnishing(parent, "chair", Vector3(2.6, 0.03, 3.85), 0.5)
        _furnishing(parent, "shelf", Vector3(-2.8, 0.03, 2.1), PI / 2.0)
        _furnishing(parent, "rug", Vector3(0.4, 0.028, -2.0), 0.2)
        _furnishing(parent, "crate", Vector3(1.1, 0.04, 4.4), 0.6)


func _nonblocking(root: Node3D) -> void:
    if root is CollisionObject3D:
        root.collision_layer = 0
        root.collision_mask = 0
    for item in root.find_children("*", "CollisionObject3D", true, false):
        var body := item as CollisionObject3D
        body.collision_layer = 0
        body.collision_mask = 0
