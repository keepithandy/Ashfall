extends "res://scripts/runtime/game.gd"
## Ashfall station main: new authored level, old gameplay systems unchanged.
## F5 uses this scene; the previous main scene remains available for rollback.

# Station-only draw distance: keep other Ashfall levels at their authored budgets.
@export_range(160.0, 1200.0, 25.0) var station_render_distance: float = 900.0

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
        hud.title.text = "ASHFALL 2.0  /  FIELD UNIT 04"
        hud.menu_title.text = "ASHFALL 2.0"
        hud.menu_title.add_theme_font_size_override("font_size", 50)
        hud.menu_body.text = "STATION 04  /  FIELD EXPEDITION\n\nRecover the sample. Scavenge what you can. Find your way back.\n[F10] PERSONALIZE YOUR FIELD JOURNAL"
        hud.show_minimal_intro()
    if is_instance_valid(player):
        player.camera.far = station_render_distance
        player.position = Vector3(0, 0.1, 25)
        player.rotation = Vector3(0, PI, 0)
    # All informational prompts now belong to the screen-space field HUD.
    # Purge any legacy world-space captions from instanced props or areas.
    for caption in find_children("*", "Label3D", true, false):
        caption.hide()
        caption.queue_free()
    if has_node("VillageStalker"):
        var roaming_threat := get_node("VillageStalker") as CharacterBody3D
        roaming_threat.points = [
            Vector3(-57, 0, 14), Vector3(-57, 0, 22),
            Vector3(-49, 0, 23), Vector3(-40, 0, 23),
            Vector3(-44, 0, 19), Vector3(-54, 0, 19)
        ]



