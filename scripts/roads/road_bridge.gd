@tool
extends Node3D
## Modular steel-railed service bridge; local X is its longitudinal axis.
## Intended for the blockout river crossing. Full bridge physics is included.
const DECK_MATERIAL = preload("res://assets/roads/worn_road.tres")
const RUST_MATERIAL = preload("res://assets/props/rust.tres")

@export_range(18.0, 220.0, 1.0) var span_length := 148.0:
    set(value):
        span_length = value
        _rebuild()

@export_range(5.0, 14.0, 0.5) var deck_width := 8.0:
    set(value):
        deck_width = value
        _rebuild()

func _ready() -> void:
    _rebuild()

func _mesh(parent: Node3D, name: String, size: Vector3, at: Vector3, mat: Material) -> void:
    var mesh := BoxMesh.new()
    mesh.size = size
    var visual := MeshInstance3D.new()
    visual.name = name
    visual.mesh = mesh
    visual.material_override = mat
    visual.position = at
    visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
    if parent == self:
        visual.set_meta("ashfall_generated_bridge", true)
    parent.add_child(visual)

func _rebuild() -> void:
    if not is_inside_tree():
        return
    for child in get_children():
        if child.get_meta("ashfall_generated_bridge", false):
            child.free()

    var deck_body := StaticBody3D.new()
    deck_body.name = "BridgeDeckAndCollision"
    deck_body.set_meta("ashfall_generated_bridge", true)
    add_child(deck_body)

    # Deck top is y=0.045, close to the adjoining 0.036 m road surface.
    _mesh(deck_body, "WornRoadDeck",
        Vector3(span_length, 0.22, deck_width), Vector3(0, -0.065, 0), DECK_MATERIAL)
    var shape := BoxShape3D.new()
    shape.size = Vector3(span_length, 0.22, deck_width)
    var collision := CollisionShape3D.new()
    collision.name = "DeckCollision"
    collision.shape = shape
    collision.position.y = -0.065
    deck_body.add_child(collision)

    for side in [-1.0, 1.0]:
        var z := side * (deck_width * 0.5 - 0.18)
        _mesh(self, "Guardrail_%s" % str(side),
            Vector3(span_length - 0.5, 0.12, 0.16), Vector3(0, 0.91, z), RUST_MATERIAL)
        _mesh(self, "MiddleRail_%s" % str(side),
            Vector3(span_length - 0.5, 0.09, 0.12), Vector3(0, 0.50, z), RUST_MATERIAL)
        var count := maxi(2, int(span_length / 9.0))
        for i in range(count + 1):
            var x := -span_length * 0.5 + (span_length * float(i) / float(count))
            _mesh(self, "RailPost_%s_%02d" % [str(side), i],
                Vector3(0.13, 1.08, 0.14), Vector3(x, 0.51, z), RUST_MATERIAL)
