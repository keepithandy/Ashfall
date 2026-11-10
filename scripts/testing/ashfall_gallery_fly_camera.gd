## Isolated first-person fly camera for Ashfall's editor-only asset showroom.
## No gameplay dependencies. ESC releases the mouse, left-click captures it again.
extends Camera3D

@export var move_speed: float = 13.0
@export var sprint_multiplier: float = 3.0
@export var mouse_sensitivity: float = 0.002

func _ready() -> void:
    current = true
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
        get_viewport().set_input_as_handled()
        return

    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
            Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
            get_viewport().set_input_as_handled()
        return

    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        rotation.y -= event.relative.x * mouse_sensitivity
        rotation.x = clampf(rotation.x - event.relative.y * mouse_sensitivity, -1.48, 1.48)
        get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
    var movement := Vector3.ZERO
    if Input.is_physical_key_pressed(KEY_W):
        movement -= global_transform.basis.z
    if Input.is_physical_key_pressed(KEY_S):
        movement += global_transform.basis.z
    if Input.is_physical_key_pressed(KEY_A):
        movement -= global_transform.basis.x
    if Input.is_physical_key_pressed(KEY_D):
        movement += global_transform.basis.x
    if Input.is_physical_key_pressed(KEY_E):
        movement += Vector3.UP
    if Input.is_physical_key_pressed(KEY_Q):
        movement += Vector3.DOWN
    if movement.length_squared() > 0.0:
        var speed := move_speed
        if Input.is_key_pressed(KEY_SHIFT):
            speed *= sprint_multiplier
        global_position += movement.normalized() * speed * delta

func _exit_tree() -> void:
    if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
