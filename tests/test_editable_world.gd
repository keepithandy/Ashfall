extends SceneTree
var errors:=0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		errors+=1
		push_error("EDITABLE_WORLD_FAIL: "+message)
func run() -> void:
	var packed:=load("res://scenes/ashfall_editable.tscn") as PackedScene
	var game=packed.instantiate()
	var world: Node3D=game.get_node("EditableWorld")
	check(game.is_editable_instance(world),"Editable children are not enabled")
	for name in ["Lighting","TerrainAndStructures","Buildings","Props","Vegetation","GameplayObjects"]:
		check(world.has_node(name),"Missing editor group "+name)
	var ground: Node3D=world.get_node("TerrainAndStructures/Ground")
	var sample: Node3D=world.get_node("GameplayObjects/ResearchSample")
	check(ground.get_child_count()>=2 and sample.owner==world,"Models and collision do not belong to the saved world")
	# A change made to the editor-owned node must be used directly at runtime.
	var changed_position: Vector3=sample.position+Vector3(0,0,0.25)
	sample.position=changed_position
	var changed_scene:=PackedScene.new()
	check(changed_scene.pack(game)==OK,"Could not pack an edited scene")
	check(ResourceSaver.save(changed_scene,"user://editable_world_test.tscn")==OK,"Could not save an edited scene")
	var reloaded: Node=ResourceLoader.load("user://editable_world_test.tscn","",ResourceLoader.CACHE_MODE_IGNORE).instantiate()
	check(reloaded.get_node("EditableWorld/GameplayObjects/ResearchSample").position.is_equal_approx(changed_position),"An editor-style saved transform did not persist")
	reloaded.free()
	root.add_child(game)
	game.smoke_test=true
	game.resume_game()
	await physics_frame
	check(game.sample==sample and game.sample.position.is_equal_approx(changed_position),"Gameplay regenerated or ignored an edited object")
	check(game.anomalies.size()==3,"Anomalies were not connected")
	check(game.find_children("*","WorldEnvironment",true,false).size()==1,"Duplicate or missing environment")
	check(game.find_children("*","Label3D",true,false).is_empty(),"Attached world text found")
	var caches:=[]
	for node in world.find_children("*","StaticBody3D",true,false):
		if node.get_meta("interaction","")=="loot_container":
			caches.append(node)
	check(caches.size()==3,"Loot caches missing or duplicated")
	if caches.size()==3:
		check(caches[0].contents.bandage==2 and caches[1].contents.food_tin==2 and caches[2].contents.batteries==2,"Saved cache contents were lost")
		var count: int=caches[0].get_child_count()
		game.open_loot(caches[0])
		game.take_loot()
		game.close_loot()
		check(game.inventory.bandage==2 and caches[0].contents.is_empty() and caches[0].get_child_count()==count,"Loot interaction did not work or duplicated geometry")
	check(world.find_children("*","MultiMeshInstance3D",true,false).size()>0,"Vegetation batches missing")
	print("EDITABLE_WORLD_CHECK: failures=",errors)
	quit(1 if errors else 0)
