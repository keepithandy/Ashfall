@tool
extends Node3D
## A curated rural street, not an evenly distributed prop cloud.
## Existing houses and existing decorative props only; the two new prefabs
## are the separately authored Blue Sill and Lane Brick houses.
const PROFILE = preload("res://scripts/crossroads/crossroads_profile.gd")
const GROUND_MATERIAL = preload("res://assets/roads/gravel_shoulder.tres")
const WOOD_TEXTURE = preload("res://assets/materials/wood_peeling_paint_weathered/albedo.jpg")
const SOIL_TEXTURE = preload("res://assets/materials/forest_ground_05/albedo.jpg")
const HOUSES := {
    "white": "res://scenes/houses/white_garden_house.tscn",
    "green": "res://scenes/houses/green_longhouse.tscn",
    "ochre": "res://scenes/houses/ochre_workers_house.tscn",
    "blue_sill": "res://scenes/houses/blue_sill_crossroads.tscn",
    "lane_brick": "res://scenes/houses/lane_brick_crossroads.tscn"
}
const PROP := {
    "bench": "res://scenes/props/wooden_bench.tscn",
    "chair": "res://scenes/decorative_world/sagging_porch_chair.tscn",
    "table": "res://scenes/decorative_world/rotting_picnic_table.tscn",
    "wood": "res://scenes/extra_dressing/firewood_stack.tscn",
    "barrow": "res://scenes/workshop/wheelbarrow.tscn",
    "bucket": "res://scenes/props/metal_bucket.tscn",
    "rust": "res://scenes/props/rusted_drum.tscn",
    "pallet": "res://scenes/props/wooden_pallet.tscn",
    "crate": "res://scenes/workshop/open_wood_crate.tscn",
    "sawhorse": "res://scenes/extra_dressing/wood_sawhorse.tscn",
    "shovel": "res://scenes/extra_dressing/garden_shovel.tscn",
    "wires": "res://scenes/decorative_world/collapsed_cable_tray.tscn",
    "pots": "res://scenes/decorative_world/cracked_plant_pots.tscn",
    "washing": "res://scenes/decorative_world/torn_clothesline.tscn",
    "mail": "res://scenes/decorative_world/rusted_mailbox.tscn",
    "sheet": "res://scenes/decorative_world/corroded_sheet_metal_stack.tscn",
    "tyres": "res://scenes/decorative_world/discarded_tire_pile.tscn",
    "culvert": "res://scenes/decorative_world/broken_drainage_culvert.tscn",
    "shelter": "res://scenes/decorative_world/collapsed_bus_shelter.tscn",
    "guardrail": "res://scenes/decorative_world/bent_guardrail.tscn",
    "pine": "res://scenes/nature/forest_pine.tscn",
    "bare": "res://scenes/nature/bare_tree.tscn",
    "stump": "res://scenes/nature/tree_stump.tscn",
    "shrub": "res://scenes/nature/low_shrub.tscn",
    "bramble": "res://scenes/nature/dry_bramble.tscn",
    "grass": "res://scenes/extra_dressing/dry_grass_tuft.tscn",
    "fern": "res://scenes/nature/fern_clump.tscn",
    "logs": "res://scenes/nature/fallen_log.tscn",
    "branch": "res://scenes/nature/dead_branch_pile.tscn",
    "stone": "res://scenes/nature/mossy_boulder.tscn"
}

const YARD_GROUPS := [
    ["wood", "barrow", "bucket", "crate", "shovel", "chair"],
    ["pots", "table", "bench", "wood", "barrow", "bucket"],
    ["wood", "sawhorse", "shovel", "crate", "chair", "logs"],
    ["pots", "table", "shovel", "bench", "wood", "bucket"],
    ["wires", "pallet", "rust", "sawhorse", "tyres", "sheet"],
    ["barrow", "bucket", "wood", "shovel", "bench", "stone"],
    ["washing", "pots", "wood", "chair", "crate", "bucket"],
    ["wood", "shovel", "table", "pots", "barrow", "bench"],
    ["tyres", "logs", "branch", "sheet", "wood", "shovel"],
    ["rust", "pallet", "wires", "sawhorse", "crate", "bucket"],
    ["pots", "bench", "wood", "shovel", "chair", "barrow"],
    ["wood", "pots", "branch", "sawhorse", "bucket", "chair"]
]

var land = PROFILE.new()
var rng := RandomNumberGenerator.new()
var stock: Dictionary = {}
var houses_placed := 0
var walkable_gate_count := 0
var fence_sections := 0
var garden_props := 0
var trees_placed := 0
var undergrowth_placed := 0
var utility_poles := 0
var boundary_obstacles := 0
var material_fence: Array[StandardMaterial3D] = []
var garden_soil: StandardMaterial3D
var pole_wood: StandardMaterial3D
var wire_mat: StandardMaterial3D


