extends SceneTree
## Scene/resource smoke test for the unmerged Station 04 visual upgrade.
## Run: godot --headless --path . --script res://tests/check_environment_overhaul.gd

const HOUSES := [
    "res://scenes/houses/green_longhouse.tscn",
    "res://scenes/houses/ochre_workers_house.tscn",
    "res://scenes/houses/white_garden_house.tscn",
    "res://scenes/houses/blue_porch_cottage.tscn",
    "res://scenes/houses/cottage_detail.tscn",
]

func _initialize() -> void:
    var failed := false
    var cloud_shader := load("res://assets/shaders/ashfall_overcast_clouds.gdshader") as Shader
    if cloud_shader == null:
        push_error("Cloud shader could not load")
        failed = true

    var station_scene := load("res://scenes/ashfall_station_main.tscn") as PackedScene
    if station_scene == null:
        push_error("Station 04 scene could not load")
        failed = true
    else:
        var station := station_scene.instantiate()
        var world := station.get_node_or_null("WorldEnvironment") as WorldEnvironment
        if world == null or world.environment == null or world.environment.sky == null:
            push_error("Station 04 WorldEnvironment or sky missing")
            failed = true
        elif not (world.environment.sky.sky_material is ShaderMaterial):
            push_error("Station 04 does not use an installed ShaderMaterial sky")
            failed = true
        station.free()

    for house_path in HOUSES:
        var house_scene := load(house_path) as PackedScene
        if house_scene == null:
            push_error("Cannot load house: " + house_path)
            failed = true
            continue
        var house := house_scene.instantiate()
        var detail := house.get_node_or_null("ArchitecturalWeathering")
        if detail == null or detail.get_script() == null:
            push_error("Weathering component missing: " + house_path)
            failed = true
        house.free()

    if failed:
        print("ASHFALL ENVIRONMENT CHECK: FAILED - inspect errors")
        quit(1)
    else:
        print("ASHFALL ENVIRONMENT CHECK: PASSED - resource loading only")
        print("Visuals, GPU shader compilation and performance require an in-editor test.")
        quit(0)
