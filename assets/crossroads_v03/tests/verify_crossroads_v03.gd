## Run from a copy of the Ashfall project after import:
##   godot --headless --path PROJECT_PATH --script res://assets/crossroads_v03/tests/verify_crossroads_v03.gd
## This test does not alter existing game scenes or save data.
extends SceneTree

var failures: int = 0
var checks: int = 0
const BASE: String = "res://assets/crossroads_v03/scenes/"

func _initialize() -> void:
    call_deferred("_run_tests")

func _check(condition: bool, message: String) -> void:
    checks += 1
    if not condition:
        failures += 1
        push_error("Crossroads v0.3 FAIL: " + message)
    else:
        print("Crossroads v0.3 PASS: " + message)

func _ray_hit() -> bool:
    var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
        Vector3(0.0, 1.50, 0.6), Vector3(0.0, 1.50, -0.6)
    )
    return not root.world_3d.direct_space_state.intersect_ray(query).is_empty()

func _test_wall(filename: String, should_block: bool, title: String) -> void:
    var packed: PackedScene = load(BASE + filename) as PackedScene
    _check(packed != null, title + " loads")
    if packed == null:
        return
    var wall: Node3D = packed.instantiate()
    root.add_child(wall)
    await physics_frame
    _check(_ray_hit() == should_block, title + " center opening collision")
    wall.queue_free()
    await physics_frame

func _run_tests() -> void:
    # Doorway/window center rays at 1.5m must be passable. Solid/shutter must block.
    await _test_wall("wall_solid_4m.tscn", true, "solid wall")
    await _test_wall("wall_window_4m.tscn", false, "window opening")
    await _test_wall("wall_doorway_4m.tscn", false, "doorway opening")
    await _test_wall("wall_garage_4m.tscn", true, "closed garage shutter")
    var packed: PackedScene = load(BASE + "maintenance_station_v03.tscn") as PackedScene
    _check(packed != null, "assembled maintenance station loads")
    if packed != null:
        var station: Node3D = packed.instantiate()
        root.add_child(station)
        _check(station.get_node("Foundation").get_child_count() == 6, "six floor modules")
        _check(station.get_node("Roof").get_child_count() == 6, "six roof modules")
        _check(station.get_node("ExteriorWalls").get_child_count() == 10, "ten exterior wall modules")
        var door: Node3D = station.get_node("Equipment/PersonnelDoor/DoorHinge")
        _check(door.has_method("interact"), "personnel door has interaction")
        if door.has_method("set_open"):
            door.call("set_open", true, true)
            # AnimatableBody3D synchronizes its transform on the physics tick.
            await physics_frame
            _check(door.rotation.y > 0.5, "door swings inward")
        station.queue_free()
    var preview: PackedScene = load(BASE + "walkthrough_v03.tscn") as PackedScene
    _check(preview != null, "walkthrough scene loads")
    print("Crossroads v0.3 tests: %d checks, %d failures" % [checks, failures])
    quit(1 if failures > 0 else 0)