func _ready() -> void:
    # Preserve the authored scene node path for the playtest and editor.
    rng.seed = 239187
    rebuild()


func _material(tint: Color, texture: Texture2D = null) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = tint
    mat.roughness = 0.96
    if texture != null:
        mat.albedo_texture = texture
        mat.uv1_triplanar = true
        mat.uv1_world_triplanar = true
        mat.uv1_scale = Vector3(0.58, 0.58, 0.58)
    return mat


func rebuild() -> void:
    if has_node("Authoring"):
        return
    rng.seed = 239187
    stock.clear()
    var root := Node3D.new()
    root.name = "Authoring"
    add_child(root)
    var homes := Node3D.new()
    homes.name = "Homesteads"
    root.add_child(homes)
    var countryside := Node3D.new()
    countryside.name = "Countryside"
    root.add_child(countryside)
    var utilities := Node3D.new()
    utilities.name = "RoadUtilities"
    root.add_child(utilities)
    material_fence = [
        _material(Color(0.56, 0.58, 0.47), WOOD_TEXTURE),
        _material(Color(0.41, 0.48, 0.43), WOOD_TEXTURE),
        _material(Color(0.47, 0.37, 0.30), WOOD_TEXTURE)
    ]
    garden_soil = _material(Color(0.34, 0.32, 0.27), SOIL_TEXTURE)
    pole_wood = _material(Color(0.28, 0.26, 0.23), WOOD_TEXTURE)
    wire_mat = _material(Color(0.16, 0.17, 0.15))
    houses_placed = 0
    walkable_gate_count = 0
    fence_sections = 0
    garden_props = 0
    trees_placed = 0
    undergrowth_placed = 0
    for i in range(PROFILE.HOMES.size()):
        _homestead(homes, PROFILE.HOMES[i], i)
    _country_vegetation(countryside)
    _roadside_stories(utilities)
    _power_line(utilities)


func _asset(path: String) -> PackedScene:
    if not stock.has(path):
        stock[path] = load(path) as PackedScene
    return stock[path] as PackedScene


func _place(parent: Node3D, id: String, x: float, z: float, rotation_y: float = 0.0, scale_value: float = 1.0, collision: bool = true) -> Node3D:
    if not PROP.has(id):
        return null
    var packed := _asset(PROP[id])
    if packed == null:
        push_warning("Missing Crossroads dressing scene " + str(PROP[id]))
        return null
    var at := packed.instantiate() as Node3D
    at.name = id.capitalize() + "_%04d" % parent.get_child_count()
    at.position = Vector3(x, land.surface_height_at(x, z), z)
    at.rotation.y = rotation_y
    at.scale = Vector3.ONE * scale_value
    parent.add_child(at)
    if not collision:
        _visual_only(at)
    return at


func _visual_only(node: Node3D) -> void:
    if node is CollisionObject3D:
        node.collision_layer = 0
        node.collision_mask = 0
    for item in node.find_children("*", "CollisionObject3D", true, false):
        var body := item as CollisionObject3D
        body.collision_layer = 0
        body.collision_mask = 0


