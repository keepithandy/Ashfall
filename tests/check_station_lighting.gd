extends SceneTree
## Scene-level Station 04 lighting, localized mist and contact-weathering checks.
## Run after asset import: godot --headless --path . --script res://tests/check_station_lighting.gd

func _initialize() -> void:
    var failures: Array[String] = []
    var packed := load("res://scenes/ashfall_station_main.tscn") as PackedScene
    if packed == null:
        push_error("Cannot load Station 04 scene")
        quit(1)
        return

    var root := packed.instantiate()
    var world := root.get_node_or_null("WorldEnvironment") as WorldEnvironment
    var sun := root.get_node_or_null("OvercastSun") as DirectionalLight3D
    if world == null or world.environment == null:
        failures.append("WorldEnvironment is missing")
    else:
        var env := world.environment
        if not env.fog_enabled or not env.volumetric_fog_enabled:
            failures.append("Overcast atmosphere must keep fog and volumetric fog enabled")
        if env.ambient_light_energy <= 0.1 or env.ambient_light_energy > 0.7:
            failures.append("Ambient energy outside reviewable range")
        if env.volumetric_fog_density > 0.015:
            failures.append("Global volumetric fog may overwhelm exterior visibility")
    if sun == null or not sun.shadow_enabled:
        failures.append("Exterior overcast key light must cast shadows")
    elif sun.light_energy < 0.3 or sun.light_energy > 0.7:
        failures.append("Overcast sun energy outside controlled range")

    var layers := [
        "ResearchApproachMist",
        "ServiceYardMist",
        "SouthernCottagesMist"
    ]
    for name in layers:
        var mist := root.get_node_or_null("EditableWorld/AtmosphericVolumes/" + name) as FogVolume
        if mist == null:
            failures.append("Missing local mist volume: " + name)
            continue
        if mist.material == null:
            failures.append("Missing fog material: " + name)
        if mist.size.x < 8.0 or mist.size.z < 8.0 or mist.size.y > 3.0:
            failures.append("Local mist dimensions unexpected: " + name)

    var lamp := root.get_node_or_null("EditableWorld/Props/PortableWorkLamp") as Node3D
    var throw := root.get_node_or_null("EditableWorld/Props/WorkLampThrow") as SpotLight3D
    if lamp == null or throw == null:
        failures.append("Work lamp and its optional authored fill are missing")
    else:
        if throw.position.distance_to(Vector3(31, 1.62, 7.1)) > 0.1:
            failures.append("Work lamp fill moved away from the physical fixture")
        if throw.shadow_enabled or throw.spot_range > 12.0:
            failures.append("Work lamp fill exceeds the local illumination budget")

    var lens := root.get_node_or_null("EditableWorld/Props/LampEmissiveLens") as MeshInstance3D
    if lens == null or lens.mesh == null:
        failures.append("Tripod work-light has no emissive lens visual")
    else:
        var lens_mat := lens.material_override as StandardMaterial3D
        if lens_mat == null or not lens_mat.emission_enabled:
            failures.append("Tripod work-light lens is not emissive")
        if lens.position.distance_to(Vector3(30.952, 1.62, 7.088)) > 0.12:
            failures.append("Tripod work-light lens is not aligned with the fixture")

    var ground := root.get_node_or_null("EditableWorld/Terrain/WalkableGround/VisibleGround") as MeshInstance3D
    var ground_shape := root.get_node_or_null("EditableWorld/Terrain/WalkableGround/GroundCollision") as CollisionShape3D
    if ground == null or ground_shape == null:
        failures.append("Existing ground visual or collision missing")
    else:
        var surface := ground.material_override as ShaderMaterial
        if surface == null or surface.shader == null:
            failures.append("Ground blending shader missing")
        elif not surface.shader.code.contains("foundation_weathering"):
            failures.append("Ground material has no contact weathering")
        elif not surface.shader.code.contains("industrial_staining"):
            failures.append("Ground material has no contact staining")
        elif surface.get_shader_parameter("foundation_weathering") < 0.0:
            failures.append("Foundation weathering invalid")
    root.free()

    if failures.is_empty():
        print("STATION 04 LIGHTING CHECK PASSED")
        print("Lighting/fog/placement reviewed in source, not a rendered visual or FPS certification")
        quit(0)
    else:
        for issue in failures:
            push_error(issue)
        print("STATION 04 LIGHTING CHECK FAILED: ", failures.size())
        quit(1)
