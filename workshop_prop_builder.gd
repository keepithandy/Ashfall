extends "res://natural_prop_builder.gd"
## Additional original props. Shares helpers/materials; does not rebuild older assets.
const WORKSHOP_CATALOG := {
	"discarded_tyre":Vector3(0.245,0.695,0.695),
	"workbench_vise":Vector3(1.5,1.12,0.7),
	"wheelbarrow":Vector3(0.85,0.72,1.65),
	"steel_ladder":Vector3(0.52,2.3,0.12),
	"fire_extinguisher":Vector3(0.23,0.61,0.22),
	"open_wood_crate":Vector3(0.7,0.44,0.52),
	"coiled_hose":Vector3(0.7,0.09,0.7),
	"metal_chair":Vector3(0.5,0.92,0.55)
}

func prepare_workshop_materials() -> void:
	var folder := "res://assets/props/"
	timber=load(folder+"wood.tres")
	iron=load(folder+"iron.tres")
	rust=load(folder+"rust.tres")
	olive=load(folder+"olive.tres")
	red=load(folder+"red.tres")
	blue=load(folder+"blue.tres")
	rubber=load(folder+"rubber.tres")
	enamel=load(folder+"enamel.tres")
	endgrain=load("res://assets/nature/endgrain.tres")

func tyre(at: Vector3, radius: float, width: float, tread: bool = true) -> void:
	var mesh := ring("RubberTyre",at,radius*0.74,radius*0.26,rubber)
	mesh.rotation.z=PI/2
	mesh.scale.y=width/(radius*0.52)
	for side in [-1,1]:
		var bead := ring("TyreBead",at+Vector3(side*width*0.45,0,0),radius*0.52,0.009,rubber)
		bead.rotation.z=PI/2
	if tread:
		for i in range(42):
			var a := i*TAU/42
			var block := b("TreadBlock",at+Vector3(0,sin(a)*radius*0.98,cos(a)*radius*0.98),Vector3(width*0.93,0.018,radius*0.15),rubber,0.003)
			block.rotation.x=PI/2-a

func discarded_tyre() -> void:
	var material:=ShaderMaterial.new()
	material.shader=load("res://assets/workshop/worn_tyre.gdshader")
	rubber=material
	# Closed rubber cross-section: outside sidewalls and crown, bead lips,
	# then the recessed inner liner. Rotation axis is X, as in the original asset.
	var profile:=PackedVector2Array([
		Vector2(0.095,0.198),Vector2(0.111,0.2),Vector2(0.115,0.215),
		Vector2(0.12,0.25),Vector2(0.113,0.293),Vector2(0.098,0.323),
		Vector2(0.082,0.334),Vector2(0.045,0.338),Vector2(-0.045,0.338),
		Vector2(-0.082,0.334),Vector2(-0.098,0.323),Vector2(-0.113,0.293),
		Vector2(-0.12,0.25),Vector2(-0.115,0.215),Vector2(-0.111,0.2),
		Vector2(-0.095,0.198),Vector2(-0.086,0.211),Vector2(-0.085,0.262),
		Vector2(-0.07,0.306),Vector2(0.07,0.306),Vector2(0.085,0.262),Vector2(0.086,0.211)
	])
	var surface:=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for segment in range(144):
		for j in range(profile.size()):
			var next: int=(j+1)%profile.size()
			for data in [Vector2i(segment,j),Vector2i(segment+1,next),Vector2i(segment+1,j),Vector2i(segment,j),Vector2i(segment,next),Vector2i(segment+1,next)]:
				var angle: float=data.x*TAU/144
				var p: Vector2=profile[data.y]
				var tangent: Vector2=(profile[(data.y+1)%profile.size()]-profile[(data.y+profile.size()-1)%profile.size()]).normalized()
				surface.set_normal(Vector3(tangent.y,-tangent.x*sin(angle),-tangent.x*cos(angle)))
				surface.set_uv(Vector2(float(data.x)/144,float(data.y)/profile.size()))
				surface.add_vertex(Vector3(p.x,0.345+p.y*sin(angle),p.y*cos(angle)))
	surface.generate_tangents()
	var shell:=MeshInstance3D.new()
	shell.name="HollowRubberCasing"
	shell.mesh=surface.commit()
	shell.material_override=material
	root.add_child(shell)
	# Four staggered lanes leave three circumferential channels and lateral gaps.
	for lane in range(4):
		var x: float=-0.078+lane*0.052
		for i in range(52):
			var angle: float=(i+(0.42 if lane%2 else 0.0))*TAU/52
			var radial:=Vector3(0,sin(angle),cos(angle))
			var rotation:=Basis(Vector3(1,0,0),radial,Vector3(0,-cos(angle),sin(angle)))
			var block:=b("WornTreadBlock",Vector3(x,0.345,0)+radial*(0.337 if lane in [0,3] else 0.342),Vector3(0.044,0.01,0.033),material,0.0018)
			block.basis=rotation*Basis(Vector3.UP,0.16 if lane%2 else -0.16)
	for side in [-1,1]:
		for radius in [0.208,0.286]:
			var rib:=ring("MouldedSidewallRib",Vector3(side*0.114,0.345,0),radius,0.0018,material)
			rib.rotation.z=PI/2
	# Eight convex rubber sectors preserve an open centre in collision too.
	for i in range(8):
		var angle:=i*TAU/8
		var collider:=CollisionShape3D.new()
		var shape:=BoxShape3D.new()
		shape.size=Vector3(0.24,0.12,0.205)
		collider.shape=shape
		collider.position=Vector3(0,0.345+sin(angle)*0.267,cos(angle)*0.267)
		collider.rotation.x=PI/2-angle
		root.add_child(collider)