func _homestead(parent: Node3D, site: Dictionary, index: int) -> void:
    var plot := Node3D.new()
    plot.name = site["name"]
    plot.set_meta("ashfall_house_kind", site["kind"])
    plot.set_meta("ashfall_decor_theme", site["garden"])
    parent.add_child(plot)
    var x := float(site["x"])
    var z := float(site["z"])
    var side := int(site["side"])
    var house_scene := _asset(HOUSES[site["kind"]])
    if house_scene == null:
        push_error("Missing Crossroads house prefab " + str(HOUSES[site["kind"]]))
        return
    var home := house_scene.instantiate() as Node3D
    home.name = "Residence"
    home.position = Vector3(x, land.surface_height_at(x, z), z)
    home.rotation.y = float(site["yaw"])
    plot.add_child(home)
    houses_placed += 1
    # Walkable front opening in a private, irregularly planted plot. The
    # fence stops at the gate; no invisible collision box spans the gap.
    # Real homesteads are not a repeated identical rectangle.
    var near_x := float(side) * (18.8 + float(index % 3) * 1.1)
    var far_x := float(side) * (67.5 + float(index % 4) * 1.35)
    var lot_half := 15.9 + float(index % 4) * 0.83
    var gate_half := 2.2 + float(index % 3) * 0.20
    var front_z := z - lot_half
    var back_z := z + lot_half
    var palette: StandardMaterial3D = material_fence[index % material_fence.size()]
    _fence(plot, Vector2(near_x, front_z), Vector2(near_x, z - gate_half), palette, index)
    _fence(plot, Vector2(near_x, z + gate_half), Vector2(near_x, back_z), palette, index)
    _fence(plot, Vector2(far_x, front_z), Vector2(far_x, back_z), palette, index)
    _fence(plot, Vector2(near_x, front_z), Vector2(far_x, front_z), palette, index)
    _fence(plot, Vector2(near_x, back_z), Vector2(far_x, back_z), palette, index)
    _gate_post(plot, near_x, z - gate_half - 0.05, palette, "South")
    _gate_post(plot, near_x, z + gate_half + 0.05, palette, "North")
    walkable_gate_count += 1
    # The worn path continues from the road, through the actual gate,
    # onto the floor-height entrance for the respective house.
    var facade_offset := 4.0 if site["kind"] in ["blue_sill", "white", "ochre", "green"] else 6.0
    var door_x := x - float(side) * facade_offset
    var road_x := land.main_road_x(z) + float(side) * 4.7
    _footpath(plot, "GateToFrontDoor", Vector2(road_x, z), Vector2(door_x, z), 1.65)
    _yard_life(plot, site, index)
    _garden_beds(plot, site)
    _yard_trees(plot, site, index)


func _fence(parent: Node3D, a: Vector2, b: Vector2, mat: Material, plot_id: int) -> void:
    var delta := b - a
    var length := delta.length()
    if length < 0.5:
        return
    var center := (a + b) * 0.5
    var section := StaticBody3D.new()
    section.name = "PrivacyFence_%d" % fence_sections
    section.position = Vector3(center.x, land.surface_height_at(center.x, center.y), center.y)
    section.rotation.y = atan2(-delta.y, delta.x)
    parent.add_child(section)
    var posts := MultiMesh.new()
    var slat := BoxMesh.new()
    slat.size = Vector3(0.11, 1.52, 0.095)
    slat.material = mat
    var total := maxi(1, int(floor(length / 0.34)))
    posts.transform_format = MultiMesh.TRANSFORM_3D
    posts.mesh = slat
    posts.instance_count = total
    var origin_y := section.position.y
    for i in range(total):
        var along := -length * 0.5 + (float(i) + 0.5) * length / float(total)
        var pos_x := lerpf(a.x, b.x, (float(i) + 0.5) / float(total))
        var pos_z := lerpf(a.y, b.y, (float(i) + 0.5) / float(total))
        var base := land.surface_height_at(pos_x, pos_z)
        # Uneven and slightly leaning planks imply years of repairs. Missing
        # pickets are uncommon: the horizontal rail remains as a physical
        # barrier, so the player never encounters phantom solid walls.
        var repaired := (i + plot_id * 7) % 19 == 0
        var slant := float((i * 5 + plot_id) % 7 - 3) * 0.006
        var basis := Basis(Vector3.FORWARD, slant)
        if repaired:
            basis = basis.scaled(Vector3(1.0, 0.82, 1.0))
        posts.set_instance_transform(i, Transform3D(basis, Vector3(along, base - origin_y + 0.76, 0)))
    var boards := MultiMeshInstance3D.new()
    boards.name = "FadedPickets"
    boards.multimesh = posts
    section.add_child(boards)
    for y in [0.55, 1.16]:
        var rail := MeshInstance3D.new()
        rail.name = "HorizontalRail"
        var rail_box := BoxMesh.new()
        rail_box.size = Vector3(length + 0.15, 0.11, 0.11)
        rail_box.material = mat
        rail.mesh = rail_box
        rail.position.y = y
        section.add_child(rail)
    var obstacle := CollisionShape3D.new()
    obstacle.name = "FenceLineCollision"
    obstacle.position.y = 0.76
    var solid := BoxShape3D.new()
    solid.size = Vector3(length, 1.51, 0.17)
    obstacle.shape = solid
    section.add_child(obstacle)
    fence_sections += 1


func _gate_post(parent: Node3D, x: float, z: float, mat: Material, side: String) -> void:
    var post := StaticBody3D.new()
    post.position = Vector3(x, land.surface_height_at(x, z), z)
    post.name = "OpenGatePost" + side
    var box := BoxMesh.new()
    box.size = Vector3(0.18, 1.85, 0.18)
    box.material = mat
    var view := MeshInstance3D.new()
    view.mesh = box
    view.position.y = 0.92
    post.add_child(view)
    var collision := CollisionShape3D.new()
    collision.position.y = 0.92
    var shape := BoxShape3D.new()
    shape.size = Vector3(0.18, 1.85, 0.18)
    collision.shape = shape
    post.add_child(collision)
    parent.add_child(post)


