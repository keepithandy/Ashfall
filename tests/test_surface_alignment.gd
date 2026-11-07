extends SceneTree
var errors:=0
func _initialize() -> void:
	call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value:
		errors+=1
		push_error("SURFACE_ALIGNMENT_FAIL: "+message)
func top(mesh: MeshInstance3D) -> float:
	return (mesh.global_transform*mesh.mesh.get_aabb().end).y
func run() -> void:
	var game=load("res://scenes/ashfall_editable.tscn").instantiate()
	root.add_child(game)
	game.smoke_test=true
	game.resume_game()
	game.get_node("VillageStalker").set_physics_process(false)
	await physics_frame
	var cottage=game.get_node("EditableWorld/Buildings/VillageLayout/FirstVillageCottage")
	var footing: float=top(cottage.get_node("BrickFooting/Surface"))
	var floor_height: float=top(cottage.get_node("TimberFloor/Surface"))
	check(floor_height-footing>0.03,"Foundation is coplanar with timber floor")
	var board: MeshInstance3D=cottage.get_node("CottageDetail/PorchDeckPlank")
	var porch_col: CollisionShape3D=cottage.get_node("PorchDeck/Collision_001")
	var porch_height: float=porch_col.global_position.y+porch_col.shape.size.y*0.5
	check(absf(porch_height-top(board))<0.002,"Porch boards do not match walkable collision")
	for name in ["VillageDirtLane","Mesh_001","Mesh_002"]:
		check(top(cottage.get_parent().get_node(name))<0.008,"Village path floats above ground")
	var geometry=game.get_node("EditableWorld/TerrainAndStructures")
	for i in range(4,17):
		check(top(geometry.get_node("Geometry_%03d/Mesh_001" % i))<0.008,"Road or road marking floats above ground")
	var desk: MeshInstance3D=game.get_node("EditableWorld/Buildings/CheckpointHouse/DeskTop/Surface")
	var medical: MeshInstance3D=game.supplies.get_child(0)
	var medical_bottom: float=(medical.global_transform*medical.mesh.get_aabb().position).y
	check(absf(medical_bottom-top(desk))<0.003,"Medical case is floating above its desk")
	for point in [Vector3(-46,0.5,10),Vector3(-44.9,0.5,6),Vector3(-46,0.5,12.1)]:
		game.player.position=point
		game.player.velocity=Vector3.ZERO
		for i in range(30):
			await physics_frame
		var expected: float=0.20 if point.z>11.5 else 0.18
		check(game.player.is_on_floor() and absf(game.player.position.y-expected)<0.012,"Feet do not meet floor at "+str(point))
	print("SURFACE_ALIGNMENT_CHECK: failures=",errors)
	quit(1 if errors else 0)