func workbench() -> void:
	for i in range(5):
		b("TimberWorktopBoard",Vector3(0,0.81,-0.28+i*0.14),Vector3(1.5,0.08,0.132),timber,0.008)
	for x in [-0.65,0.65]:
		for z in [-0.24,0.24]:
			b("SteelBenchLeg",Vector3(x,0.4,z),Vector3(0.055,0.8,0.055),blue)
		beam("EndBrace",Vector3(x,0.2,-0.24),Vector3(x,0.7,0.24),0.025,iron)
	b("LowerShelf",Vector3(0,0.21,0),Vector3(1.35,0.035,0.53),timber)
	b("ViceBase",Vector3(0.42,0.885,0.18),Vector3(0.3,0.07,0.24),blue)
	for z in [0.13,0.29]:
		b("ViceJaw",Vector3(0.42,1.025,z),Vector3(0.26,0.16,0.065),iron)
		for i in range(7):
			b("JawSerration",Vector3(0.32+i*0.034,1.07,z-0.035),Vector3(0.012,0.045,0.006),rust,0.001)
	pipe("LeadScrew",Vector3(0.42,0.96,0.05),Vector3(0.42,0.96,0.49),0.018,iron)
	pipe("SlidingViceHandle",Vector3(0.42,0.86,0.5),Vector3(0.42,1.08,0.5),0.009,iron)
	for x in [0.31,0.53]:
		bolt(Vector3(x,0.9,0.3))
	collision_box(Vector3(0,0.43,0),Vector3(1.5,0.86,0.7))
	collision_box(Vector3(0.42,0.99,0.23),Vector3(0.3,0.26,0.4))

func wheelbarrow() -> void:
	var mat := blue.duplicate() as StandardMaterial3D
	mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var bottom := [Vector3(-0.22,0.36,-0.34),Vector3(0.22,0.36,-0.34),Vector3(0.22,0.36,0.24),Vector3(-0.22,0.36,0.24)]
	var top := [Vector3(-0.4,0.65,-0.5),Vector3(0.4,0.65,-0.5),Vector3(0.4,0.65,0.4),Vector3(-0.4,0.65,0.4)]
	for i in range(4):
		quad(surface,[bottom[i],bottom[(i+1)%4],top[(i+1)%4],top[i]])
		pipe("RolledTrayRim",top[i],top[(i+1)%4],0.014,iron)
	surface.generate_tangents()
	var tray := MeshInstance3D.new()
	tray.name="HollowSteelTray"
	tray.mesh=surface.commit()
	tray.material_override=mat
	root.add_child(tray)
	b("TrayFloor",Vector3(0,0.36,-0.05),Vector3(0.44,0.02,0.58),blue)
	for x in [-0.27,0.27]:
		pipe("TubularFrame",Vector3(x,0.22,-0.56),Vector3(x,0.65,1.0),0.024,olive)
		pipe("RubberGrip",Vector3(x,0.62,0.86),Vector3(x,0.65,1.0),0.03,rubber)
		pipe("SupportLeg",Vector3(x,0.03,0.36),Vector3(x,0.4,0.12),0.023,iron)
	tyre(Vector3(0,0.19,-0.57),0.19,0.12,false)
	pipe("WheelAxle",Vector3(-0.29,0.19,-0.57),Vector3(0.29,0.19,-0.57),0.015,iron)
	pipe("WheelHub",Vector3(-0.067,0.19,-0.57),Vector3(0.067,0.19,-0.57),0.085,iron)
	collision_box(Vector3(0,0.4,-0.06),Vector3(0.8,0.54,0.95))

func ladder() -> void:
	for x in [-0.23,0.23]:
		b("LadderRail",Vector3(x,1.15,0),Vector3(0.055,2.3,0.07),olive,0.012)
		b("RubberFoot",Vector3(x,0.04,0),Vector3(0.07,0.08,0.09),rubber)
	for i in range(8):
		pipe("SerratedRung",Vector3(-0.22,0.22+i*0.27,0),Vector3(0.22,0.22+i*0.27,0),0.02,iron)
	collision_box(Vector3(0,1.15,0),Vector3(0.52,2.3,0.12))

