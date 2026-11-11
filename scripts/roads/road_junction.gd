@tool
extends Node3D
## Reusable low-profile road junction cap. Rotate the prefab for T direction.
const ROAD_MATERIAL = preload("res://assets/roads/worn_road.tres")

@export_enum("T junction", "Crossroads") var junction_type := 0:
    set(value):
        junction_type = value
        _rebuild()
@export_range(3.0, 11.0, 0.25) var road_width := 5.8:
    set(value):
        road_width = value
        _rebuild()

func _ready() -> void:
    _rebuild()

func _piece(name: String, size: Vector3, position_local: Vector3) -> void:
    var visual := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = size
    visual.name = name
    visual.mesh = box
    visual.material_override = ROAD_MATERIAL
    visual.position = position_local
    visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    visual.set_meta("ashfall_generated_junction", true)
    add_child(visual)

func _rebuild() -> void:
    if not is_inside_tree():
        return
    for child in get_children():
        if child.get_meta("ashfall_generated_junction", false):
            child.free()
    # Low-profile pieces sit flush with strips and the y=0 underlying terrain.
    var thickness := 0.045
    _piece("JunctionCentre", Vector3(road_width + 0.8, thickness, road_width + 0.8), Vector3(0, 0.016, 0))
    var reach := 4.2
    _piece("LeftApproach", Vector3(reach, thickness, road_width), Vector3(-road_width * 0.5 - reach * 0.5, 0.017, 0))
    _piece("RightApproach", Vector3(reach, thickness, road_width), Vector3(road_width * 0.5 + reach * 0.5, 0.017, 0))
    _piece("SouthApproach", Vector3(road_width, thickness, reach), Vector3(0, 0.017, road_width * 0.5 + reach * 0.5))
    if junction_type == 1:
        _piece("NorthApproach", Vector3(road_width, thickness, reach), Vector3(0, 0.017, -road_width * 0.5 - reach * 0.5))
