extends SceneTree
func _initialize() -> void:call_deferred("capture")
func capture() -> void:
	var viewport := SubViewport.new()
	viewport.size=Vector2i(192,192);viewport.own_world_3d=true;viewport.transparent_bg=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;viewport.msaa_3d=Viewport.MSAA_4X
	root.add_child(viewport)
	var stage := Node3D.new();viewport.add_child(stage)
	var world := WorldEnvironment.new();var environment := Environment.new()
	environment.background_mode=Environment.BG_COLOR;environment.background_color=Color(0,0,0,0)
	environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.ambient_light_color=Color("bbc8bc");environment.ambient_light_energy=.75
	world.environment=environment;stage.add_child(world)
	var light := DirectionalLight3D.new();light.rotation_degrees=Vector3(-35,-35,0);light.light_energy=1.3;stage.add_child(light)
	var camera := Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.near=.005;stage.add_child(camera);camera.current=true
	DirAccess.make_dir_recursive_absolute("res://assets/items/icons")
	for id in ItemCatalog.ORDER:
		var model: Node3D=ItemCatalog.grip(id).model_scene.instantiate()
		stage.add_child(model);model.rotation.x=PI/2
		await process_frame
		var bounds := AABB();var first := true
		for mesh: MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
			# Use the authored hierarchy instead of relying on render/physics sync.
			var transform := mesh.transform
			var parent := mesh.get_parent()
			while parent!=stage and parent is Node3D:
				transform=parent.transform*transform
				parent=parent.get_parent()
			var box: AABB=transform*mesh.mesh.get_aabb()
			bounds=box if first else bounds.merge(box);first=false
		var center := bounds.get_center()
		var extent := maxf(bounds.size.x,maxf(bounds.size.y,bounds.size.z))
		camera.size=extent*1.25;camera.position=center+Vector3(.8,.5,-1.4).normalized()*extent*4
		camera.look_at(center)
		for i in range(8):await process_frame
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png("res://assets/items/icons/"+id+".png")
		model.queue_free();await process_frame
	print("ITEM_ICONS_BAKED: 8 rendered models")
	viewport.queue_free()
	await process_frame
	await process_frame
	quit()
