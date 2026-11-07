extends "res://workshop_prop_builder.gd"
## A separate residential cottage; existing house and prop scenes are not rebuilt.

func build_cottage() -> Node3D:
	prepare_workshop_materials()
	rng.seed=7614
	root=Node3D.new()
	root.name="BluePorchCottage"
	concrete=load("res://assets/props/concrete.tres")
	masonry=scanned("rough_plaster_brick_02",1.5,Color("b8ada0"))
	plaster=scanned("grey_plaster",1.0,Color("e1d6ba"))
	timber=load("res://assets/props/wood.tres").duplicate()
	timber.albedo_color=Color("7cabb6")
	var floor_wood: Material=load("res://assets/props/wood.tres")
	var slate:=scanned("concrete_floor_worn_001",1.1,Color("68605b"))
	box("BrickFooting",Vector3(0,-0.01,0),Vector3(8.25,0.3,7.25),masonry,true)
	box("TimberFloor",Vector3(0,0.15,0),Vector3(7.98,0.06,6.98),floor_wood,true)
	var front:=wall("CottageFront",Vector3(0,0,3.5),8,[Rect2(-3.08,1.12,1.56,1.46),Rect2(-0.62,0.14,1.24,2.3),Rect2(1.52,1.12,1.56,1.46)],0)
	window_frame(front,Vector2(-2.3,1.85))
	window_frame(front,Vector2(2.3,1.85),true)
	var east:=wall("CottageEast",Vector3(4,0,0),7,[Rect2(-2.38,1.12,1.56,1.46),Rect2(0.62,1.12,1.56,1.46)],PI/2)
	window_frame(east,Vector2(-1.6,1.85))
	window_frame(east,Vector2(1.4,1.85))
	var west:=wall("CottageWest",Vector3(-4,0,0),7,[Rect2(-0.78,1.12,1.56,1.46)],-PI/2)
	window_frame(west,Vector2(0,1.85),true)
	wall("CottageRear",Vector3(0,0,-3.5),8,[],PI)
	# Blue timber trim and gable infill distinguish the cottage from the checkpoint.
	for x in [-4.08,4.08]:
		box("PaintedCornerBoard",Vector3(x,1.66,3.57),Vector3(0.15,2.98,0.1),timber)
	for z in [-3.52,3.52]:
		var gable:=polygon("BlueTimberGable",PackedVector2Array([Vector2(-4.1,3.13),Vector2(4.1,3.13),Vector2(0,5.02)]),Vector3(0,0,z),timber)
		if z<0:
			gable.rotation.y=PI
		for row in range(10):
			var y:=3.23+row*0.17
			var width: float=(5.02-y)/0.46*2
			box("GableBoardJoint",Vector3(0,y,z+0.008*signf(z)),Vector3(width,0.015,0.012),floor_wood)
	var tiles: Array[MeshInstance3D]=[]
	for side in [-1,1]:
		for row in range(8):
			for col in range(14):
				var x: float=side*(row+0.5)*0.55
				var z: float=-3.58+col*0.55+(0.06 if row%2 else 0.0)
				# Raised courses shed over the next row; narrow joints reveal each slate.
				var tile:=b("WeatheredRoofSlate",Vector3(x,5.07-absf(x)*0.44+(8-row)*0.012,z),Vector3(0.65,0.045,0.525),slate,0.006)
				tile.rotation.z=-side*atan(0.44)
				tiles.append(tile)
	var roof_tool:=SurfaceTool.new()
	roof_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for tile in tiles:
		roof_tool.append_from(tile.mesh,0,tile.transform)
	var roof:=MeshInstance3D.new()
	roof.name="OverlappingSlateRoof"
	roof.mesh=roof_tool.commit()
	roof.material_override=slate
	root.add_child(roof)
	for tile in tiles:
		tile.free()
	for side in [-1,1]:
		beam("GableBargeboard",Vector3(0,5.1,3.95),Vector3(side*4.5,3.1,3.95),0.12,timber)
		box("EavesBoard",Vector3(side*4.4,3.08,0),Vector3(0.12,0.18,7.95),timber)
	pipe("RidgeFlashing",Vector3(0,5.12,-3.9),Vector3(0,5.12,4.0),0.075,iron)
	box("Ceiling",Vector3(0,3.06,0),Vector3(7.66,0.08,6.66),plaster,true)
	# Covered porch, with a gentle approach that can be walked up.
	var deck:=box("PorchDeck",Vector3(0,0.12,4.25),Vector3(3.05,0.12,1.65),floor_wood,true)
	for child in deck.get_children():
		if child is CollisionShape3D:
			child.position.y=0.02
	for x in [-1.35,1.35]:
		box("PorchPost",Vector3(x,1.42,4.92),Vector3(0.13,2.8,0.13),timber,true)
		box("PorchSideRail",Vector3(x,0.97,4.25),Vector3(0.08,0.09,1.4),timber)
		for z in [3.7,4.0,4.3,4.6]:
			box("PorchSpindle",Vector3(x,0.64,z),Vector3(0.04,0.6,0.04),timber)
	var porch_roof:=box("PorchCanopy",Vector3(0,2.85,4.25),Vector3(3.4,0.09,2.1),slate)
	porch_roof.rotation.x=0.14
	box("PorchFrontBeam",Vector3(0,2.7,4.97),Vector3(3.15,0.16,0.14),timber)
	var ramp:=box("WalkablePorchApproach",Vector3(0,0.07,5.6),Vector3(1.65,0.1,1.75),concrete,true)
	ramp.rotation.x=0.105
	for x in [-0.66,0.66]:
		box("DoorFrame",Vector3(x,1.29,3.55),Vector3(0.1,2.3,0.27),timber,true)
	box("DoorFrameHead",Vector3(0,2.47,3.55),Vector3(1.4,0.1,0.27),timber)
	var door:=box("OpenBlueDoor",Vector3(-1.09,1.26,3.93),Vector3(1.1,2.16,0.055),timber,true)
	door.rotation.y=-1.2
	# The partition leaves a full-height opening to the sleeping room.
	box("InteriorPartitionLeft",Vector3(-1.7,1.47,-0.6),Vector3(4.6,2.6,0.15),plaster,true)
	box("InteriorPartitionRight",Vector3(2.8,1.47,-0.6),Vector3(2.4,2.6,0.15),plaster,true)
	box("InteriorDoorHeader",Vector3(1.1,2.59,-0.6),Vector3(1.0,0.35,0.15),timber,true)
	# Stove and chimney are architecture, not interactive props yet.
	box("CastIronStove",Vector3(-2.8,0.62,0.4),Vector3(0.65,0.86,0.6),rubber,true)
	box("StoveDoor",Vector3(-2.8,0.65,0.72),Vector3(0.4,0.43,0.025),iron)
	pipe("Stovepipe",Vector3(-2.8,1.04,0.4),Vector3(-2.8,3.2,0.4),0.065,iron)
	box("BrickChimney",Vector3(-2.8,4.35,0.4),Vector3(0.6,2.1,0.62),masonry)
	box("ChimneyCap",Vector3(-2.8,5.43,0.4),Vector3(0.78,0.12,0.8),concrete)
	box("ChimneyOpening",Vector3(-2.8,5.495,0.4),Vector3(0.42,0.01,0.42),rubber)
	var interior_light:=OmniLight3D.new()
	interior_light.name="DimCottageLamp"
	interior_light.position=Vector3(1,2.55,1.4)
	interior_light.light_color=Color("e8b876")
	interior_light.light_energy=0.7
	interior_light.omni_range=7
	interior_light.shadow_enabled=true
	root.add_child(interior_light)
	var furnishings:=[
		["res://scenes/props/field_cot.tscn",Vector3(-2.3,0.18,-2.0),PI/2],
		["res://scenes/props/worn_mattress.tscn",Vector3(-2.3,0.63,-2.0),PI/2],
		["res://scenes/props/wooden_bench.tscn",Vector3(2.55,0.18,-2.8),0.0],
		["res://scenes/workshop/metal_chair.tscn",Vector3(2.45,0.18,1.6),0.2],
		["res://scenes/workshop/open_wood_crate.tscn",Vector3(3,0.18,0.1),0.0],
		["res://scenes/props/metal_bucket.tscn",Vector3(-3.2,0.18,2.5),0.0]
	]
	for p in furnishings:
		var prop: Node3D=load(p[0]).instantiate()
		prop.position=p[1]
		prop.rotation.y=p[2]
		root.add_child(prop)
	root.set_meta("house_type","Blue porch cottage")
	root.set_meta("approximate_size_metres",Vector3(9,5.5,12))
	root.set_meta("world_text_policy","No attached text")
	if ResourceLoader.exists("res://scenes/houses/cottage_detail.tscn"):
		root.add_child(load("res://scenes/houses/cottage_detail.tscn").instantiate())
	return root
