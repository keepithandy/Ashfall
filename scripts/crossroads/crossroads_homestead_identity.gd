@tool
extends Node3D
## Crossroads Phase 1: a dozen hand-curated traces of ordinary life.
## Decorative ONLY: no items to collect, no objective text, no AI, no extra
## physical obstacles across gates, front thresholds or narrow interiors.
## Reuses existing authored assets. The older homestead geometry is unchanged.

const PROFILE = preload("res://scripts/crossroads/crossroads_profile.gd")
const EARTH_ALBEDO = preload("res://assets/materials/forest_ground_05/albedo.jpg")
const ASSETS := {
    "bench": "res://scenes/props/wooden_bench.tscn",
    "chair": "res://scenes/decorative_world/sagging_porch_chair.tscn",
    "table": "res://scenes/decorative_world/rotting_picnic_table.tscn",
    "wood": "res://scenes/extra_dressing/firewood_stack.tscn",
    "sawhorse": "res://scenes/extra_dressing/wood_sawhorse.tscn",
    "shovel": "res://scenes/extra_dressing/garden_shovel.tscn",
    "pots": "res://scenes/decorative_world/cracked_plant_pots.tscn",
    "washing": "res://scenes/decorative_world/torn_clothesline.tscn",
    "barrow": "res://scenes/workshop/wheelbarrow.tscn",
    "bucket": "res://scenes/props/metal_bucket.tscn",
    "crate": "res://scenes/workshop/open_wood_crate.tscn",
    "tyres": "res://scenes/decorative_world/discarded_tire_pile.tscn",
    "sheet": "res://scenes/decorative_world/corroded_sheet_metal_stack.tscn",
    "hose": "res://scenes/workshop/coiled_hose.tscn",
    "workbench": "res://scenes/workshop/workbench_vise.tscn",
    "toolbox": "res://scenes/props/tool_box.tscn",
    "pallet": "res://scenes/props/wooden_pallet.tscn",
    "bramble": "res://scenes/nature/dry_bramble.tscn",
    "shrub": "res://scenes/nature/low_shrub.tscn",
    "grass": "res://scenes/extra_dressing/dry_grass_tuft.tscn",
    "stump": "res://scenes/nature/tree_stump.tscn",
    "roots": "res://scenes/crossroads_props/exposed_roots.tscn",
    "stone": "res://scenes/extra_dressing/stone_scatter.tscn",
    "branch": "res://scenes/nature/dead_branch_pile.tscn",
    "mug": "res://scenes/props/enamel_mug.tscn",
    "kettle": "res://scenes/decorative_interiors/rusted_enamel_kettle.tscn",
    "crockery": "res://scenes/decorative_interiors/broken_crockery_scatter.tscn",
    "boxes": "res://scenes/decorative_interiors/dusty_cardboard_box_stack.tscn",
    "rug": "res://scenes/decorative_interiors/threadbare_area_rug.tscn",
    "scrap": "res://scenes/extra_dressing/scrap_sheet.tscn"
}

