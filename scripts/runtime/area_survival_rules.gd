extends Node
## Optional, per-area survival exposure. Default GROUNDED is exactly the
## original Ashfall movement, damage and perception balance.
## User selection is stored in a UI config, not expedition save data.
const TIERS := ["LIGHT", "GROUNDED", "BRUTAL"]
const PROFILE_PATH := "user://ashfall_23_survival.cfg"
const DAMAGE := [0.74, 1.0, 1.42]
const EXERTION := [0.84, 1.0, 1.30]
const RECOVERY := [1.20, 1.0, 0.72]
const HEARING := [0.90, 1.0, 1.15]
var game: Node3D
var selected := {"perimeter": 1, "relay": 1}
var hardcore := {"perimeter": false, "relay": false}


func _ready() -> void:
    name = "AreaSurvivalRules"
    load_choices()


func area() -> String:
    if not is_instance_valid(game):
        return "perimeter"
    var areas := game.get("areas") as Node
    if areas == null:
        return "perimeter"
    return str(areas.get("current"))


func _index() -> int:
    return clampi(int(selected.get(area(), 1)), 0, 2)


func _hard() -> bool:
    return bool(hardcore.get(area(), false))


func incoming_damage_factor() -> float:
    return DAMAGE[_index()] * (1.25 if _hard() else 1.0)


func stamina_cost_factor() -> float:
    return EXERTION[_index()] * (1.15 if _hard() else 1.0)


func stamina_recovery_factor() -> float:
    return RECOVERY[_index()] * (0.85 if _hard() else 1.0)


func hearing_factor() -> float:
    return HEARING[_index()] * (1.1 if _hard() else 1.0)


func label() -> String:
    return TIERS[_index()] + ("  /  HARDCORE" if _hard() else "")


func set_tier(id: String, level: int) -> void:
    selected[id] = clampi(level, 0, TIERS.size() - 1)
    save_choices()


func set_hardcore(id: String, enabled: bool) -> void:
    hardcore[id] = enabled
    save_choices()


func load_choices() -> void:
    var config := ConfigFile.new()
    if config.load(PROFILE_PATH) != OK:
        return
    for id in selected.keys():
        selected[id] = clampi(int(config.get_value(id, "tier", 1)), 0, 2)
        hardcore[id] = bool(config.get_value(id, "hardcore", false))


func save_choices() -> void:
    var config := ConfigFile.new()
    for id in selected.keys():
        config.set_value(id, "tier", selected[id])
        config.set_value(id, "hardcore", hardcore[id])
    if config.save(PROFILE_PATH) != OK:
        push_warning("Survival preference could not be saved")


func _input(event: InputEvent) -> void:
    if not event is InputEventKey or not event.pressed or event.echo:
        return
    if not is_instance_valid(game) or not bool(game.get("started")):
        return
    var player := game.get("player") as CharacterBody3D
    if player == null or not bool(player.get("active")):
        return
    var id := area()
    if event.physical_keycode == KEY_F6:
        set_tier(id, (_index() + 1) % TIERS.size())
        game.call("show_message", "SURVIVAL  /  " + id.to_upper() + "  /  " + label(), 5.0)
        get_viewport().set_input_as_handled()
    elif event.physical_keycode == KEY_F9:
        set_hardcore(id, not _hard())
        game.call("show_message", "SURVIVAL  /  " + id.to_upper() + "  /  " + label(), 5.0)
        get_viewport().set_input_as_handled()
