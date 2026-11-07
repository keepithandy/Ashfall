extends SceneTree
var errors:=0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, what: String) -> void:
	if not ok:
		errors+=1
		push_error("COTTAGE_GROUND_FAIL: "+what)
func run() -> void:
	var game=load("res://scenes/ashfall_editable.tscn").instantiate()
	var terrain: StaticBody3D=game.get_node("NaturalGround")
	var original: StaticBody3D=game.get_node("EditableWorld/TerrainAndStructures/Ground")
	var collision: CollisionShape3D=original.get_node("Collision_002")
	check(not original.visible and collision.disabled,"Old ground still visible or colliding")
	check(game.is_editable_instance(terrain),"Ground is not editable")
	var mesh: ArrayMesh=terrain.get_node("TerrainMesh").mesh
	var arrays:=mesh.surface_get_arrays(0)
	check(arrays[Mesh.ARRAY_VERTEX].size()==36381 and arrays[Mesh.ARRAY_INDEX].size()/3==72000,"Terrain resolution incorrect")
	check(arrays[Mesh.ARRAY_TANGENT].size()==36381*4,"Terrain normal-map tangents missing")
	check(terrain.get_node("TerrainCollision").shape is ConcavePolygonShape3D,"Terrain collision missing")
	var cottage: Node3D=game.get_node("EditableWorld/Buildings/VillageLayout/FirstVillageCottage")
	var detail: Node3D=cottage.get_node("CottageDetail")
	check(detail.has_node("IndividuallyWeatheredBricks") and detail.get_child_count()>40,"Cottage details missing")
	check(detail.find_children("*","Label3D",true,false).is_empty(),"Building detail has text")
	var reusable=load("res://scenes/houses/blue_porch_cottage.tscn").instantiate()
	check(reusable.has_node("CottageDetail"),"Reusable cottage lacks detail")
	reusable.free()
	root.add_child(game)
	game.smoke_test=true
	game.resume_game()
	await physics_frame
	await physics_frame
	for position in [Vector3(0,2,25),Vector3(-46,2,20),Vector3(-72,2,30),Vector3(35,2,-10)]:
		var query:=PhysicsRayQueryParameters3D.create(position,position-Vector3.UP*4)
		query.exclude=[game.player.get_rid()]
		var hit=game.get_world_3d().direct_space_state.intersect_ray(query)
		check(not hit.is_empty() and hit.collider==terrain and hit.position.y<=0.01 and hit.position.y> -0.1,"Ground is missing or not walkable at "+str(position))
	game.player.position=Vector3(-72,0.5,30)
	game.player.velocity=Vector3.ZERO
	for i in range(45):
		await physics_frame
	check(game.player.is_on_floor() and game.player.position.y>-0.12,"Player fell through terrain")
	print("COTTAGE_GROUND_CHECK: failures=",errors)
	quit(1 if errors else 0)
