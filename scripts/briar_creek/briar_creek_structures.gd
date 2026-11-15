@tool
extends Node3D
## Area 02 layout shells. They establish real doors, rooms, structure collision
## and industrial working relationships; production art/detail still required.
const PROFILE = preload("res://scripts/briar_creek/briar_creek_profile.gd")
var profile=PROFILE.new()
var buildings_created := 0
var props_placed := 0

func _ready() -> void:
    build()

func _mat(color: Color) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color=color
    m.roughness=0.96
    return m

func _solid(body: StaticBody3D, label: String, pos: Vector3, size: Vector3, material: Material, angle: float = 0.0) -> void:
    var mesh := BoxMesh.new()
    mesh.size=size
    mesh.material=material
    var visual := MeshInstance3D.new()
    visual.name=label
    visual.mesh=mesh
    visual.position=pos
    visual.rotation.z=angle
    body.add_child(visual)
    var hit := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size=size
    hit.shape=shape
    hit.position=pos
    hit.rotation.z=angle
    body.add_child(hit)

func _new_building(parent: Node3D, label: String, x: float, north: float, y: float) -> StaticBody3D:
    var body := StaticBody3D.new()
    body.name=label
    # Anchor structures to the actual collision-matched terrain instead
    # of assuming their intended pad elevation is exact at every coordinate.
    var anchor := profile.to_world(x,north)
    anchor.y=profile.surface_height_at(anchor.x,anchor.z)+0.035
    body.position=anchor
    body.set_meta("design_elevation_target",y)
    body.collision_layer=1
    body.collision_mask=0
    parent.add_child(body)
    buildings_created+=1
    return body

func _shell(parent: Node3D, label: String, x: float, north: float, y: float, width: float, depth: float, wall_height: float, door_width: float, walls: Material, roof: Material) -> StaticBody3D:
    var body := _new_building(parent,label,x,north,y)
    var thickness := 0.24
    _solid(body,"Floor",Vector3(0,0.05,0),Vector3(width,0.16,depth),walls)
    _solid(body,"RearWall",Vector3(0,wall_height*0.5,depth*0.5),Vector3(width,wall_height,thickness),walls)
    _solid(body,"LeftWall",Vector3(-width*0.5,wall_height*0.5,0),Vector3(thickness,wall_height,depth),walls)
    _solid(body,"RightWall",Vector3(width*0.5,wall_height*0.5,0),Vector3(thickness,wall_height,depth),walls)
    if door_width < width:
        var segment := (width-door_width)*0.5
        _solid(body,"FrontWallL",Vector3(-(door_width+segment)*0.5,wall_height*0.5,-depth*0.5),Vector3(segment,wall_height,thickness),walls)
        _solid(body,"FrontWallR",Vector3((door_width+segment)*0.5,wall_height*0.5,-depth*0.5),Vector3(segment,wall_height,thickness),walls)
    var rise := minf(1.6,width*0.20)
    var slope := atan2(rise,width*0.5)
    var rlength := sqrt(pow(width*0.5,2)+pow(rise,2))+0.9
    _solid(body,"RoofWest",Vector3(-width*0.25,wall_height+rise*0.5,0),Vector3(rlength,0.17,depth+1.1),roof,slope)
    _solid(body,"RoofEast",Vector3(width*0.25,wall_height+rise*0.5,0),Vector3(rlength,0.17,depth+1.1),roof,-slope)
    return body

func _shed(parent: Node3D, label: String, x: float, north: float, y: float, width: float, depth: float, wood: Material, metal: Material) -> void:
    var body := _new_building(parent,label,x,north,y)
    _solid(body,"GroundSlab",Vector3(0,0.04,0),Vector3(width,0.14,depth),wood)
    for sx in [-1.0,1.0]:
        for sz in [-1.0,1.0]:
            _solid(body,"Support",Vector3(sx*(width*0.5-0.3),2.0,sz*(depth*0.5-0.3)),Vector3(0.27,4.0,0.27),wood)
    _solid(body,"SlopedSheetRoof",Vector3(0,4.2,0),Vector3(width+1.0,0.2,depth+1.1),metal,-0.045)

func _stack(parent: Node3D, x: float, north: float, y: float, wood: Material) -> void:
    var body := _new_building(parent,"BundledTimber",x,north,y)
    for j in range(3):
        _solid(body,"Stack_%02d" % j,Vector3(0,0.35+j*0.55,0),Vector3(6.5,0.47,1.6),wood)

