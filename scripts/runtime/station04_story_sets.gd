extends Node3D
## Deliberate, restrained traces of occupation rather than random scatter.
## Scenes already in the Ashfall owned asset pack: no outside art downloads.
## The extra pieces are visual-only, leaving mission paths and physics intact.

const TRACES := [
    # The last bus: a shelter with nowhere left to go.
    {"scene": "discarded_tire_pile", "name": "DitchTires", "at": Vector3(59, 0, 39), "yaw": 0.2},
    {"scene": "rotting_picnic_table", "name": "RoadsideTable", "at": Vector3(67, 0, 54), "yaw": 0.5},
    {"scene": "corroded_sheet_metal_stack", "name": "ShelterScrap", "at": Vector3(66, 0, 45), "yaw": -0.25},
    {"scene": "cracked_plant_pots", "name": "ShelterPots", "at": Vector3(60, 0, 58), "yaw": -0.5},
    # After the cottages went quiet, the washing stayed on the line.
    {"scene": "torn_clothesline", "name": "AbandonedWashing", "at": Vector3(-49, 0, 63), "yaw": 0.28},
    {"scene": "sagging_porch_chair", "name": "LastPorchChair", "at": Vector3(-45, 0, 57), "yaw": 2.4},
    {"scene": "cracked_plant_pots", "name": "PorchPots", "at": Vector3(-52, 0, 57), "yaw": 0.8},
    {"scene": "rotting_picnic_table", "name": "RowGardenTable", "at": Vector3(-57, 0, 52), "yaw": -0.6},
    # Maintenance work was interrupted, not tidied away.
    {"scene": "crushed_ventilation_duct", "name": "ServiceDuct", "at": Vector3(55, 0, -20), "yaw": 1.1},
    {"scene": "collapsed_cable_tray", "name": "YardCable", "at": Vector3(56, 0, -29), "yaw": 0.48},
    {"scene": "broken_drainage_culvert", "name": "RoadsideCulvert", "at": Vector3(62, 0, -42), "yaw": 1.57},
    {"scene": "corroded_sheet_metal_stack", "name": "SubstationScrap", "at": Vector3(48, 0, -43), "yaw": 0.2},
    {"scene": "discarded_tire_pile", "name": "FlatTyres", "at": Vector3(62, 0, -54), "yaw": -0.75},
    # Items still at the forest edge. The house has disappeared.
    {"scene": "sagging_porch_chair", "name": "WoodlineChair", "at": Vector3(-64, 0, -55), "yaw": -1.3},
    {"scene": "cracked_plant_pots", "name": "WoodlinePots", "at": Vector3(-58, 0, -56), "yaw": 1.6},
    {"scene": "corroded_sheet_metal_stack", "name": "WoodlineSheeting", "at": Vector3(-71, 0, -63), "yaw": 0.25}
]

var placed_count: int = 0
var placed_positions: Array[Vector3] = []


func _ready() -> void:
    rebuild()


func rebuild() -> void:
    if has_node("StorySets"):
        return
    var anchor := Node3D.new()
    anchor.name = "StorySets"
    add_child(anchor)
    placed_positions.clear()
    placed_count = 0
    for trace in TRACES:
        var path := "res://scenes/decorative_world/" + str(trace["scene"]) + ".tscn"
        var packed := load(path) as PackedScene
        if packed == null:
            push_warning("Missing authored world trace: " + path)
            continue
        var piece := packed.instantiate() as Node3D
        piece.name = str(trace["name"])
        piece.position = trace["at"]
        piece.rotation.y = float(trace["yaw"])
        piece.set_meta("ashfall_environmental_story", true)
        _decoration_only(piece)
        anchor.add_child(piece)
        placed_positions.append(piece.position)
        placed_count += 1


func _decoration_only(piece: Node3D) -> void:
    if piece is CollisionObject3D:
        piece.collision_layer = 0
        piece.collision_mask = 0
    for item in piece.find_children("*", "CollisionObject3D", true, false):
        var body := item as CollisionObject3D
        body.collision_layer = 0
        body.collision_mask = 0
    for item in piece.find_children("*", "GeometryInstance3D", true, false):
        var visual := item as GeometryInstance3D
        visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        visual.visibility_range_end = 155.0
