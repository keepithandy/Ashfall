extends "res://scripts/authoring/house_builder.gd"

func build_variant(index: int) -> Node3D:
	root = Node3D.new()
	root.name = ["OchreWorkersHouse", "GreenLonghouse", "WhiteGardenHouse"][index]
	masonry = scanned("rough_plaster_brick_02", 1.5, Color("9b8875"))
	plaster = scanned("grey_plaster", 1.4, [Color("c8b281"), Color("8c9a83"), Color("d0cdc0")][index])
	timber = load("res://assets/props/wood.tres").duplicate()
	timber.albedo_color = [Color("655447"), Color("52716a"), Color("7a5150")][index]
	concrete = load("res://assets/props/concrete.tres")
	iron = load("res://assets/props/iron.tres")
	var wood: Material = load("res://assets/props/wood.tres")
	var width: float = [8.0, 12.0, 9.0][index]
	var depth: float = [8.0, 7.0, 10.0][index]
	box("Foundation", Vector3(0,-0.02,0), Vector3(width+0.3,0.28,depth+0.3), concrete,true)
	box("Floorboards", Vector3(0,0.14,0), Vector3(width,0.04,depth),wood,true)
	var front := wall("Front",Vector3(0,0,depth/2),width,[Rect2(-0.8,0.14,1.6,2.35),Rect2(-3.08,1.12,1.56,1.46),Rect2(1.52,1.12,1.56,1.46)],0)
	window_frame(front,Vector2(-2.3,1.85))
	window_frame(front,Vector2(2.3,1.85))
	for side in [-1,1]:
		var face := wall("Side",Vector3(side*width/2,0,0),depth,[Rect2(-0.78,1.12,1.56,1.46)],side*PI/2)
		window_frame(face,Vector2(0,1.85))
	wall("Rear",Vector3(0,0,-depth/2),width,[Rect2(-0.8,0.14,1.6,2.35)],PI)
	for z in [-depth/2,depth/2]:
		for x in [-0.85,0.85]:
			box("DoorJamb",Vector3(x,1.35,z),Vector3(0.1,2.42,0.4),timber,true)
		box("DoorHeader",Vector3(0,2.54,z),Vector3(1.8,0.13,0.4),timber)
		var ramp := box("ThresholdRamp",Vector3(0,0.04,z+signf(z)*0.6),Vector3(1.7,0.1,1.2),concrete,true)
		ramp.rotation.x = signf(z)*0.1
	# A clear central hall links both exits; doorways lead into side rooms.
	for side in [-1,1]:
		for z in [-depth/4,depth/4]:
			box("HallPartition",Vector3(side*1.4,1.55,z),Vector3(0.15,2.8,depth/2-1.5),plaster,true)
		box("RoomDoorHeader",Vector3(side*1.4,2.75,0),Vector3(0.15,0.4,1.5),timber,true)
	box("Ceiling",Vector3(0,3.13,0),Vector3(width,0.12,depth),plaster)
	var rise := 1.6
	var half := width/2+0.4
	for side in [-1,1]:
		var roof := box("PitchedRoof",Vector3(side*half/2,3.2+rise/2,0),Vector3(sqrt(half*half+rise*rise),0.14,depth+0.8),iron)
		roof.rotation.z = -side*atan2(rise,half)
	for z in [-depth/2,depth/2]:
		polygon("Gable",PackedVector2Array([Vector2(-width/2,3.15),Vector2(width/2,3.15),Vector2(0,4.8)]),Vector3(0,0,z),plaster)
	box("RidgeCap",Vector3(0,4.82,0),Vector3(0.2,0.16,depth+0.85),iron)
	box("BrickChimney",Vector3(-width/2+1,4.1,-depth/4),Vector3(0.6,2.2,0.65),masonry)
	box("ChimneyCap",Vector3(-width/2+1,5.25,-depth/4),Vector3(0.8,0.15,0.85),concrete)
	var porch_width: float = [3.0,8.0,4.0][index]
	box("PorchCanopy",Vector3(0,2.8,depth/2+1),Vector3(porch_width,0.13,2.3),iron)
	for x in [-porch_width/2+0.15,porch_width/2-0.15]:
		box("PorchPost",Vector3(x,1.4,depth/2+1.9),Vector3(0.14,2.8,0.14),timber,true)
	for entry in [["wooden_bench",Vector3(2.3,0.17,depth/2-1.3)],["field_cot",Vector3(-width/2+1.2,0.17,-depth/4)],["shelving_unit",Vector3(width/2-0.7,0.17,-depth/4)],["radiator",Vector3(-width/2+0.5,0.17,1.7)]]:
		var item := (load("res://scenes/props/"+entry[0]+".tscn") as PackedScene).instantiate() as Node3D
		root.add_child(item)
		item.position = entry[1]
	return root