# All offsets are explicit authored local plot coordinates:
# [asset, meters toward back (+) or street (-), meters along street, yaw,
#  scale]. No repeated random placement lists. z=0 is the main gate walkline.
const PORTRAITS := [
    {"title":"The family home", "story":"The last meal was never cleared away",
     "yard":[["bench",-15.0,-8.0,0.3,0.96],["pots",-11.4,8.0,0.6,1.0],["wood",21.0,7.5,1.0,0.92],["barrow",25.5,-8.0,0.6,0.9],["grass",-11.0,-12.0,0.4,1.0]],
     "room":["kettle","mug","crockery"], "landmark":true},
    {"title":"The blue sill", "story":"Gardening continued after the rest of the street fell silent",
     "yard":[["pots",-13.0,8.5,0.5,1.0],["shovel",-11.0,-8.0,0.2,0.9],["bench",18.0,12.0,1.6,0.95],["crate",24.0,-8.0,0.8,0.9],["grass",25.0,11.0,0.0,1.15]],
     "room":["mug","rug","boxes"], "landmark":false},
    {"title":"The woodcutter's house", "story":"Tools and stacked fuel beside an empty chair",
     "yard":[["sawhorse",-14.0,8.5,1.2,0.95],["wood",20.0,-7.0,1.2,1.0],["shovel",-11.0,-8.0,0.7,0.9],["stump",23.0,10.5,1.0,0.85],["chair",-16.0,-11.0,0.2,0.94]],
     "room":["boxes","toolbox","mug"], "landmark":false},
    {"title":"The orchard residence", "story":"Neglected garden equipment and old planting pots",
     "yard":[["pots",-14.5,-9.0,1.2,1.0],["barrow",22.0,8.0,0.5,0.92],["bucket",-11.0,8.0,0.8,1.0],["stone",24.0,-9.0,0.4,0.95],["shrub",20.0,12.5,0.0,1.15]],
     "room":["kettle","mug","rug"], "landmark":false},
    {"title":"The repair courtyard", "story":"A vehicle or farm machine was being stripped for parts",
     "yard":[["workbench",22.0,-8.0,1.0,1.0],["tyres",25.0,9.0,0.7,0.98],["hose",19.0,12.0,0.3,0.9],["sawhorse",-15.0,-8.0,0.4,1.0],["crate",-13.0,8.0,1.0,0.95],["pallet",24.0,-12.5,1.0,0.92],["toolbox",19.0,-11.5,0.1,0.92]],
     "room":["toolbox","boxes","mug"], "landmark":true},
    {"title":"The water yard", "story":"A family kept buckets and washing tools near the house",
     "yard":[["bucket",-15.0,-8.0,0.1,1.0],["washing",22.0,11.0,0.3,0.92],["barrow",19.0,-10.0,0.8,0.9],["pots",-12.0,8.5,0.4,0.9],["wood",25.0,-8.5,0.1,1.05]],
     "room":["mug","kettle","boxes"], "landmark":false},
    {"title":"The laundry house", "story":"Worn-out clothes were left in a wet yard",
     "yard":[["washing",20.0,9.0,0.1,0.94],["bucket",-13.0,-8.0,0.5,0.95],["chair",-15.0,8.0,0.4,1.0],["pots",23.0,-8.5,1.1,0.9],["branch",26.0,11.2,0.2,1.05]],
     "room":["crockery","mug","rug"], "landmark":false},
    {"title":"The vegetable plot", "story":"A carefully kept bed has gone to seed",
     "yard":[["shovel",-14.0,8.0,0.4,1.0],["barrow",24.0,-7.5,1.0,0.86],["bucket",-11.0,-9.0,0.0,0.95],["pots",21.0,12.0,0.9,0.95],["shrub",26.0,7.0,0.2,1.0]],
     "room":["kettle","boxes","mug"], "landmark":false},
    {"title":"The overgrown home", "story":"Nature is claiming this plot before the others",
     "yard":[["bramble",-12.0,-8.0,0.4,1.34],["bramble",-13.0,9.0,0.1,1.2],["shrub",20.0,-11.0,0.5,1.6],["roots",24.0,10.0,1.2,1.05],["branch",25.0,-8.0,0.5,1.15],["grass",18.0,12.0,0.2,1.45],["stump",27.0,-6.8,0.1,0.98]],
     "room":["crockery","boxes","rug"], "landmark":true},
    {"title":"The former equipment store", "story":"Household storage mixed with agricultural repair",
     "yard":[["sheet",22.0,-10.0,1.0,0.9],["pallet",23.0,9.0,1.2,0.96],["toolbox",-13.0,-8.0,0.2,0.95],["wood",26.0,-8.5,0.8,0.95],["hose",-11.5,8.0,0.7,0.9]],
     "room":["toolbox","boxes","crockery"], "landmark":false},
    {"title":"The last maintained cottage", "story":"A bench has survived in the garden",
     "yard":[["bench",-14.5,8.0,0.1,0.96],["pots",-12.0,-8.0,0.4,1.0],["shovel",24.0,-10.0,0.8,0.9],["crate",23.0,8.0,1.3,0.85],["grass",19.0,12.0,0.4,0.85]],
     "room":["mug","rug","kettle"], "landmark":false},
    {"title":"The northern woodpile", "story":"Firewood and repairs at the last occupied house",
     "yard":[["wood",22.0,-9.0,0.7,1.1],["sawhorse",-12.5,8.0,0.9,0.9],["bucket",-14.0,-8.0,0.8,0.93],["chair",19.0,11.0,1.2,0.95],["crate",26.0,7.0,0.0,0.9]],
     "room":["kettle","mug","boxes"], "landmark":false}
]

var plot_data: Dictionary = {}
var ordinal := -1
var residence: Node3D
var land: RefCounted
var cached_assets: Dictionary = {}
var outdoor_count := 0
var interior_count := 0
var verge_count := 0
var doorway_clearance := 2.1
var wear_segment_count := 0
var surface_placed_count := 0
var floor_placed_count := 0


func configure(site: Dictionary, index: int, home: Node3D, profile: RefCounted) -> void:
    plot_data = site.duplicate(true)
    ordinal = index
    residence = home
    land = profile


func _ready() -> void:
    if ordinal < 0 or plot_data.is_empty() or land == null:
        return
    _decorate()


