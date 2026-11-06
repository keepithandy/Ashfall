extends SceneTree

func _initialize() -> void:
	var builder=load("res://workshop_prop_builder.gd").new()
	builder.prepare_workshop_materials()
	DirAccess.make_dir_recursive_absolute("res://scenes/loot")
	for item in ["bandage", "food_tin", "batteries"]:
		builder.root=Node3D.new()
		builder.root.name=item.capitalize().replace("_", "")
		var cloth=builder.plain(Color("bcb39b"))
		var dark_cloth=builder.plain(Color("8a7d68"))
		if item=="bandage":
			builder.pipe("WrappedCotton",Vector3(-0.065,0.045,0),Vector3(0.065,0.045,0),0.044,cloth)
			for x in [-0.048,-0.024,0.0,0.024,0.048]:
				var seam=builder.ring("ClothWrapSeam",Vector3(x,0.045,0),0.044,0.0015,dark_cloth)
				seam.rotation.z=PI/2
			for side in [-1,1]:
				builder.pipe("RollCore",Vector3(side*0.065,0.045,0),Vector3(side*0.068,0.045,0),0.011,dark_cloth)
				for radius in [0.018,0.03]:
					var layer=builder.ring("ClothEndLayer",Vector3(side*0.066,0.045,0),radius,0.001,cloth)
					layer.rotation.z=PI/2
			builder.b("ClothTail",Vector3(0,0.012,0.05),Vector3(0.12,0.012,0.06),cloth,0.003)
		elif item=="food_tin":
			builder.pipe("TinBody",Vector3(0,0.012,0),Vector3(0,0.13,0),0.046,builder.olive)
			for y in [0.013,0.021,0.12,0.131]:
				builder.ring("RolledMetalRim",Vector3(0,y,0),0.046,0.003,builder.iron)
			builder.pipe("TinLid",Vector3(0,0.131,0),Vector3(0,0.134,0),0.042,builder.iron)
			builder.b("CorrodedPatch",Vector3(0.023,0.073,0.039),Vector3(0.024,0.04,0.002),builder.rust,0.001)
		else:
			for x in [-0.026,0.026]:
				builder.pipe("BatteryCasing",Vector3(x,0.008,0),Vector3(x,0.095,0),0.022,builder.rubber)
				builder.pipe("BatteryCap",Vector3(x,0.095,0),Vector3(x,0.101,0),0.021,builder.iron)
				builder.pipe("PositiveTerminal",Vector3(x,0.101,0),Vector3(x,0.106,0),0.007,builder.iron)
				builder.b("FadedBand",Vector3(x,0.05,0.021),Vector3(0.031,0.025,0.002),builder.olive,0.001)
		for child in builder.root.get_children():
			child.owner=builder.root
		var packed=PackedScene.new()
		if packed.pack(builder.root)!=OK or ResourceSaver.save(packed,"res://scenes/loot/"+item+".tscn")!=OK:
			push_error("Could not save loot model "+item)
			quit(1)
			return
		builder.root.free()
	print("LOOT_MODELS_BAKED: bandage, food tin, batteries")
	quit()
