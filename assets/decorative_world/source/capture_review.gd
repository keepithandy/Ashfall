extends SceneTree
## Renders both decorative packs with a controlled camera and lighting.
## Runs only in CI/editor review; it is not part of gameplay.
const WORLD := [
"bent_guardrail", "collapsed_bus_shelter", "discarded_tire_pile", "fallen_utility_pole",
"rusted_mailbox", "sagging_porch_chair", "cracked_plant_pots", "torn_clothesline",
"crushed_ventilation_duct", "collapsed_cable_tray", "corroded_sheet_metal_stack",
"broken_factory_window", "rotting_picnic_table", "damaged_footbridge_fragment",
"roadside_memorial", "broken_drainage_culvert",
]
const INTERIORS := [
"sagging_sofa", "battered_armchair", "cracked_crt_television", "crooked_wall_mirror",
"splintered_dining_table", "damaged_kitchen_cupboard", "broken_crockery_scatter",
"rusted_enamel_kettle", "tilted_wooden_dresser", "torn_interior_curtains",
"threadbare_area_rug", "faded_photo_frames", "fallen_ceiling_tile_pile",
"broken_ceiling_fan", "peeling_wallpaper_panels", "dusty_cardboard_box_stack",
]
var stage: Node3D
var camera: Camera3D
var ambient: WorldEnvironment
var sunlight: DirectionalLight3D

func _initialize() -> void:
    call_deferred("_capture")

func _capture() -> void:
    stage = Node3D.new()
    stage.name = "TemporaryPreviewStage"
    root.add_child(stage)

    ambient = WorldEnvironment.new()
    var sky_environment := Environment.new()
    sky_environment.background_mode = Environment.BG_COLOR
    sky_environment.background_color = Color(0.14, 0.16, 0.17)
    sky_environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    sky_environment.ambient_light_color = Color(0.55, 0.60, 0.63)
    sky_environment.ambient_light_energy = 0.70
    ambient.environment = sky_environment
    stage.add_child(ambient)

    sunlight = DirectionalLight3D.new()
    sunlight.rotation_degrees = Vector3(-56, -33, -11)
    sunlight.light_energy = 1.25
    sunlight.shadow_enabled = true
    stage.add_child(sunlight)

    var floor_mesh := PlaneMesh.new()
    floor_mesh.size = Vector2(14, 14)
    var floor_surface := StandardMaterial3D.new()
    floor_surface.albedo_color = Color(0.19, 0.205, 0.19)
    floor_surface.roughness = 1.0
    var floor := MeshInstance3D.new()
    floor.mesh = floor_mesh
    floor.material_override = floor_surface
    floor.position.y = -0.05
    stage.add_child(floor)

    camera = Camera3D.new()
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.current = true
    stage.add_child(camera)

    var outdir := OS.get_environment("ASHFALL_REVIEW_DIR")
    if outdir.is_empty():
        outdir = "user://reviews"
    DirAccess.make_dir_recursive_absolute(outdir)

    for pack in ["decorative_world", "decorative_interiors"]:
        var names := WORLD if pack == "decorative_world" else INTERIORS
        for item_name in names:
            var scene_path := "res://scenes/%s/%s.tscn" % [pack, item_name]
            var packed := load(scene_path) as PackedScene
            if packed == null:
                push_error("Could not load preview scene " + scene_path)
                quit(1)
                return
            var prop := packed.instantiate() as Node3D
            if prop == null:
                push_error("Could not instantiate preview scene " + scene_path)
                quit(1)
                return
            stage.add_child(prop)
            var found := false
            var bbox := AABB()
            for child in prop.find_children("*", "MeshInstance3D", true, false):
                var mesh_instance := child as MeshInstance3D
                if mesh_instance == null or mesh_instance.mesh == null:
                    continue
                var bounds: AABB = mesh_instance.global_transform * mesh_instance.get_aabb()
                bbox = bbox.merge(bounds) if found else bounds
                found = true
            if not found:
                push_error("No mesh visible in " + scene_path)
                prop.free()
                quit(1)
                return
            var center := bbox.get_center()
            var extent := maxf(bbox.size.x, maxf(bbox.size.y, bbox.size.z))
            camera.size = maxf(1.2, extent * 1.66)
            camera.position = center + Vector3(5.0, 3.2, 6.8).normalized() * maxf(5.5, extent * 2.4)
            camera.look_at(center, Vector3.UP)
            camera.current = true
            for f in range(4):
                await process_frame
            var output_image := root.get_texture().get_image()
            if output_image == null or output_image.is_empty():
                push_error("No framebuffer pixels for " + scene_path)
                prop.free()
                quit(1)
                return
            var target := outdir.path_join("%s__%s.png" % [pack, item_name])
            var saved := output_image.save_png(target)
            if saved != OK:
                push_error("Screenshot save failed: " + target)
                prop.free()
                quit(1)
                return
            print("RENDERED ", pack, " ", item_name, " bounds=", bbox)
            prop.free()
        if pack == "decorative_world":
            ambient.environment.background_color = Color(0.09, 0.105, 0.112)
            ambient.environment.ambient_light_color = Color(0.35, 0.43, 0.45)
            ambient.environment.ambient_light_energy = 0.36
            sunlight.light_energy = 0.42
    print("PASS: Rendered 32 prop previews, including darker Ashfall lighting")
    quit(0)
