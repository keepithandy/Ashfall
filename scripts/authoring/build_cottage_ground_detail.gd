extends SceneTree
## Builds only the new terrain and cottage-detail scenes; never rewrites the world.

func _initialize() -> void:
	call_deferred("build")

func save_scene(node: Node, path: String) -> bool:
	assign_owner(node,node)
	var packed:=PackedScene.new()
	if packed.pack(node)!=OK:
		return false
	return ResourceSaver.save(packed,path)==OK

func assign_owner(node: Node, root: Node) -> void:
	for child in node.get_children():
		child.owner=root
		assign_owner(child,root)

func distance_to_rect(p: Vector2, area: Rect2) -> float:
	var dx:=maxf(maxf(area.position.x-p.x,0),p.x-area.end.x)
	var dy:=maxf(maxf(area.position.y-p.y,0),p.y-area.end.y)
	return Vector2(dx,dy).length()

func ground_height(x: float, z: float, noise: FastNoiseLite) -> float:
	var p:=Vector2(x,z)
	var protected:=[Rect2(-33,-54,66,87),Rect2(-51.5,3,11,12.5),Rect2(-63,18,34,4),Rect2(-47.7,12,3.4,10),Rect2(-61.7,-20,3.4,51)]
	var factor:=1.0
	for area in protected:
		factor=minf(factor,smoothstep(0.0,3.0,distance_to_rect(p,area)))
	return -0.045*factor*(0.55+0.45*noise.get_noise_2d(x,z))

func build_terrain() -> bool:
	var terrain:=StaticBody3D.new()
	terrain.name="NaturalGround"
	terrain.set_meta("editable_note","Move the ground as one object; the mesh and collision are children.")
	var noise:=FastNoiseLite.new()
	noise.seed=7183
	noise.frequency=0.095
	var nx:=180
	var nz:=200
	var vertices:=PackedVector3Array()
	var normals:=PackedVector3Array()
	var uvs:=PackedVector2Array()
	var indices:=PackedInt32Array()
	for z in range(nz+1):
		for x in range(nx+1):
			var wx:=float(x)-90.0
			var wz:=float(z)-110.0
			var h:=ground_height(wx,wz,noise)
			vertices.append(Vector3(wx,h,wz))
			var hx:=ground_height(wx-0.5,wz,noise)-ground_height(wx+0.5,wz,noise)
			var hz:=ground_height(wx,wz-0.5,noise)-ground_height(wx,wz+0.5,noise)
			normals.append(Vector3(hx,1,hz).normalized())
			uvs.append(Vector2(wx/2.0,wz/2.0))
	for z in range(nz):
		for x in range(nx):
			var a:=z*(nx+1)+x
			var b:=a+1
			var c:=a+nx+1
			var d:=c+1
			indices.append_array(PackedInt32Array([a,b,c,b,d,c]))
	var arrays:=[]
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices
	arrays[Mesh.ARRAY_NORMAL]=normals
	arrays[Mesh.ARRAY_TEX_UV]=uvs
	arrays[Mesh.ARRAY_INDEX]=indices
	var mesh:=ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var tangents:=SurfaceTool.new()
	tangents.create_from(mesh,0)
	tangents.generate_tangents()
	mesh=tangents.commit()
	var material:=StandardMaterial3D.new()
	material.albedo_texture=load("res://assets/materials/forest_ground_05/albedo.jpg")
	material.albedo_color=Color("b8b3a4")
	material.roughness_texture=load("res://assets/materials/forest_ground_05/roughness.jpg")
	material.roughness_texture_channel=BaseMaterial3D.TEXTURE_CHANNEL_RED
	material.normal_enabled=true
	material.normal_texture=load("res://assets/materials/forest_ground_05/normal.jpg")
	material.normal_scale=0.6
	material.ao_enabled=true
	material.ao_texture=load("res://assets/materials/forest_ground_05/ao.jpg")
	material.ao_light_affect=0.35
	material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	var visual:=MeshInstance3D.new()
	visual.name="TerrainMesh"
	visual.mesh=mesh
	visual.material_override=material
	terrain.add_child(visual)
	var collision:=CollisionShape3D.new()
	collision.name="TerrainCollision"
	collision.shape=mesh.create_trimesh_shape()
	terrain.add_child(collision)
	var ok:=save_scene(terrain,"res://scenes/natural_ground.tscn")
	terrain.free()
	print("TERRAIN_VERTICES: ",vertices.size()," TRIANGLES: ",indices.size()/3)
	return ok

func merge_details(builder: RefCounted, nodes: Array[MeshInstance3D], label: String, material: Material) -> void:
	if nodes.is_empty():
		return
	var surface:=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for node in nodes:
		surface.append_from(node.mesh,0,node.transform)
	var batch:=MeshInstance3D.new()
	batch.name=label
	batch.mesh=surface.commit()
	batch.material_override=material
	builder.root.add_child(batch)
	for node in nodes:
		node.free()

