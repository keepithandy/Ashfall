## Ashfall modular steel door controller (Godot 4.x).
## Attach to an AnimatableBody3D whose local origin is the door hinge.
## Put the visual mesh AND collision shape under that body, offset toward the latch.
## This script never edits the scene or save schema.
extends AnimatableBody3D
class_name AshfallSteelDoor

signal state_changed(opened: bool)
signal locked_attempt()

@export_range(30.0, 175.0, 1.0) var open_degrees: float = 105.0
@export_range(0.15, 4.0, 0.05) var movement_seconds: float = 0.85
@export var swing_direction: float = -1.0 # set 1 for the opposite swing
@export var starts_open: bool = false
@export var locked: bool = false

var opened: bool = false
var _closed_y: float = 0.0
var _movement: Tween

func _ready() -> void:
    _closed_y = rotation.y
    sync_to_physics = true
    add_to_group("ashfall_interactables")
    opened = starts_open
    if opened:
        rotation.y = _closed_y + deg_to_rad(open_degrees) * sign(swing_direction)

func interact(_actor: Node = null) -> void:
    if locked:
        locked_attempt.emit()
        return
    set_open(not opened)

func set_open(value: bool, instant: bool = false) -> void:
    if opened == value and not instant:
        return
    opened = value
    var target_y: float = _closed_y
    if opened:
        target_y += deg_to_rad(open_degrees) * sign(swing_direction)
    if _movement and _movement.is_running():
        _movement.kill()
    if instant:
        rotation.y = target_y
    else:
        _movement = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
        _movement.tween_property(self, "rotation:y", target_y, movement_seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    state_changed.emit(opened)