func _footpath(parent: Node3D, label: String, a: Vector2, b: Vector2, width: float) -> void:
    var distance := a.distance_to(b)
    var chunks := maxi(2, int(ceil(distance / 2.0)))
    var sideways := Vector2(-(b - a).normalized().y, (b - a).normalized().x)
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    st.set_material(GROUND_MATERIAL)
    for i in range(chunks):
        var u := float(i) / float(chunks)
        var v := float(i + 1) / float(chunks)
        var pa := a.lerp(b, u)
        var pb := a.lerp(b, v)
        var a_left := _foot_vertex(pa - sideways * width * 0.5)
        var a_right := _foot_vertex(pa + sideways * width * 0.5)
        var b_left := _foot_vertex(pb - sideways * width * 0.5)
        var b_right := _foot_vertex(pb + sideways * width * 0.5)
        for point in [a_left, b_left, a_right, a_right, b_left, b_right]:
            st.set_uv(Vector2(point.x / 4.0, point.z / 4.0))
            st.add_vertex(point)
    st.generate_normals()
    var walk := MeshInstance3D.new()
    walk.name = label
    walk.mesh = st.commit()
    walk.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    parent.add_child(walk)


func _foot_vertex(at: Vector2) -> Vector3:
    return Vector3(at.x, land.surface_height_at(at.x, at.y) + 0.028, at.y)


func _yard_life(parent: Node3D, site: Dictionary, index: int) -> void:
    var x := float(site["x"])
    var z := float(site["z"])
    var side := float(site["side"])
    var group: Array = YARD_GROUPS[index]
    for i in range(group.size()):
        var item: String = group[i]
        var back: float = [10.0, 17.0, 12.5, 20.0, -9.0, -12.0][i]
        var across: float = [-10.0, 8.5, 11.5, -7.0, -11.0, 11.0][i]
        var target_x := x + side * back
        var target_z := z + across
        var asset := _place(parent, item, target_x, target_z,
            float(i) * 0.41 + float(index) * 0.17, 0.9 + 0.05 * float(i % 3), true)
        if asset != null:
            garden_props += 1
    # One personal object by the gate; deliberately offset from the path.
    if _place(parent, "mail" if index % 3 == 0 else "bucket",
        float(site["side"]) * 23.0, z + 4.3, 0.3, 1.0, true) != null:
        garden_props += 1


func _garden_beds(parent: Node3D, site: Dictionary) -> void:
    var x := float(site["x"]) + float(site["side"]) * 13.5
    var z := float(site["z"])
    for row in range(3):
        var bed_z := z - 6.8 + float(row) * 3.2
        var mesh := MeshInstance3D.new()
        mesh.name = "TendedThenAbandonedBed"
        var shape := BoxMesh.new()
        shape.size = Vector3(5.6, 0.045, 0.89)
        shape.material = garden_soil
        mesh.mesh = shape
        mesh.position = Vector3(x, land.surface_height_at(x, bed_z) + 0.025, bed_z)
        mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        parent.add_child(mesh)
        for i in range(3):
            var plant_x := x - 1.8 + float(i) * 1.8
            if _place(parent, "grass" if (row + i) % 3 else "shrub",
                plant_x, bed_z, float(row + i), 0.75, false) != null:
                garden_props += 1


func _yard_trees(parent: Node3D, site: Dictionary, index: int) -> void:
    var x := float(site["x"]) + float(site["side"]) * 19.0
    var z := float(site["z"])
    for i in range(2):
        var px := x + float(site["side"]) * (float(i) * 2.0)
        var pz := z + (-12.0 if i == 0 else 12.0)
        if _place(parent, "bare" if (i + index) % 3 else "pine",
            px, pz, rng.randf_range(-3.14, 3.14), rng.randf_range(0.84, 1.12), true) != null:
            trees_placed += 1


