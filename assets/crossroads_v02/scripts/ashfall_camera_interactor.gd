## Optional minimal first-person camera interactor.
## Attach to the player's Camera3D only if Ashfall doesn't already have an interact raycast.
## Add an InputMap action named "interact" (recommended key: E).
extends Camera3D

@export var action_name: StringName = &"interact"
@export_range(0.5, 5.0, 0.1) var reach_meters: float = 2.5
@export_flags_3d_physics var interaction_mask: int = 1

@onready var _ray: RayCast3D = RayCast3D.new()

func _ready() -> void:
    _ray.enabled = true
    _ray.collision_mask = interaction_mask
    _ray.collide_with_areas = false
    _ray.collide_with_bodies = true
    _ray.target_position = Vector3(0, 0, -reach_meters)
    add_child(_ray)
    if not InputMap.has_action(action_name):
        push_warning("Create an InputMap action named '%s' to interact." % action_name)

func _unhandled_input(event: InputEvent) -> void:
    if not event.is_action_pressed(action_name):
        return
    _ray.target_position = Vector3(0, 0, -reach_meters)
    _ray.force_raycast_update()
    var target: Object = _ray.get_collider()
    if target and target.has_method("interact"):
        target.call("interact", get_parent())
        get_viewport().set_input_as_handled()