func extinguisher() -> void:
	pipe("PressureBottle",Vector3(0,0.025,0),Vector3(0,0.41,0),0.084,red)
	var shoulder:=MeshInstance3D.new()
	shoulder.name="BottleShoulder"
	var shape:=CylinderMesh.new()
	shape.bottom_radius=0.084
	shape.top_radius=0.025
	shape.height=0.07
	shape.radial_segments=32
	shoulder.mesh=shape
	shoulder.position.y=0.445
	shoulder.material_override=red
	root.add_child(shoulder)
	ring("ProtectiveBaseRim",Vector3(0,0.025,0),0.078,0.009,rubber)
	pipe("ValveStem",Vector3(0,0.47,0),Vector3(0,0.54,0),0.018,iron)
	for y in [0.54,0.585]:
		b("OperatingLever",Vector3(0.045,y,0),Vector3(0.15,0.018,0.035),rubber,0.004)
	var route := [Vector3(-0.02,0.52,0),Vector3(-0.11,0.49,0),Vector3(-0.13,0.3,0),Vector3(-0.11,0.08,0.02)]
	for i in range(route.size()-1):
		pipe("DischargeHose",route[i],route[i+1],0.011,rubber)
	pipe("Nozzle",route[-1],route[-1]+Vector3(0,-0.06,0),0.017,rubber)
	pipe("GaugeBody",Vector3(0,0.51,0.02),Vector3(0,0.51,0.046),0.026,iron)
	pipe("GaugeFace",Vector3(0,0.51,0.046),Vector3(0,0.51,0.048),0.021,enamel)
	pipe("GaugeNeedle",Vector3(0,0.51,0.05),Vector3(0.014,0.519,0.05),0.002,red)
	collision_cylinder(0.09,0.61)

func open_crate() -> void:
	for x in [-0.31,0.31]:
		for z in [-0.22,0.22]:
			b("CornerPost",Vector3(x,0.22,z),Vector3(0.05,0.44,0.05),timber)
	for y in [0.09,0.22,0.35]:
		for z in [-0.24,0.24]:
			b("SideSlat",Vector3(0,y,z),Vector3(0.7,0.11,0.035),timber,0.004)
		for x in [-0.33,0.33]:
			b("EndSlat",Vector3(x,y,0),Vector3(0.035,0.11,0.45),timber,0.004)
	for i in range(4):
		b("FloorSlat",Vector3(-0.25+i*0.167,0.025,0),Vector3(0.155,0.035,0.46),timber,0.004)
	for z in [-0.24,0.24]:
		collision_box(Vector3(0,0.22,z),Vector3(0.7,0.44,0.035))
	for x in [-0.33,0.33]:
		collision_box(Vector3(x,0.22,0),Vector3(0.035,0.44,0.45))
	collision_box(Vector3(0,0.025,0),Vector3(0.7,0.035,0.5))

func hose() -> void:
	for i in range(7):
		ring("CoiledRubberHose",Vector3(0,0.025,0),0.09+i*0.035,0.015,rubber)
	pipe("LooseHoseEnd",Vector3(0.29,0.025,0),Vector3(0.34,0.025,0.2),0.015,rubber)
	pipe("MetalCoupling",Vector3(0.34,0.025,0.2),Vector3(0.35,0.025,0.25),0.022,iron)
	collision_box(Vector3(0,0.025,0),Vector3(0.7,0.05,0.7))

func chair() -> void:
	for x in [-0.21,0.21]:
		for z in [-0.2,0.2]:
			pipe("SteelLeg",Vector3(x,0.015,z),Vector3(x*0.9,0.46,z*0.9),0.019,iron)
		pipe("BackrestUpright",Vector3(x,0.44,-0.2),Vector3(x,0.9,-0.24),0.018,iron)
	b("PressedSeat",Vector3(0,0.46,0),Vector3(0.46,0.035,0.44),blue,0.015)
	b("CurvedBackrest",Vector3(0,0.77,-0.24),Vector3(0.45,0.26,0.035),blue,0.015)
	pipe("LegCrossbar",Vector3(-0.21,0.18,-0.2),Vector3(0.21,0.18,-0.2),0.012,iron)
	collision_box(Vector3(0,0.24,0),Vector3(0.5,0.48,0.5))
	collision_box(Vector3(0,0.77,-0.24),Vector3(0.45,0.3,0.04))

func build_workshop(id: String) -> Node3D:
	root=StaticBody3D.new()
	root.name=id.to_pascal_case()
	rng.seed=hash(id)
	match id:
		"discarded_tyre": discarded_tyre()
		"workbench_vise": workbench()
		"wheelbarrow": wheelbarrow()
		"steel_ladder": ladder()
		"fire_extinguisher": extinguisher()
		"open_wood_crate": open_crate()
		"coiled_hose": hose()
		"metal_chair": chair()
	merge_meshes()
	root.set_meta("prop_id",id)
	root.set_meta("approximate_size_metres",WORKSHOP_CATALOG[id])
	root.set_meta("world_text_policy","No attached text")
	return root
