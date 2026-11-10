extends RefCounted
## Local collision-sampled routing. Never steers through a wall or teleports.
var route := PackedVector3Array()
var refresh := 0.0

func direction(actor: CharacterBody3D, destination: Vector3, delta: float) -> Vector3:
	refresh -= delta
	var start := actor.global_position
	var direct := destination - start
	direct.y = 0
	var space := actor.get_world_3d().direct_space_state
	var probe := PhysicsShapeQueryParameters3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.6
	probe.shape = capsule
	probe.exclude = [actor.get_rid(), actor.game.player.get_rid()]
	probe.transform = Transform3D(Basis.IDENTITY, start + Vector3.UP * 0.95)
	probe.motion = direct
	if space.cast_motion(probe)[0] >= 1.0:
		route.clear()
		return direct.normalized()
	if refresh <= 0:
		refresh = 2.0
		var grid := AStarGrid2D.new()
		grid.region = Rect2i(-24,-24,49,49)
		grid.cell_size = Vector2.ONE
		grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
		grid.update()
		probe.motion = Vector3.ZERO
		for x in range(-24,25):
			for z in range(-24,25):
				probe.transform.origin = start + Vector3(x,0.95,z)
				grid.set_point_solid(Vector2i(x,z), not space.intersect_shape(probe,1).is_empty())
		grid.set_point_solid(Vector2i.ZERO,false)
		var goal := Vector2i(clampi(roundi(direct.x),-24,24),clampi(roundi(direct.z),-24,24))
		route.clear()
		for point in grid.get_id_path(Vector2i.ZERO,goal,true):
			route.append(start + Vector3(point.x,0,point.y))
	while not route.is_empty() and start.distance_to(route[0]) < 0.65:
		route.remove_at(0)
	if route.is_empty(): return Vector3.ZERO
	var offset := route[0] - start
	offset.y = 0
	return offset.normalized()