func _source(kind: String) -> PackedScene:
    if not cached_assets.has(kind):
        cached_assets[kind] = load(str(ASSETS[kind])) as PackedScene
    return cached_assets[kind] as PackedScene


func _ground(x: float, z: float) -> float:
    return float(land.call("surface_height_at", x, z))


func _visual_only(node: Node3D) -> void:
    if node is CollisionObject3D:
        node.collision_layer = 0
        node.collision_mask = 0
    for child in node.find_children("*", "CollisionObject3D", true, false):
        var body := child as CollisionObject3D
        body.collision_layer = 0
        body.collision_mask = 0


func _instantiate(parent: Node3D, kind: String, name: String, position: Vector3, yaw: float, scale_factor: float) -> bool:
    var packed := _source(kind)
    if packed == null:
        push_error("Crossroads Phase 1: missing existing asset " + str(ASSETS[kind]))
        return false
    var prop := packed.instantiate() as Node3D
    if prop == null:
        return false
    prop.name = name
    prop.position = position
    prop.rotation.y = yaw
    prop.scale = Vector3.ONE * scale_factor
    parent.add_child(prop)
    _visual_only(prop)
    return true


func _decorate() -> void:
    var portrait: Dictionary = PORTRAITS[ordinal]
    set_meta("property_title", portrait["title"])
    set_meta("property_story", portrait["story"])
    set_meta("recognizable_landmark", bool(portrait["landmark"]))
    name = "HomesteadIdentity"
    var courtyard := Node3D.new()
    courtyard.name = "PersonalCourtyard"
    add_child(courtyard)
    var interior := Node3D.new()
    interior.name = "RoomTraces"
    residence.add_child(interior)
    var verge := Node3D.new()
    verge.name = "StreetVerge"
    add_child(verge)
    var site_x := float(plot_data["x"])
    var site_z := float(plot_data["z"])
    var side := float(plot_data["side"])
    for i in range(portrait["yard"].size()):
        var entry: Array = portrait["yard"][i]
        var kind: String = str(entry[0])
        var x := site_x + side * float(entry[1])
        var z := site_z + float(entry[2])
        # The centreline to the front door is reserved, not cluttered.
        if absf(z - site_z) < doorway_clearance:
            push_error("Crossroads Phase 1: yard prop in gate path at " + str(plot_data["name"]))
            continue
        if _instantiate(courtyard, kind, "DailyTrace_%02d_%s" % [i, kind],
            Vector3(x, _ground(x, z), z), float(entry[3]), float(entry[4])):
            outdoor_count += 1
    _interior_details(interior, portrait, str(plot_data["kind"]))
    _service_wear()
    # A little maintained / neglected roadside growth on both sides of the
    # open gate. Never on the 5.8m asphalt, in the throat, or on the curb.
    var street_x := float(land.call("main_road_x", site_z))
    for i in range(3):
        var z := site_z + (-11.2 if i == 0 else (11.4 if i == 1 else 14.0))
        var x := street_x + side * (7.1 + float(i % 2) * 0.9)
        var kind := "grass" if i == 0 else ("shrub" if i == 1 else "stone")
        if _instantiate(verge, kind, "VergeTrace_%d_%s" % [i, kind],
            Vector3(x, _ground(x, z), z), float(i) * 0.57, 0.72 + float(i) * 0.13):
            verge_count += 1


