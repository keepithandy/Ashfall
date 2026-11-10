extends "res://scripts/review/hand_grip_review.gd"
## Uses the actual avatar, item profiles and transitions in an isolated viewport.
func _ready() -> void:
	super._ready()
	label.get_parent().hide()
	camera.size=0.35
func _unhandled_input(_event: InputEvent) -> void:
	pass
func isolate_hand() -> void:
	super.isolate_hand()
	# Flatten only the diagnostic mesh's cut edge. The gameplay body is intact.
	var body: MeshInstance3D=character.model.find_child("MaleMannequinBody",true,false)
	var wrist: Vector3=character.profile_vector("wrist_rest")
	var elbow: Vector3=character.skeleton.get_bone_global_rest(character.skeleton.find_bone("forearm.R")).origin
	var axis := (elbow-wrist).normalized()
	var mesh := ArrayMesh.new()
	for surface in range(body.mesh.get_surface_count()):
		var arrays := body.mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
		var edges := {}
		for i in range(0,indices.size(),3):
			for pair in [[indices[i],indices[i+1]],[indices[i+1],indices[i+2]],[indices[i+2],indices[i]]]:
				var edge := Vector2i(mini(pair[0],pair[1]),maxi(pair[0],pair[1]))
				edges[edge]=edges.get(edge,0)+1
		var boundary := {}
		for edge in edges:
			if edges[edge]==1:boundary[edge.x]=true;boundary[edge.y]=true
		for i in boundary:
			if (vertices[i]-wrist).dot(axis)>.13:
				vertices[i]+=axis*(.185-(vertices[i]-wrist).dot(axis))
		arrays[Mesh.ARRAY_VERTEX]=vertices
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		mesh.surface_set_material(mesh.get_surface_count()-1,body.get_active_material(surface))
	body.mesh=mesh
func select_item(id: String) -> void:
	equip(ItemCatalog.grip(id))
func orbit(event: InputEvent) -> void:
	if event is InputEventMouseMotion and (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)):
		angle-=event.relative.x*0.007
		elevation=clampf(elevation+event.relative.y*0.007,-1.2,1.2)
	if event is InputEventMouseButton and event.pressed:
		if event.button_index==MOUSE_BUTTON_WHEEL_UP:camera.size=maxf(0.16,camera.size*0.9)
		if event.button_index==MOUSE_BUTTON_WHEEL_DOWN:camera.size=minf(0.65,camera.size*1.1)