func build() -> void:
    if has_node("GeneratedDistrict"):
        return
    var root := Node3D.new()
    root.name="GeneratedDistrict"
    add_child(root)
    var wood := _mat(Color(0.31,0.245,0.185))
    var pale := _mat(Color(0.43,0.41,0.34))
    var steel := _mat(Color(0.29,0.30,0.30))
    var rust := _mat(Color(0.38,0.235,0.18))
    buildings_created=0
    # Mill production logic: incoming log yard to west, saw hall centrally,
    # finished timber in an open-sided covered shelter, office near truck road.
    _shell(root,"MainSawmill",325,320,18,28,14,7.2,7.0,wood,rust)
    _shell(root,"MillOffice",388,292,18,12,8,3.2,1.9,pale,steel)
    _shed(root,"LogSortingShelter",315,334,18,24,10,wood,rust)
    _stack(root,306,302,18,wood)
    _stack(root,314,304,18,wood)
    _stack(root,321,304,18,wood)
    _shed(root,"FinishedTimberShelter",395,270,18,16,9,wood,steel)
    # Worker cabins follow a shared lane; distinct footprints face clearing.
    _shell(root,"WorkerCabinA",125,395,23,8,6,2.9,1.6,wood,steel)
    _shell(root,"WorkerCabinB",155,405,23,8,6,2.9,1.6,pale,steel)
    _shell(root,"WorkerCabinC",130,365,23,8,6,2.9,1.6,wood,rust)
    _shell(root,"WorkerCabinD",170,375,23,8,6,2.9,1.6,pale,rust)
    _shell(root,"MaintenanceWorkshop",450,465,32,16,12,4.0,4.2,wood,rust)
    _shed(root,"EquipmentShelter",500,430,32,18,10,wood,steel)
    _shell(root,"CheckpointBooth",315,72,5,4,4,2.65,1.25,pale,steel)
    # Lookout creates a north-ridge silhouette. Accessible tower stairs are
    # not built yet: the path currently reaches its base, not the platform.
    var tower := _new_building(root,"LookoutTower",335,550,60)
    for dx in [-1.8,1.8]:
        for dz in [-1.8,1.8]:
            _solid(tower,"TowerLeg",Vector3(dx,6.0,dz),Vector3(0.38,12.0,0.38),wood)
    _solid(tower,"ObservationDeck",Vector3(0,12.0,0),Vector3(5.5,0.36,5.5),wood)
    _solid(tower,"ObservationRoof",Vector3(0,15.8,0),Vector3(6.0,0.22,6.0),steel)
    # Source-safe physical dressing: all objects are existing Ashfall scenes.
    # Placement reflects how a small logging yard and service camp would work.
    props_placed=0
    for spec in [
        ["props/wooden_pallet", 337.0,296.0,0.2],
        ["props/wooden_pallet", 341.0,296.0,-0.1],
        ["props/shipping_crate", 376.0,310.0,0.1],
        ["props/cable_spool", 370.0,312.0,1.0],
        ["props/hand_truck", 377.0,327.0,1.2],
        ["props/rusted_drum", 383.0,317.0,0.4],
        ["props/metal_bucket", 330.0,302.0,0.1],
        ["props/tool_box", 331.0,306.0,0.6],
        ["workshop/workbench_vise", 449.0,465.0,0.0],
        ["workshop/discarded_tyre", 480.0,455.0,0.4],
        ["workshop/coiled_hose", 483.0,440.0,0.8],
        ["props/gas_cylinder", 496.0,438.0,0.0],
        ["props/jerrycan", 480.0,442.0,0.2],
        ["props/filing_cabinet", 386.0,291.0,0.0],
        ["props/wooden_bench", 125.0,387.0,1.57],
        ["props/metal_bucket", 152.0,394.0,0.3],
        ["extra_dressing/firewood_stack", 138.0,367.0,0.2],
        ["workshop/wheelbarrow", 181.0,380.0,-0.5],
        ["props/warning_sign", 312.0,67.0,0.1],
        ["props/rusted_drum", 316.0,77.0,0.8],
        ["nature/tree_stump", 221.0,462.0,0.1],
        ["nature/tree_stump", 236.0,442.0,1.0],
        ["nature/fallen_log", 206.0,448.0,0.6],
        ["nature/dead_branch_pile", 218.0,473.0,0.4],
        ["nature/reed_clump", 106.0,260.0,-0.1],
        ["nature/reed_clump", 112.0,238.0,0.7]
    ]:
        _prop(root,str(spec[0]),float(spec[1]),float(spec[2]),float(spec[3]))

func _prop(parent: Node3D, relative: String, x: float, north: float, yaw: float) -> void:
    var packed := load("res://scenes/" + relative + ".tscn") as PackedScene
    if packed == null:
        push_warning("Missing Briar Creek source prop: " + relative)
        return
    var prop := packed.instantiate() as Node3D
    if prop == null:
        push_warning("Briar Creek source prop is not a 3D node: " + relative)
        return
    prop.name=relative.get_file().get_basename() + "_" + str(props_placed)
    var world := profile.to_world(x,north)
    world.y=profile.surface_height_at(world.x,world.z)+0.045
    prop.position=world
    prop.rotation.y=yaw
    parent.add_child(prop)
    props_placed += 1
