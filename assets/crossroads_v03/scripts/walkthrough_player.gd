## Isolated inspector for the Crossroads maintenance station (Godot 4.x).
## No Ashfall input mappings, saved games, or existing player scripts are changed.
extends CharacterBody3D

@export_range(1.0, 10.0, 0.1) var move_speed: float = 4.2
@export_range(0.0005, 0.01, 0.0001) var mouse_sensitivity: float = 0.0025
@export_range(1.0, 4.0, 0.1) var interaction_distance: float = 2.8

@onready var _head: Node3D = $Head
@onready var _camera: Camera3D = $Head/Camera3D
@onready var _interaction_ray: RayCast3D = $Head/Camera3D/InteractRay
@onready var _hint: Label = get_parent().get_node("UI/TargetHint")
@onready var _roof: Node3D = get_parent().get_node("Station/Roof")

func _ready() -> void:
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    _interaction_ray.target_position = Vector3(0.0, 0.0, -interaction_distance)
    _interaction_ray.enabled = true
    _interaction_ray.collide_with_bodies = true
    _interaction_ray.collide_with_areas = false

func _exit_tree() -> void:
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
        get_viewport().set_input_as_handled()
        return
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        rotate_y(-event.relative.x * mouse_sensitivity)
        _head.rotate_x(-event.relative.y * mouse_sensitivity)
        _head.rotation.x = clampf(_head.rotation.x, deg_to_rad(-80.0), deg_to_rad(80.0))
        get_viewport().set_input_as_handled()
        return
    if not event is InputEventKey or not event.pressed or event.echo:
        return
    if event.keycode == KEY_ESCAPE:
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    elif event.keycode == KEY_R:
        _roof.visible = not _roof.visible
    elif event.keycode == KEY_E:
        _try_interact()
    else:
        return
    get_viewport().set_input_as_handled()

func _try_interact() -> void:
    _interaction_ray.force_raycast_update()
    var collider: Object = _interaction_ray.get_collider()
    if collider != null and collider.has_method("interact"):
        collider.call("interact", self)

func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity.y -= 9.8 * delta
    else:
        velocity.y = 0.0

    var input_axis := Vector2.ZERO
    if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        if Input.is_physical_key_pressed(KEY_A): input_axis.x -= 1.0
        if Input.is_physical_key_pressed(KEY_D): input_axis.x += 1.0
        if Input.is_physical_key_pressed(KEY_W): input_axis.y -= 1.0
        if Input.is_physical_key_pressed(KEY_S): input_axis.y += 1.0
    input_axis = input_axis.normalized()
    var direction: Vector3 = global_transform.basis * Vector3(input_axis.x, 0.0, input_axis.y)
    velocity.x = direction.x * move_speed
    velocity.z = direction.z * move_speed
    move_and_slide()

    _interaction_ray.force_raycast_update()
    var collider: Object = _interaction_ray.get_collider()
    _hint.text = "[E] Open / close steel door" if collider != null and collider.has_method("interact") else ""