func build_cottage_details() -> bool:
	var builder=load("res://scripts/authoring/workshop_prop_builder.gd").new()
	builder.prepare_workshop_materials()
	var root:=Node3D.new()
	root.name="CottageDetail"
	builder.root=root
	var random:=RandomNumberGenerator.new()
	random.seed=18422
	var brick=builder.scanned("rough_plaster_brick_02",0.8,Color("a19888"))
	var wood: StandardMaterial3D=load("res://assets/props/wood.tres").duplicate()
	wood.albedo_color=Color("86a8a5")
	var old_wood: Material=load("res://assets/props/wood.tres")
	var iron: Material=load("res://assets/props/iron.tres")
	var roof=builder.scanned("concrete_floor_worn_001",0.8,Color("77716b"))
	var bricks: Array[MeshInstance3D]=[]
	# Recessed, broken-out masonry at the foot of the front and side walls.
	for face in [0,1]:
		for row in range(5):
			for col in range(28):
				if random.randf()<0.16:
					continue
				var t: float=-3.8+col*0.275+(0.13 if row%2 else 0.0)
				if t>3.84 or (face==0 and absf(t)<0.79):
					continue
				var y: float=0.23+row*0.115+random.randf_range(-0.004,0.004)
				var length: float=random.randf_range(0.22,0.255)
				var n: MeshInstance3D
				if face==0:
					n=builder.b("Brick",Vector3(t,y,3.684+random.randf_range(0,0.008)),Vector3(length,0.098,0.025),brick,0.005)
				else:
					if absf(t)>3.28:
						continue
					n=builder.b("Brick",Vector3(4.184+random.randf_range(0,0.008),y,t),Vector3(0.025,0.098,length),brick,0.005)
				bricks.append(n)
	merge_details(builder,bricks,"IndividuallyWeatheredBricks",brick)
	# Shallow, bevelled painted boards and trim catch real light around windows.
	for center in [-2.3,2.3]:
		for side in [-1,1]:
			builder.b("FrontWindowSideTrim",Vector3(center+side*0.82,1.85,3.705),Vector3(0.075,1.62,0.055),wood,0.01)
		builder.b("FrontWindowCrown",Vector3(center,2.67,3.71),Vector3(1.82,0.09,0.065),wood,0.01)
		builder.b("FrontWindowApron",Vector3(center,1.0,3.71),Vector3(1.74,0.13,0.045),wood,0.008)
	for z in [-1.6,1.4]:
		for side in [-1,1]:
			builder.b("SideWindowTrim",Vector3(4.205,1.85,z+side*0.82),Vector3(0.055,1.62,0.075),wood,0.01)
		builder.b("SideWindowCrown",Vector3(4.21,2.67,z),Vector3(0.065,0.09,1.82),wood,0.01)
		builder.b("SideWindowApron",Vector3(4.21,1.0,z),Vector3(0.045,0.13,1.74),wood,0.008)
	# Visible individual gable planks with realistic shadow gaps.
	for row in range(10):
		var y:=3.23+row*0.17
		var width: float=clampf((5.02-y)/0.46*2-0.08,0,8)
		builder.b("GablePlank",Vector3(0,y,3.546),Vector3(width,0.148,0.035),wood,0.006)
	for side in [-1,1]:
		builder.pipe("RainGutter",Vector3(side*4.43,3.04,-3.9),Vector3(side*4.43,3.04,3.9),0.055,iron)
		for z in [-3,-1,1,3]:
			builder.b("GutterBracket",Vector3(side*4.43,3.04,z),Vector3(0.13,0.09,0.035),iron,0.004)
	builder.pipe("RainDownpipe",Vector3(4.36,3.04,-3.35),Vector3(4.36,0.35,-3.35),0.045,iron)
	for y in [0.65,1.7,2.65]:
		builder.b("DownpipeClip",Vector3(4.31,y,-3.35),Vector3(0.1,0.055,0.14),iron,0.004)
	# Thin planks and rafters sit on the existing walkable porch and canopy.
	for i in range(9):
		builder.b("PorchDeckPlank",Vector3(-1.34+i*0.335,0.191,4.25),Vector3(0.315,0.018,1.55),old_wood,0.004)
	for x in [-1.35,-0.7,0,0.7,1.35]:
		builder.beam("PorchRoofRafter",Vector3(x,2.94,3.35),Vector3(x,2.68,5.13),0.055,wood)
	for i in range(17):
		var z: float=-3.8+i*0.475
		builder.b("RidgeCap",Vector3(0,5.18,z),Vector3(0.25,0.075,0.455),roof,0.008)
	var ok:=save_scene(root,"res://scenes/houses/cottage_detail.tscn")
	root.free()
	return ok

func build() -> void:
	if not build_terrain() or not build_cottage_details():
		push_error("Failed to create cottage or terrain scenes")
		quit(1)
		return
	print("COTTAGE_AND_TERRAIN_CREATED")
	quit()