func _country_vegetation(parent: Node3D) -> void:
    # Vegetation should cluster into a tree belt, field edges and neglected
    # hedges. Do not seed the road, a path or a house threshold with bushes.
    for i in range(152):
        var x := rng.randf_range(-173.0, 173.0)
        var z := rng.randf_range(-202.0, 202.0)
        if land.is_thoroughfare(x, z, 3.5):
            continue
        var too_close := false
        for site in PROFILE.HOMES:
            var d := Vector2(x - float(site["x"]), z - float(site["z"])).length()
            if d < 17.5:
                too_close = true
                break
        if too_close:
            continue
        var border := absf(x) > 110.0 or absf(z) > 174.0
        if not border and i % 4 != 0:
            continue
        var tree_type := "bare" if i % 4 == 0 else "pine"
        if _place(parent, tree_type, x, z, rng.randf_range(-3.14, 3.14),
            rng.randf_range(0.8, 1.4), true) != null:
            trees_placed += 1
    for i in range(580):
        var x := rng.randf_range(-172.0, 172.0)
        var z := rng.randf_range(-203.0, 203.0)
        if land.is_thoroughfare(x, z, 1.8):
            continue
        var near_house := false
        for site in PROFILE.HOMES:
            if Vector2(x - float(site["x"]), z - float(site["z"])).length() < 10.5:
                near_house = true
                break
        if near_house:
            continue
        var id: String = ["grass", "grass", "bramble", "shrub", "fern", "branch", "grass", "stump"][i % 8]
        if _place(parent, id, x, z, rng.randf_range(-3.14, 3.14),
            rng.randf_range(0.65, 1.35), id == "stump") != null:
            undergrowth_placed += 1


func _roadside_stories(parent: Node3D) -> void:
    # Already-authored pieces only. A hamlet has forgotten work, deliveries,
    # repairs, weather and ordinary family routines—not game pickups.
    var extras := [
        ["shelter", 16.5, 180.0, -1.2],
        ["guardrail", -9.0, 175.5, 1.6],
        ["culvert", -11.0, 48.0, 1.57],
        ["sheet", 14.0, -115.0, 0.28],
        ["tyres", 12.5, -107.0, 0.9],
        ["wood", -11.8, -173.0, 0.45],
        ["logs", -17.0, 178.0, 0.32],
        ["branch", 11.0, -180.0, -0.5]
    ]
    for item in extras:
        if _place(parent, str(item[0]), float(item[1]), float(item[2]),
            float(item[3]), 1.0, true) != null:
            garden_props += 1


func _power_line(parent: Node3D) -> void:
    # Ordinary timber utility poles and slack old wiring made from basic
    # geometry; no new standalone props or exterior asset downloads.
    var poles: Array[Vector3] = []
    for i in range(8):
        var z := -177.0 + float(i) * 50.0
        var x := land.main_road_x(z) + 11.3
        var bottom := Vector3(x, land.surface_height_at(x, z), z)
        _pole(parent, bottom)
        poles.append(bottom)
    for i in range(poles.size() - 1):
        var from: Vector3 = poles[i]
        var to: Vector3 = poles[i + 1]
        for lateral in [-0.24, 0.24]:
            for segment in range(8):
                var u := float(segment) / 8.0
                var v := float(segment + 1) / 8.0
                _cable(parent,
                    from.lerp(to, u) + Vector3(lateral, 6.25 - 0.32 * sin(u * PI), 0),
                    from.lerp(to, v) + Vector3(lateral, 6.25 - 0.32 * sin(v * PI), 0))
    utility_poles = poles.size()


func _pole(parent: Node3D, base: Vector3) -> void:
    var body := StaticBody3D.new()
    body.name = "TimberUtilityPole"
    body.position = base
    var shaft := CylinderMesh.new()
    shaft.top_radius = 0.085
    shaft.bottom_radius = 0.14
    shaft.height = 6.45
    shaft.radial_segments = 8
    shaft.material = pole_wood
    var visual := MeshInstance3D.new()
    visual.mesh = shaft
    visual.position.y = 3.225
    body.add_child(visual)
    var collision := CollisionShape3D.new()
    var hit := CylinderShape3D.new()
    hit.height = 6.45
    hit.radius = 0.14
    collision.shape = hit
    collision.position.y = 3.225
    body.add_child(collision)
    var crosspiece := BoxMesh.new()
    crosspiece.size = Vector3(0.8, 0.12, 0.13)
    crosspiece.material = pole_wood
    var arm := MeshInstance3D.new()
    arm.mesh = crosspiece
    arm.position.y = 6.18
    body.add_child(arm)
    parent.add_child(body)


func _cable(parent: Node3D, a: Vector3, b: Vector3) -> void:
    var visual := MeshInstance3D.new()
    visual.name = "OverheadWire"
    var rod := CylinderMesh.new()
    rod.top_radius = 0.009
    rod.bottom_radius = 0.009
    rod.height = a.distance_to(b)
    rod.radial_segments = 5
    rod.material = wire_mat
    visual.mesh = rod
    visual.position = (a + b) * 0.5
    visual.quaternion = Quaternion(Vector3.UP, (b - a).normalized())
    visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    parent.add_child(visual)
