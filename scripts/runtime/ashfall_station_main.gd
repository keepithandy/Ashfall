extends "res://scripts/runtime/game.gd"
## Ashfall station main: new authored level, old gameplay systems unchanged.
## F5 uses this scene; the previous main scene remains available for rollback.

func _ready() -> void:
    super._ready()
    if baking_editable_world:
        return
    # The earlier level used hand-authored anomaly rings; restore two safe test
    # placements in this cleaner map without changing hazard or detector math.
    make_anomaly(Vector3(-3.5, 0.15, -14), 1.9)
    make_anomaly(Vector3(12.0, 0.15, -38), 2.2)
    # Explain the new space without changing any of the player or HUD systems.
    if is_instance_valid(hud):
        hud.title.text = "A S H F A L L   /   STATION 04"
        hud.menu_title.text = "ASHFALL / STATION 04"
        hud.menu_title.add_theme_font_size_override("font_size", 50)
        hud.menu_body.text = "STATION 04 / ASSET PLAYTEST\n\nThree new houses stand ahead of the starting point.\nExplore the ochre workers house, green longhouse and white garden house.\nWalk through their interiors to test scale, materials and collision.\nRecover the research sample north of the station.\nStart the maintenance generator and retrieve the diagnostic.\nThe east service passage still connects to North Relay.\n\nWASD move  /  F flashlight  /  E interact  /  TAB inventory\nFollow the failing ward lights. Search the beds. Find a way back."
        hud.show_minimal_intro()
    if is_instance_valid(player):
        player.position = Vector3(0, 0.1, 25)
        player.rotation = Vector3(0, PI, 0)
    if has_node("VillageStalker"):
        var roaming_threat := get_node("VillageStalker") as CharacterBody3D
        roaming_threat.points = [
            Vector3(-57, 0, 14), Vector3(-57, 0, 22),
            Vector3(-49, 0, 23), Vector3(-40, 0, 23),
            Vector3(-44, 0, 19), Vector3(-54, 0, 19)
        ]



