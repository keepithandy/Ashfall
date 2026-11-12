extends SceneTree
## Ashfall 2.1 integration: world-detail placement, readable discovery notes,
## search around last-known threat positions, and reversible render budgets.
## godot --headless --path . --script res://tests/check_station_immersion.gd

func _initialize() -> void:
    call_deferred("_verify")


func _verify() -> void:
    var failures: Array[String] = []
    var packed := load("res://scenes/ashfall_station_main.tscn") as PackedScene
    if packed == null:
        push_error("Cannot open Station 04 scene")
        quit(1)
        return
    var level := packed.instantiate()
    root.add_child(level)
    await process_frame
    var player := level.get("player") as CharacterBody3D
    var hud := level.get("hud") as Control
    var detail := level.get_node_or_null("WorldDetail21") as Node3D
    var budget := level.get_node_or_null("Station04VisualBudget") as Node
    var audio := level.get_node_or_null("Station04AmbientCues") as Node3D
    if audio == null or (audio.get("cues") as Array).size() != 5:
        failures.append("Station 04 positional atmosphere cue layer missing")
    if player == null or hud == null:
        failures.append("No playable player or HUD")
    if detail == null:
        failures.append("World detail node missing")
    else:
        if int(detail.get("foliage_count")) < 95:
            failures.append("Near-ground vegetation failed to populate")
        if int(detail.get("landmark_count")) != 4:
            failures.append("Four narrative environment assets were not placed")
        var patches := detail.get_node_or_null("DecorativeDetail/Understory")
        var narrative := detail.get_node_or_null("DecorativeDetail/NarrativeProps")
        if patches == null or narrative == null:
            failures.append("Missing separated understory and landmark scene nodes")
        else:
            for collision in patches.find_children("*", "CollisionObject3D", true, false):
                var body := collision as CollisionObject3D
                if body.collision_layer != 0 or body.collision_mask != 0:
                    failures.append("Decorative undergrowth unexpectedly blocks the player")
                    break
            if narrative.get_child_count() != 4:
                failures.append("Missing authored story props")
        var positions: Array = detail.get("placement_points")
        for point in positions:
            if absf(point.x) > 79.0 or absf(point.z) > 78.0:
                failures.append("Undergrowth escaped intended world bounds")
                break
        detail.call("rebuild")
        if detail.get_node("DecorativeDetail").get_child_count() != 2:
            failures.append("Environment dressing rebuild is not idempotent")
    if player != null and budget != null:
        if not is_equal_approx(player.camera.far, 900.0):
            failures.append("Default Station 04 distance was changed")
        budget.call("set_view_mode", 2)
        if not is_equal_approx(player.camera.far, 400.0):
            failures.append("F8 performance view distance did not apply")
        budget.call("set_view_mode", 0)
        if not is_equal_approx(player.camera.far, 900.0):
            failures.append("Long-view distance did not restore")
    else:
        failures.append("Render-budget controller missing")
    if player != null and hud != null:
        var record := hud.get("field_record") as Control
        if record == null:
            failures.append("Field Record panel missing")
        else:
            if record.visible:
                failures.append("Field Record covers the opening view")
            if int(record.get("unlocked").size()) != 1:
                failures.append("Survey is not reset for a new expedition")
            level.set("started", true)
            level.set("smoke_test", true)
            player.active = true
            player.position = Vector3(-12, 0.1, 65)
            record.call("_process", 0.0)
            if not record.get("unlocked").has("memorial"):
                failures.append("Approaching the roadside memorial did not discover it")
            record.call("open_record")
            if not record.visible or player.active:
                failures.append("Field Record does not pause local movement")
            if not record.get("content").text.contains("ROADSIDE MEMORIAL"):
                failures.append("Unlocked site not displayed in journal")
            record.call("close_record")
            if record.visible or not player.active:
                failures.append("Closing journal did not return control")
            player.active = false
    var stalker := level.get_node_or_null("VillageStalker")
    if stalker != null and stalker.get_script() != null:
        stalker.set("last_known", Vector3(-47, 0, 17))
        stalker.set("search_index", 0)
        var first: Vector3 = stalker.call("search_destination")
        stalker.set("search_index", 1)
        var next: Vector3 = stalker.call("search_destination")
        if first.distance_to(Vector3(-47, 0, 17)) > 0.01 or first.distance_to(next) < 2.0:
            failures.append("Creature is not searching around last-known location")
    else:
        failures.append("Village threat was not instantiated")
    level.queue_free()
    await process_frame
    if failures.is_empty():
        print("ASHFALL 2.1 IMMERSION CHECK PASSED")
        quit(0)
    else:
        for issue in failures:
            push_error(issue)
        print("ASHFALL 2.1 IMMERSION CHECK FAILED: ", failures.size(), " issues")
        quit(1)
