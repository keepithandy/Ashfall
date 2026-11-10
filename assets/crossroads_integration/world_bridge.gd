## Ashfall Crossroads v0.3 main-game integration, Godot 4.x.
## Registered as a reversible autoload by the installer; does not edit existing scenes.
## Loads the finished station only in a 3D gameplay scene with an active player camera.
extends Node

const STATION_SCENE: PackedScene = preload("res://assets/crossroads_v03/scenes/maintenance_station_v03.tscn")
const SETTINGS_PATH := "res://assets/crossroads_integration/placement.cfg"
const STATION_NAME := "AshfallCrossroadsStation"

var _pending_seconds: float = 0.0
var _last_scene_id: int = 0
var _failed_notice_id: int = 0

func _ready() -> void:
    # The game may start at a 2D menu; wait until an actual 3D playable scene exists.
    get_tree().scene_changed.connect(_on_scene_changed)
    set_process(true)

func _on_scene_changed(_scene: Node) -> void:
    _last_scene_id = 0
    _pending_seconds = 0.0

func _physics_process(delta: float) -> void:
    _pending_seconds += delta
    if _pending_seconds < 0.75:
        return
    _pending_seconds = 0.0
    var world: Node = get_tree().current_scene
    if world == null or not (world is Node3D):
        return
    if world.scene_file_path.begins_with("res://assets/crossroads_"):
        return
    if world.has_node(STATION_NAME):
        return
    var scene_id: int = world.get_instance_id()
    if _last_scene_id == scene_id:
        return
    # Only install near the player, never into a main menu, editing preview or test scene.
    var player_camera: Camera3D = get_viewport().get_camera_3d()
    if player_camera == null or not world.is_ancestor_of(player_camera):
        return
    var player_position: Vector3 = player_camera.global_position
    var player_actor: Node = player_camera
    while player_actor != world and player_actor != null:
        if player_actor is CharacterBody3D or player_actor is RigidBody3D:
            player_position = (player_actor as Node3D).global_position
            break
        player_actor = player_actor.get_parent()
    var placement := _choose_placement(world, player_camera, player_position)
    if placement.is_empty():
        if _failed_notice_id != scene_id:
            push_warning("Crossroads not placed: no suitable location. Set mode=fixed in placement.cfg or add CrossroadsStationAnchor (Node3D) to the game world.")
            _failed_notice_id = scene_id
        _last_scene_id = scene_id
        return
    var station: Node3D = STATION_SCENE.instantiate() as Node3D
    if station == null:
        push_error("Crossroads station failed to instantiate.")
        _last_scene_id = scene_id
        return
    station.name = STATION_NAME
    world.add_child(station)
    station.global_transform = placement["transform"]
    station.set_meta("crossroads_version", "0.3")
    _last_scene_id = scene_id
    print("[Ashfall Crossroads] Maintenance Station integrated into playable world at ", station.global_position)

func _choose_placement(world: Node3D, camera: Camera3D, player_pos: Vector3) -> Dictionary:
    # A designer-placed Node3D anchor overrides all automatic placement.
    var anchor: Node = world.find_child("CrossroadsStationAnchor", true, false)
    if anchor is Node3D:
        return {"transform": (anchor as Node3D).global_transform}
    var cfg := ConfigFile.new()
    if cfg.load(SETTINGS_PATH) != OK:
        push_warning("Missing Crossroads placement.cfg; using safe default values.")
    var mode: String = str(cfg.get_value("placement", "mode", "near_player"))
    var height_adjust: float = float(cfg.get_value("placement", "height_adjust", 0.0))
    if mode == "fixed":
        var fixed_pos: Vector3 = cfg.get_value("placement", "fixed_position", Vector3(25, 0, 25))
        var fixed_yaw: float = deg_to_rad(float(cfg.get_value("placement", "yaw_degrees", 0.0)))
        return {"transform": Transform3D(Basis(Vector3.UP, fixed_yaw), fixed_pos + Vector3.UP * height_adjust)}
    var forward: Vector3 = -camera.global_transform.basis.z
    forward.y = 0.0
    if forward.length_squared() < 0.001:
        forward = Vector3.FORWARD
    forward = forward.normalized()
    # Look for free land ahead and slightly off-axis. Never place directly over player.
    var direction_variants := [forward, forward.rotated(Vector3.UP, 0.55), forward.rotated(Vector3.UP, -0.55)]
    var world_physics: PhysicsDirectSpaceState3D = world.get_world_3d().direct_space_state
    for direction in direction_variants:
        for distance in [28.0, 40.0, 52.0]:
            var target: Vector3 = player_pos + direction * distance
            var land := _ground_hit(world_physics, target)
            if land.is_empty():
                continue
            var p: Vector3 = land["position"]
            if abs(p.y - player_pos.y) > 8.0:
                continue
            if not _terrain_is_level(world_physics, p):
                continue
            # Check for buildings, walls, or other obstacles in the station's footprint.
            if not _footprint_clear(world_physics, p):
                continue
            var toward_player: Vector3 = player_pos - p
            toward_player.y = 0.0
            var yaw := atan2(toward_player.x, toward_player.z)
            return {"transform": Transform3D(Basis(Vector3.UP, yaw), p + Vector3.UP * height_adjust)}
    return {}

func _ground_hit(space: PhysicsDirectSpaceState3D, p: Vector3) -> Dictionary:
    var query := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 55.0, p - Vector3.UP * 90.0)
    query.collision_mask = 1
    return space.intersect_ray(query)

func _terrain_is_level(space: PhysicsDirectSpaceState3D, p: Vector3) -> bool:
    # Center and four approximate corners, with tolerant slope check.
    for offset in [Vector3(-6,0,-4), Vector3(6,0,-4), Vector3(-6,0,4), Vector3(6,0,4)]:
        var hit := _ground_hit(space, p + offset)
        if hit.is_empty() or abs(hit["position"].y - p.y) > 0.65:
            return false
    return true

func _footprint_clear(space: PhysicsDirectSpaceState3D, p: Vector3) -> bool:
    # A modest box above the terrain. Does not overlap an intact building roof/wall.
    var volume := BoxShape3D.new()
    volume.size = Vector3(15.0, 3.2, 15.0)
    var query := PhysicsShapeQueryParameters3D.new()
    query.shape = volume
    query.transform = Transform3D(Basis.IDENTITY, p + Vector3(0, 1.72, 0))
    query.collision_mask = 1
    query.margin = 0.03
    # Terrain height variation may count as an obstruction; if so, use a fixed anchor.
    return space.intersect_shape(query, 1).is_empty()
