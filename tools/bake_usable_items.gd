extends SceneTree
var builder
var metal: Material
var dark: Material
var olive: Material
var paper: Material
func _initialize() -> void:call_deferred("build")
func lathe(name: String,profile: Array,mat: Material) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in range(profile.size()-1):
		for i in range(64):
			# Godot uses clockwise front faces. Keep the outer shell visible.
			for p in [[j,i],[j,i+1],[j+1,i],[j,i+1],[j+1,i+1],[j+1,i]]:
				var a: float=p[1]*TAU/64.0
				var row: int=p[0]
				var shape: Vector2=profile[row]
				var tangent: Vector2=profile[mini(row+1,profile.size()-1)]-profile[maxi(row-1,0)]
				st.set_normal(Vector3(tangent.y*cos(a),-tangent.x,tangent.y*sin(a)).normalized())
				st.set_uv(Vector2(p[1]/64.0,float(row)/profile.size()))
				st.add_vertex(Vector3(shape.x*cos(a),shape.y,shape.x*sin(a)))
	var mesh := MeshInstance3D.new()
	mesh.name=name;mesh.mesh=st.commit();mesh.material_override=mat
	builder.root.add_child(mesh)
func rings(y_values: Array,radius: float,mat: Material) -> void:
	for y in y_values:builder.ring("Machined seam",Vector3(0,y,0),radius,0.0012,mat)
func build() -> void:
	builder=load("res://scripts/authoring/prop_builder.gd").new()
	metal=builder.plain(Color("727c77"),0.38,0.75)
	dark=builder.plain(Color("202923"),0.8)
	olive=load("res://assets/props/olive.tres")
	paper=builder.plain(Color("c6c1a9"),0.85)
	DirAccess.make_dir_recursive_absolute("res://scenes/items")
	for id in ["bandage","batteries","water_bottle","antiseptic","detector","field_radio"]:
		var root := Node3D.new();root.name=id.to_pascal_case()
		var model := Node3D.new();model.name="Model";root.add_child(model)
		builder.root=model
		if id=="bandage" or id=="batteries":
			var old: Node3D=load("res://scenes/loot/"+id+".tscn").instantiate()
			# Bake a standalone prop: packing overridden inherited children would
			# instantiate a second set and leave the replaced originals orphaned.
			old.scene_file_path=""
			model.add_child(old)
			if id=="bandage":
				old.rotation.y=PI/2;old.position.y=-0.045
			else:
				old.rotation.x=-PI/2;old.scale=Vector3.ONE*0.8;old.position.z=0.057*0.8
		else:
			model.rotation.x=-PI/2
			match id:
				"water_bottle":
					lathe("Curved flask",[Vector2(0,-.105),Vector2(.024,-.105),Vector2(.030,-.101),Vector2(.032,-.087),Vector2(.032,.035),Vector2(.030,.048),Vector2(.022,.067),Vector2(.013,.074),Vector2(.013,.092),Vector2(0,.092)],olive)
					rings([-.085,-.065,.012,.032],.0325,metal)
					builder.pipe("Screw cap",Vector3(0,.086,0),Vector3(0,.103,0),.017,dark)
					rings([.089,.094,.099],.017,metal)
					builder.b("Faded blank label",Vector3(0,-.022,-.031),Vector3(.030,.044,.002),paper,.002)
				"antiseptic":
					var amber: Material = builder.plain(Color("69452c"),.28)
					lathe("Amber medicine bottle",[Vector2(0,-.063),Vector2(.020,-.063),Vector2(.024,-.058),Vector2(.024,.033),Vector2(.022,.043),Vector2(.012,.054),Vector2(.012,.064),Vector2(0,.064)],amber)
					builder.pipe("Ribbed white cap",Vector3(0,.054,0),Vector3(0,.075,0),.015,paper)
					builder.b("Medical cross upright",Vector3(0,-.008,-.025),Vector3(.006,.033,.002),paper,.001)
					builder.b("Medical cross bar",Vector3(0,-.008,-.025),Vector3(.022,.006,.002),paper,.001)
					rings([.057,.061,.065,.069,.073],.015,dark)
				"detector":
					lathe("Rugged sensor body",[Vector2(0,-.075),Vector2(.026,-.075),Vector2(.031,-.069),Vector2(.031,.066),Vector2(.027,.075),Vector2(0,.075)],olive)
					rings([-.067,-.050,.050,.066],.0315,dark)
					builder.b("Meter housing",Vector3(0,.018,-.030),Vector3(.043,.048,.012),dark,.004)
					builder.b("Meter face",Vector3(0,.018,-.037),Vector3(.034,.037,.002),paper,.002)
					var needle: MeshInstance3D=builder.b("Gauge needle",Vector3(0,.018,-.039),Vector3(.002,.028,.002),dark,.0004)
					needle.rotation.z=.5
					builder.pipe("Sensor probe",Vector3(0,.073,0),Vector3(0,.113,0),.005,metal)
					builder.pipe("Side control",Vector3(.027,.049,0),Vector3(.038,.049,0),.008,dark)
				"field_radio":
					builder.b("Beveled receiver",Vector3.ZERO,Vector3(.060,.130,.038),olive,.008)
					builder.b("Front inset",Vector3(0,.007,-.021),Vector3(.048,.104,.005),dark,.004)
					builder.b("Tuning scale",Vector3(0,.035,-.025),Vector3(.038,.024,.003),paper,.002)
					builder.b("Tuning needle",Vector3(.008,.035,-.027),Vector3(.0015,.018,.002),dark,.0003)
					for i in range(7):builder.b("Speaker grille",Vector3(0,-.005-i*.006,-.025),Vector3(.038,.002,.003),metal,.0005)
					builder.pipe("Tuning dial",Vector3(-.017,.063,0),Vector3(-.017,.077,0),.008,dark)
					builder.pipe("Antenna",Vector3(.018,.065,0),Vector3(.018,.160,0),.0025,metal)
					builder.pipe("Antenna base",Vector3(.018,.061,0),Vector3(.018,.079,0),.006,dark)
		for mesh: MeshInstance3D in root.find_children("*","MeshInstance3D",true,false):
			if mesh.mesh is CylinderMesh:mesh.mesh.radial_segments=64
			if mesh.mesh is TorusMesh:mesh.mesh.rings=64;mesh.mesh.ring_segments=12
		for node in root.find_children("*","Node",true,false):node.owner=root
		var packed := PackedScene.new()
		assert(packed.pack(root)==OK)
		assert(ResourceSaver.save(packed,"res://scenes/items/held_"+id+".tscn")==OK)
		root.free()
	print("USABLE_ITEM_MODELS_BAKED: six held models")
	quit()
