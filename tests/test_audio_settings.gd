extends SceneTree
var failures := 0
func _initialize() -> void:
    call_deferred("run")
func check(condition: bool, description: String) -> void:
    if condition:
        print("PASS: ", description)
    else:
        failures += 1
        push_error("FAIL: " + description)
func run() -> void:
    var game = load("res://scenes/ashfall_editable.tscn").instantiate()
    root.add_child(game)
    await process_frame
    check(game.player.footsteps.bus == "Footsteps", "footsteps use their own channel")
    check(game.player.footsteps.volume_db <= -28, "default footsteps are quieter")
    check(game.ambience.bus == "Wind", "wind uses its own channel")
    var sounds = game.get_node("Atmosphere").sounds
    check(sounds.size() > 0 and sounds[0].bus == "Effects", "world cues use effects channel")
    check(game.get_node("VillageStalker").breath.bus == "Effects", "creature uses effects channel")
    var settings = game.hud.audio_panel
    settings.show()
    var slider: HSlider = settings.get_node("FootstepsSlider")
    slider.value = 35
    check(is_equal_approx(game.audio_settings.levels.Footsteps, 0.35), "slider changes the footstep volume")
    var index = AudioServer.get_bus_index("Footsteps")
    check(is_equal_approx(AudioServer.get_bus_volume_db(index), linear_to_db(0.35)), "volume reaches audio engine")
    slider.value = 0
    check(AudioServer.is_bus_mute(index), "zero mutes the channel")
    slider.value = 42
    var saved = load("res://scripts/runtime/audio_settings.gd").new()
    saved.setup()
    check(is_equal_approx(saved.levels.Footsteps, 0.42), "settings persist across sessions")
    game.resume_game()
    game.pause_game()
    settings.show()
    var escape := InputEventKey.new()
    escape.physical_keycode = KEY_ESCAPE
    escape.pressed = true
    game._unhandled_input(escape)
    check(not settings.visible and game.hud.overlay.visible and not game.player.active, "Escape returns to the pause menu")
    game.audio_settings.set_level("Footsteps", 1.0)
    game.queue_free()
    await process_frame
    print("AUDIO_SETTINGS: ", failures, " failure(s)")
    quit(1 if failures else 0)