func _interior_details(parent: Node3D, portrait: Dictionary, house_kind: String) -> void:
    # A real floorplan audit exposed a serious error in the first pass:
    # the old prefab rooms are CENTERED about z=0, while some traces had
    # been placed at z=depth-1.3 (outside the house). Also cups and kettles
    # were standing directly on floorboards. Keep floor clutter near the
    # existing walls and put small household objects onto existing furniture.
    var half_width := 4.0
    var half_depth := 4.0
    match house_kind:
        "white":
            half_width = 4.3
            half_depth = 5.0
        "green":
            half_width = 5.9
            half_depth = 3.5
        "ochre":
            half_width = 4.0
            half_depth = 4.0
        "blue_sill":
            half_width = 6.0
            half_depth = 4.0
        "lane_brick":
            half_width = 4.0
            half_depth = 6.0
    var old_house := house_kind in ["white", "green", "ochre"]
    var support: Node3D = null
    if old_house:
        support = residence.get_node_or_null("WoodenBench") as Node3D
    else:
        support = residence.get_node_or_null("BuiltHouse/LivingSpaces/Table2") as Node3D
    if support == null:
        push_error("Crossroads Phase 1: missing existing household support in " + str(plot_data["name"]))
        return

    var small_objects := 0
    for i in range(portrait["room"].size()):
        var item := str(portrait["room"][i])
        var location := Vector3.ZERO
        if item == "mug" or item == "kettle":
            # Bench seating and dining table heights come from the shipped
            # assets: wooden bench = 0.46m; dining table = 0.93m.
            var surface_y := 0.46 if old_house else 0.93
            location = Vector3(
                support.position.x + (-0.42 if small_objects % 2 == 0 else 0.42),
                support.position.y + surface_y + 0.015,
                support.position.z + (-0.045 if small_objects % 2 == 0 else 0.06)
            )
            small_objects += 1
        elif item == "rug":
            location = Vector3(-0.55, 0.20, -0.35 if old_house else 0.40)
        elif item == "crockery":
            location = Vector3(
                half_width - 1.20, 0.20,
                0.65 if old_house else -half_depth + 1.15
            )
        elif item == "boxes":
            location = Vector3(
                half_width - 1.45 if old_house else -half_width + 1.40,
                0.20, 0.10 if old_house else half_depth - 1.40
            )
        else:
            # Tools are set beside the wall, not in the front-door aisle.
            location = Vector3(-half_width + 1.25, 0.20, 0.10)
        if absf(location.x) >= half_width - 0.15 or absf(location.z) >= half_depth - 0.15:
            push_error("Crossroads Phase 1: interior prop outside actual house footprint")
            continue
        if _instantiate(parent, item, "HouseholdTrace_%d_%s" % [i, item],
            location, float(i) * 0.17 + float(ordinal) * 0.13, 0.90):
            interior_count += 1
            if item in ["mug", "kettle"]:
                surface_placed_count += 1
            else:
                floor_placed_count += 1


func _service_wear() -> void:
    # A house should show decades of daily movement, not three identical
    # perfect garden bars. These irregular, interrupted soil traces lead
    # past one side of each residence to its rear work area. They are purely
    # visual, hugging the same exact triangles as the physical ground.
    # No change to the authored GateToFrontDoor path or garden geometry.
    var mat := StandardMaterial3D.new()
    mat.albedo_texture = EARTH_ALBEDO
    mat.albedo_color = Color(0.41, 0.36, 0.29)
    mat.roughness = 1.0
    mat.uv1_triplanar = true
    mat.uv1_world_triplanar = true
    mat.uv1_scale = Vector3(0.45, 0.45, 0.45)

    var site_x := float(plot_data["x"])
    var site_z := float(plot_data["z"])
    var side := float(plot_data["side"])
    var history := str(PORTRAITS[ordinal]["title"])
    var use_side_z := -8.8 if (ordinal % 2 == 0) else 9.1
    var paths := 2 if bool(PORTRAITS[ordinal]["landmark"]) else 1
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    st.set_material(mat)
    for path_index in range(paths):
        var z_center := site_z + (use_side_z if path_index == 0 else -use_side_z)
        for section in range(8):
            # Missing patches: old grass has grown back through the middle.
            if (section + ordinal + path_index * 2) % 6 == 0:
                continue
            var from_back := 7.0 + float(section) * 1.75
            var to_back := from_back + 1.64
            var x0 := site_x + side * from_back
            var x1 := site_x + side * to_back
            var wobble0 := sin(float(section) * 1.37 + float(ordinal)) * 0.18
            var wobble1 := sin(float(section + 1) * 1.37 + float(ordinal)) * 0.18
            var center0 := z_center + wobble0
            var center1 := z_center + wobble1
            var half0 := 0.23 + float((section + ordinal) % 3) * 0.065
            var half1 := 0.23 + float((section + ordinal + 1) % 3) * 0.065
            var a := _wear_vertex(x0, center0 - half0)
            var b := _wear_vertex(x1, center1 - half1)
            var p := _wear_vertex(x0, center0 + half0)
            var d := _wear_vertex(x1, center1 + half1)
            # The west/east house sides face opposite ways in world X.
            var triangles := [a, b, p, b, d, p] if side > 0.0 else [a, p, b, b, p, d]
            for vertex in triangles:
                st.set_uv(Vector2(vertex.x / 3.5, vertex.z / 3.5))
                st.add_vertex(vertex)
            wear_segment_count += 1
    if wear_segment_count == 0:
        return
    st.generate_normals()
    var trace := MeshInstance3D.new()
    trace.name = "InterruptedWorkyardTracks"
    trace.mesh = st.commit()
    trace.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    trace.set_meta("property_history", history)
    add_child(trace)


func _wear_vertex(x: float, z: float) -> Vector3:
    return Vector3(x, _ground(x, z) + 0.041, z)
