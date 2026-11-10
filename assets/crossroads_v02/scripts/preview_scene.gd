## Only for the isolated v0.2 preview. Press Space to toggle the door.
extends Node3D

@onready var door: AshfallSteelDoor = $Door/DoorHinge

func _ready() -> void:
    print("Crossroads v0.2 preview: Press SPACE to operate the door.")

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
        door.interact()
