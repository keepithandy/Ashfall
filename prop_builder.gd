extends "res://house_builder.gd"
## Original modular prop kit. Reuses the house's scanned materials and helpers.

const CATALOG := {
	"steel_drum": ["Olive steel drum", "Storage"],
	"rusted_drum": ["Rusted steel drum", "Storage"],
	"wooden_pallet": ["Wooden pallet", "Storage"],
	"shipping_crate": ["Shipping crate", "Storage"],
	"equipment_case": ["Equipment case", "Storage"],
	"jerrycan": ["Fuel jerrycan", "Utilities"],
	"gas_cylinder": ["Gas cylinder", "Utilities"],
	"cable_spool": ["Cable spool", "Utilities"],
	"portable_generator": ["Portable generator", "Utilities"],
	"traffic_cone": ["Traffic cone", "Checkpoint"],
	"concrete_barrier": ["Concrete barrier", "Checkpoint"],
	"warning_sign": ["Restricted area sign", "Checkpoint"],
	"work_light": ["Tripod work light", "Workshop"],
	"hand_truck": ["Hand truck", "Workshop"],
	"tool_box": ["Steel toolbox", "Workshop"],
	"pipe_bundle": ["Pipe bundle", "Workshop"],
	"electrical_cabinet": ["Electrical cabinet", "Utilities"],
	"shelving_unit": ["Steel shelving", "Interiors"],
	"filing_cabinet": ["Filing cabinet", "Interiors"],
	"wooden_bench": ["Wooden bench", "Interiors"],
	"desk_radio": ["Desk radio", "Small objects"],
	"metal_bucket": ["Metal bucket", "Small objects"],
	"enamel_mug": ["Enamel mug", "Small objects"],
	"rubble_pile": ["Masonry debris", "Ground dressing"],
	"radiator": ["Cast iron radiator", "Interiors"],
	"field_cot": ["Abandoned field cot", "Interiors"],
	"worn_mattress": ["Worn mattress", "Interiors"],
	"wall_fusebox": ["Open wall fusebox", "Utilities"],
	"valve_pipe": ["Industrial valve pipe", "Utilities"],
	"pendant_light": ["Hanging industrial lamp", "Interiors"],
	"damaged_fence": ["Damaged wire fence", "Checkpoint"],
	"sandbag_stack": ["Sandbag barricade", "Checkpoint"]
}

var olive: Material
var rust: Material
var red: Material
var yellow: Material
var blue: Material
var rubber: Material
var paper: Material
var enamel: Material
var bounds := Vector3.ONE

func fitted_text(words: String, at: Vector3, font_size: int, panel_size: Vector2) -> Label3D:
	var label := text(words,at,font_size)
	var font := ThemeDB.fallback_font
	while label.font_size > 6:
		var dimensions := font.get_multiline_string_size(words,HORIZONTAL_ALIGNMENT_CENTER,-1,label.font_size) * label.pixel_size
		if dimensions.x <= panel_size.x and dimensions.y <= panel_size.y:
			break
		label.font_size -= 1
	label.set_meta("lettering_panel_metres",panel_size)
	return label

func prepare_materials() -> void:
	# Shared external resources keep instanced scenes from duplicating texture sets.
	var folder := "res://assets/props/"
	DirAccess.make_dir_recursive_absolute(folder)
	# Reclaimed wood keeps the photographed grain while toning down the original
	# high-contrast peeling paint. This derivative is only used by the prop kit.
	var wood_material := scanned("wood_peeling_paint_weathered",0.762)
	var wood_image := wood_material.albedo_texture.get_image()
	if wood_image.is_compressed():
		wood_image.decompress()
	wood_image.resize(1024,1024,Image.INTERPOLATE_LANCZOS)
	wood_image.adjust_bcs(1.1,0.48,0.3)
	var toned_texture := ImageTexture.create_from_image(wood_image)
	ResourceSaver.save(toned_texture,folder+"reclaimed_wood.res")
	wood_material.albedo_texture = load(folder+"reclaimed_wood.res")
	wood_material.albedo_color = Color("b9ab91")
	wood_material.normal_scale = 0.32
	var definitions := {
		"wood": wood_material,
		"concrete": scanned("concrete_floor_worn_001", 3.0),
		"masonry": scanned("rough_plaster_brick_02", 1.5),
		"rust": worn_metal(Color("714c35")),
		"olive": worn_metal(Color("53624b")),
		"red": worn_metal(Color("874739")),
		"yellow": worn_metal(Color("c8a556")),
		"blue": worn_metal(Color("4b6268")),
		"iron": plain(Color("777e7a"), 0.63, 0.65),
		"rubber": plain(Color("202521"), 0.96),
		"paper": plain(Color("c5bfa5")),
		"enamel": plain(Color("b8c3b9"), 0.36)
	}
	for key: String in definitions:
		var path := folder + key + ".tres"
		if not FileAccess.file_exists(path) or "--refresh-prop-materials" in OS.get_cmdline_user_args():
			ResourceSaver.save(definitions[key], path)
	timber = load(folder + "wood.tres")
	concrete = load(folder + "concrete.tres")
	masonry = load(folder + "masonry.tres")
	rust = load(folder + "rust.tres")
	olive = load(folder + "olive.tres")
	red = load(folder + "red.tres")
	yellow = load(folder + "yellow.tres")
	blue = load(folder + "blue.tres")
	iron = load(folder + "iron.tres")
	rubber = load(folder + "rubber.tres")
	paper = load(folder + "paper.tres")
	enamel = load(folder + "enamel.tres")

func worn_metal(color: Color) -> StandardMaterial3D:
	var mat := plain(Color.WHITE, 0.87, 0.15)
	var noise := FastNoiseLite.new()
	noise.seed = 822
	noise.frequency = 0.085
	noise.fractal_octaves = 4
	var texture := NoiseTexture2D.new()
	texture.width = 256
	texture.height = 256
	texture.generate_mipmaps = true
	texture.seamless = true
	texture.noise = noise
	var colors := Gradient.new()
	colors.set_color(0, color.darkened(0.18))
	colors.set_color(1, Color("8e613f"))
	colors.add_point(0.63, color)
	colors.add_point(0.68, Color("574032"))
	texture.color_ramp = colors
	mat.albedo_texture = texture
	mat.uv1_triplanar = true
	mat.uv1_scale = Vector3.ONE * 1.3
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return mat

func b(label: String, at: Vector3, size: Vector3, mat: Material, bevel: float = 0.008) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = label
	mesh.position = at
	mesh.mesh = bevel_box(size, minf(bevel, minf(size.x, minf(size.y, size.z)) * 0.24))
	mesh.material_override = mat
	root.add_child(mesh)
	return mesh

func bevel_box(size: Vector3, bevel: float) -> ArrayMesh:
	# Six inset faces, twelve bevel strips, and eight clipped corners.
	var half := size * 0.5
	var inset := half - Vector3.ONE * bevel
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for axis in range(3):
		var u := (axis + 1) % 3
		var v := (axis + 2) % 3
		for sign_value in [-1, 1]:
			var corners: Array[Vector3] = []
			for pair in [Vector2(-1,-1), Vector2(1,-1), Vector2(1,1), Vector2(-1,1)]:
				var point := Vector3.ZERO
				point[axis] = sign_value * half[axis]
				point[u] = pair.x * inset[u]
				point[v] = pair.y * inset[v]
				corners.append(point)
			quad(surface, corners)
	for axis in range(3):
		var u := (axis + 1) % 3
		var v := (axis + 2) % 3
		for su in [-1, 1]:
			for sv in [-1, 1]:
				var corners: Array[Vector3] = []
				for pair in [Vector2(-1,0),Vector2(1,0),Vector2(1,1),Vector2(-1,1)]:
					var point := Vector3.ZERO
					point[axis] = pair.x * inset[axis]
					point[u] = su * (half[u] if pair.y == 0 else inset[u])
					point[v] = sv * (inset[v] if pair.y == 0 else half[v])
					corners.append(point)
				quad(surface, corners)
	for x in [-1, 1]:
		for y in [-1, 1]:
			for z in [-1, 1]:
				var sign_vector := Vector3(x,y,z)
				var points: Array[Vector3] = []
				for axis in range(3):
					var point := inset * sign_vector
					point[axis] = half[axis] * sign_vector[axis]
					points.append(point)
				triangle(surface, points[0], points[1], points[2])
	surface.generate_tangents()
	return surface.commit()

func triangle(surface: SurfaceTool, a: Vector3, c: Vector3, d: Vector3) -> void:
	var normal := (c - a).cross(d - a).normalized()
	if normal.dot((a + c + d) / 3) < 0:
		var swap := c
		c = d
		d = swap
		normal = -normal
	# Godot front faces use clockwise winding.
	for vertex in [a, d, c]:
		surface.set_normal(normal)
		surface.set_uv(Vector2(vertex.x + vertex.z, -vertex.y))
		surface.add_vertex(vertex)

func quad(surface: SurfaceTool, vertices: Array[Vector3]) -> void:
	triangle(surface, vertices[0], vertices[1], vertices[2])
	triangle(surface, vertices[0], vertices[2], vertices[3])

func lathe(label: String, profile: PackedVector2Array, mat: Material, segments: int = 40) -> MeshInstance3D:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(0)
	for j in range(profile.size() - 1):
		for i in range(segments):
			var corners: Array[Vector3] = []
			for step in [Vector2i(i,j), Vector2i(i+1,j), Vector2i(i+1,j+1), Vector2i(i,j+1)]:
				var angle := float(step.x) / segments * TAU
				var p := profile[step.y]
				corners.append(Vector3(sin(angle) * p.x, p.y, cos(angle) * p.x))
			for index in [0, 2, 1, 0, 3, 2]:
				var point := corners[index]
				surface.set_uv(Vector2(atan2(point.x, point.z) / TAU, -point.y))
				surface.add_vertex(point)
	surface.generate_normals()
	surface.generate_tangents()
	var mesh := MeshInstance3D.new()
	mesh.name = label
	mesh.mesh = surface.commit()
	mesh.material_override = mat
	root.add_child(mesh)
	return mesh

func ring(label: String, at: Vector3, radius: float, thickness: float, mat: Material) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = label
	mesh.position = at
	var torus := TorusMesh.new()
	torus.inner_radius = radius - thickness
	torus.outer_radius = radius + thickness
	torus.rings = 32
	torus.ring_segments = 8
	mesh.mesh = torus
	mesh.material_override = mat
	root.add_child(mesh)
	return mesh

func collision_box(at: Vector3, size: Vector3) -> void:
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collider.shape = shape
	collider.position = at
	root.add_child(collider)

func collision_cylinder(radius: float, height: float) -> void:
	var collider := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = height
	collider.shape = shape
	collider.position.y = height / 2
	root.add_child(collider)

func beam(label: String, start: Vector3, end: Vector3, thickness: float, mat: Material) -> void:
	var piece := b(label, (start + end) / 2, Vector3(thickness, start.distance_to(end), thickness), mat)
	piece.quaternion = Quaternion(Vector3.UP, (end - start).normalized())

func bolt(at: Vector3, radius: float = 0.012) -> void:
	pipe("Fastener", at, at + Vector3(0, 0, 0.008), radius, iron)

func drum(rusted: bool) -> void:
	bounds = Vector3(0.62,0.89,0.62)
	var mat := rust if rusted else olive
	lathe("RolledSteelShell", PackedVector2Array([
		Vector2(0,0.01),Vector2(0.28,0.01),Vector2(0.3,0.025),Vector2(0.3,0.05),
		Vector2(0.286,0.065),Vector2(0.286,0.27),Vector2(0.302,0.285),Vector2(0.302,0.305),
		Vector2(0.286,0.32),Vector2(0.286,0.57),Vector2(0.302,0.585),Vector2(0.302,0.605),
		Vector2(0.286,0.62),Vector2(0.286,0.83),Vector2(0.3,0.85),Vector2(0.3,0.88),
		Vector2(0.277,0.88),Vector2(0.277,0.855),Vector2(0,0.855)]), mat)
	ring("TopRolledRim", Vector3(0,0.875,0),0.29,0.009,iron)
	pipe("FillBung",Vector3(0.15,0.85,0.09),Vector3(0.15,0.88,0.09),0.031,iron)
	pipe("VentBung",Vector3(-0.16,0.85,-0.08),Vector3(-0.16,0.87,-0.08),0.014,iron)
	if not rusted:
		b("FadedStencilPanel",Vector3(0,0.46,0.287),Vector3(0.22,0.13,0.006),paper)
		fitted_text("FUEL\n200 L",Vector3(0,0.46,0.292),16,Vector2(0.19,0.11)).modulate = Color("383c31")
	collision_cylinder(0.3,0.89)

func pallet() -> void:
	bounds = Vector3(1.2,0.144,0.8)
	for z in [-0.32,0,0.32]:
		b("BottomRunner",Vector3(0,0.011,z),Vector3(1.2,0.022,0.145),timber,0.004)
		for x in [-0.5,0,0.5]:
			b("SupportBlock",Vector3(x,0.061,z),Vector3(0.145,0.078,0.145),timber)
	for x in [-0.5,0,0.5]:
		b("CrossMember",Vector3(x,0.111,0),Vector3(0.145,0.022,0.8),timber,0.004)
	for i in range(5):
		var z := -0.327 + i * 0.1635
		b("TopDeckBoard",Vector3(0,0.133,z),Vector3(1.2,0.022,0.125),timber,0.003)
	collision_box(Vector3(0,0.072,0),bounds)

func crate(equipment: bool) -> void:
	bounds = Vector3(0.65,0.34,0.36) if equipment else Vector3(0.9,0.72,0.7)
	var mat := olive if equipment else timber
	if equipment:
		b("PressedMetalBody",bounds * Vector3(0,0.48,0),bounds * Vector3(1,0.88,1),mat,0.022)
		b("OverlappingLid",Vector3(0,bounds.y-0.025,0),Vector3(bounds.x+0.014,0.05,bounds.z+0.014),mat)
	else:
		for side in [-1,1]:
			for i in range(5):
				b("SidePlank",Vector3(0,0.075+i*0.14,side*0.33),Vector3(0.89,0.132,0.035),timber,0.004)
				b("EndPlank",Vector3(side*0.43,0.075+i*0.14,0),Vector3(0.035,0.132,0.62),timber,0.004)
			for x in [-0.33,0.33]:
				b("VerticalBatten",Vector3(x,0.36,side*0.36),Vector3(0.065,0.7,0.03),timber)
		for i in range(5):
			b("LidBoard",Vector3(0,0.7,-0.28+i*0.14),Vector3(0.9,0.035,0.13),timber,0.004)
	for side in [-1,1]:
		var x: float = side * bounds.x * 0.3
		b("MetalBand",Vector3(x,bounds.y/2,bounds.z/2+0.02),Vector3(0.03,bounds.y,0.012),iron,0.002)
		b("BandAcrossLid",Vector3(x,bounds.y+0.005,0),Vector3(0.03,0.009,bounds.z),iron,0.002)
		for y in [0.08,bounds.y-0.08]:
			bolt(Vector3(x,y,bounds.z/2+0.03))
	if equipment:
		for side in [-1,1]:
			pipe("CarryHandle",Vector3(side*0.33,0.16,-0.08),Vector3(side*0.33,0.16,0.08),0.014,iron)
		b("LidLatch",Vector3(0,0.27,0.2),Vector3(0.07,0.09,0.025),iron)
	fitted_text("FIELD EQUIPMENT" if equipment else "STATION 04\nSUPPLIES",Vector3(0,bounds.y*0.54,bounds.z/2+0.028),16 if equipment else 24,Vector2(bounds.x*0.75,bounds.y*0.4))
	collision_box(Vector3(0,bounds.y/2,0),bounds)

func jerrycan() -> void:
	bounds = Vector3(0.35,0.48,0.19)
	b("StampedFuelCan",Vector3(0,0.2,0),Vector3(0.35,0.39,0.18),olive,0.03)
	b("Shoulder",Vector3(0,0.395,0),Vector3(0.3,0.07,0.17),olive,0.025)
	for z in [-0.055,0,0.055]:
		beam("HandleUpright",Vector3(-0.07,0.4,z),Vector3(-0.07,0.475,z),0.023,olive)
		beam("CarryGrip",Vector3(-0.07,0.475,z),Vector3(0.1,0.475,z),0.023,olive)
		beam("HandleReturn",Vector3(0.1,0.475,z),Vector3(0.12,0.4,z),0.023,olive)
	pipe("FillerCap",Vector3(-0.12,0.4,0),Vector3(-0.12,0.435,0),0.042,iron)
	for side in [-1,1]:
		beam("StampedReinforcement",Vector3(-0.1,0.1,side*0.094),Vector3(0.1,0.31,side*0.094),0.013,olive)
		beam("StampedReinforcement",Vector3(0.1,0.1,side*0.094),Vector3(-0.1,0.31,side*0.094),0.013,olive)
	collision_box(Vector3(0,0.24,0),bounds)

func gas_cylinder() -> void:
	bounds = Vector3(0.36,1.26,0.36)
	lathe("CylinderPressureVessel",PackedVector2Array([Vector2(0,0.01),Vector2(0.14,0.01),Vector2(0.17,0.06),Vector2(0.17,0.94),Vector2(0.15,1.0),Vector2(0.08,1.06),Vector2(0.035,1.08),Vector2(0,1.08)]),blue)
	pipe("BrassValve",Vector3(0,1.07,0),Vector3(0,1.19,0),0.025,yellow)
	ring("ValveWheel",Vector3(0,1.19,0),0.055,0.009,iron)
	for side in [-1,1]:
		pipe("ValveGuard",Vector3(side*0.1,1.03,0),Vector3(side*0.1,1.25,0),0.017,blue)
	pipe("ValveGuardTop",Vector3(-0.1,1.25,0),Vector3(0.1,1.25,0),0.017,blue)
	collision_cylinder(0.17,1.26)

func spool() -> void:
	bounds = Vector3(0.85,0.72,0.85)
	for y in [0.045,0.675]:
		pipe("TimberFlange",Vector3(0,y-0.035,0),Vector3(0,y+0.035,0),0.42,timber)
		for i in range(6):
			var a := i * TAU/6
			pipe("FlangeBolt",Vector3(sin(a)*0.32,y,cos(a)*0.32),Vector3(sin(a)*0.32,y+0.04,cos(a)*0.32),0.015,iron)
	pipe("CentralCableCore",Vector3(0,0.08,0),Vector3(0,0.64,0),0.22,timber)
	for i in range(21):
		ring("WoundCable",Vector3(0,0.1+i*0.026,0),0.285,0.014,rubber)
	collision_cylinder(0.42,0.72)

func generator() -> void:
	bounds = Vector3(0.78,0.64,0.54)
	for x in [-0.35,0.35]:
		for z in [-0.23,0.23]:
			pipe("CageUpright",Vector3(x,0.04,z),Vector3(x,0.61,z),0.024,olive)
		for y in [0.06,0.61]:
			pipe("CageEnd",Vector3(x,y,-0.23),Vector3(x,y,0.23),0.024,olive)
	for z in [-0.23,0.23]:
		for y in [0.06,0.61]:
			pipe("FrameRail",Vector3(-0.35,y,z),Vector3(0.35,y,z),0.024,olive)
	b("EngineBlock",Vector3(-0.12,0.29,0),Vector3(0.28,0.31,0.34),iron,0.025)
	for i in range(7):
		b("CoolingFin",Vector3(-0.12,0.18+i*0.032,0),Vector3(0.32,0.012,0.36),iron,0.003)
	pipe("Alternator",Vector3(0.04,0.27,0),Vector3(0.28,0.27,0),0.15,blue)
	b("FuelTank",Vector3(0,0.52,0),Vector3(0.55,0.13,0.36),olive,0.025)
	pipe("FuelCap",Vector3(-0.1,0.59,0),Vector3(-0.1,0.62,0),0.034,iron)
	b("ControlPanel",Vector3(0.2,0.36,0.2),Vector3(0.23,0.21,0.025),olive)
	for x in [0.15,0.25]:
		pipe("Socket",Vector3(x,0.35,0.215),Vector3(x,0.35,0.23),0.028,rubber)
	pipe("Exhaust",Vector3(-0.22,0.3,-0.18),Vector3(-0.22,0.49,-0.18),0.025,rust)
	collision_box(Vector3(0,0.32,0),bounds)

func cone() -> void:
	bounds = Vector3(0.42,0.72,0.42)
	b("WeightedRubberBase",Vector3(0,0.025,0),Vector3(0.42,0.05,0.42),rubber,0.02)
	var orange := worn_metal(Color("b85e30"))
	lathe("TaperedCone",PackedVector2Array([Vector2(0.17,0.05),Vector2(0.035,0.7),Vector2(0.02,0.72),Vector2(0.015,0.7)]),orange)
	lathe("ReflectiveBand",PackedVector2Array([Vector2(0.125,0.28),Vector2(0.101,0.39)]),paper)
	collision_box(Vector3(0,0.23,0),Vector3(0.42,0.46,0.42))

func barrier() -> void:
	bounds = Vector3(2.2,0.91,0.6)
	var mesh := MeshInstance3D.new()
	mesh.name = "CastConcreteBarrier"
	var hull := ConvexPolygonShape3D.new()
	var vertices := PackedVector3Array()
	for x in [-1.1,1.1]:
		for p in [Vector2(-0.3,0),Vector2(0.3,0),Vector2(0.3,0.15),Vector2(0.12,0.52),Vector2(0.12,0.9),Vector2(-0.12,0.9),Vector2(-0.12,0.52),Vector2(-0.3,0.15)]:
			vertices.append(Vector3(x,p.y,p.x))
	hull.points = vertices
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var centered: Array[Vector3] = []
	for vertex in vertices:
		centered.append(vertex - Vector3(0,0.45,0))
	for i in range(8):
		quad(surface,[centered[i],centered[(i+1)%8],centered[(i+1)%8+8],centered[i+8]])
	var profile := PackedVector2Array()
	for i in range(8):
		profile.append(Vector2(centered[i].z,centered[i].y))
	var indices := Geometry2D.triangulate_polygon(profile)
	for side in [0,8]:
		for i in range(0,indices.size(),3):
			triangle(surface,centered[indices[i]+side],centered[indices[i+1]+side],centered[indices[i+2]+side])
	surface.generate_tangents()
	mesh.mesh = surface.commit()
	mesh.position.y = 0.45
	mesh.material_override = concrete
	root.add_child(mesh)
	var collider := CollisionShape3D.new()
	collider.shape = hull
	root.add_child(collider)
	for i in range(7):
		var stripe := b("WornHazardStripe",Vector3(-0.93+i*0.31,0.7,0.123),Vector3(0.15,0.3,0.006),yellow,0.001)
		stripe.rotation.z = -0.22
	for x in [-0.7,0.7]:
		var loop := ring("LiftingEye",Vector3(x,0.92,0),0.045,0.009,iron)
		loop.rotation.x = PI/2

func warning_sign() -> void:
	bounds = Vector3(0.76,1.65,0.52)
	b("SteelFoot",Vector3(0,0.03,0),Vector3(0.6,0.06,0.5),iron)
	pipe("SignPost",Vector3(0,0.05,0),Vector3(0,1.5,0),0.032,rust)
	b("PaintedSign",Vector3(0,1.3,0.04),Vector3(0.74,0.55,0.024),yellow)
	b("SignInset",Vector3(0,1.3,0.055),Vector3(0.68,0.49,0.006),olive,0.002)
	fitted_text("RESTRICTED\nAREA\nAUTHORIZED\nSTAFF",Vector3(0,1.31,0.061),21,Vector2(0.60,0.40))
	for x in [-0.31,0.31]:
		bolt(Vector3(x,1.49,0.063))
	collision_box(Vector3(0,0.035,0),Vector3(0.6,0.07,0.5))
	collision_box(Vector3(0,0.8,0),Vector3(0.08,1.6,0.08))

func work_light() -> void:
	bounds = Vector3(0.9,1.8,0.9)
	for i in range(3):
		var a := i*TAU/3
		pipe("TripodLeg",Vector3(sin(a)*0.44,0.04,cos(a)*0.44),Vector3(0,0.68,0),0.02,iron)
	pipe("TelescopingStand",Vector3(0,0.3,0),Vector3(0,1.55,0),0.023,iron)
	b("HeightClamp",Vector3(0,0.91,0),Vector3(0.08,0.08,0.07),yellow)
	b("FloodlightHousing",Vector3(0,1.62,0),Vector3(0.43,0.29,0.17),yellow,0.025)
	b("Reflector",Vector3(0,1.62,0.09),Vector3(0.36,0.22,0.015),iron)
	b("LampLens",Vector3(0,1.62,0.1),Vector3(0.32,0.18,0.012),enamel)
	var light := SpotLight3D.new()
	light.name = "OptionalWorkLight"
	light.position = Vector3(0,1.62,0.13)
	light.rotation.y = PI
	light.spot_range = 12
	light.light_color = Color("ffe0ad")
	light.light_energy = 2
	light.visible = false
	root.add_child(light)
	collision_box(Vector3(0,0.7,0),Vector3(0.12,1.4,0.12))

func hand_truck() -> void:
	bounds = Vector3(0.55,1.18,0.45)
	for x in [-0.2,0.2]:
		pipe("FrameUpright",Vector3(x,0.12,0),Vector3(x,1.15,-0.1),0.023,red)
		pipe("HandleGrip",Vector3(x,1.15,-0.1),Vector3(x,1.15,-0.25),0.03,rubber)
	for y in [0.25,0.55,0.85]:
		pipe("FrameCrossbar",Vector3(-0.2,y,0),Vector3(0.2,y,0),0.018,red)
	b("ToePlate",Vector3(0,0.05,0.16),Vector3(0.44,0.035,0.3),iron)
	for x in [-0.25,0.25]:
		var wheel := ring("RubberWheel",Vector3(x,0.14,-0.06),0.103,0.035,rubber)
		wheel.rotation.z = PI/2
		pipe("WheelHub",Vector3(x-0.035,0.14,-0.06),Vector3(x+0.035,0.14,-0.06),0.055,iron)
	collision_box(Vector3(0,0.55,0),Vector3(0.54,1.1,0.18))

func toolbox() -> void:
	bounds = Vector3(0.46,0.31,0.24)
	b("SteelTray",Vector3(0,0.11,0),Vector3(0.46,0.22,0.24),red,0.018)
	b("Lid",Vector3(0,0.232,0),Vector3(0.47,0.045,0.25),red)
	for x in [-0.08,0.08]:
		pipe("HandleMount",Vector3(x,0.25,0),Vector3(x,0.3,0),0.012,iron)
	pipe("CarryHandle",Vector3(-0.08,0.3,0),Vector3(0.08,0.3,0),0.015,rubber)
	for x in [-0.14,0.14]:
		b("ToggleLatch",Vector3(x,0.21,0.135),Vector3(0.035,0.07,0.02),iron)
	collision_box(Vector3(0,0.13,0),Vector3(0.47,0.26,0.25))

func pipes() -> void:
	bounds = Vector3(1.65,0.46,0.6)
	for layer in range(2):
		for i in range(3-layer):
			var tube := lathe("OpenSteelPipe",PackedVector2Array([Vector2(0.09,0),Vector2(0.09,1.6),Vector2(0.074,1.6),Vector2(0.074,0),Vector2(0.09,0)]),rust)
			tube.rotation.z = -PI/2
			tube.position = Vector3(-0.8,0.1+layer*0.165,-0.2+i*0.2+layer*0.1)
	for x in [-0.55,0.55]:
		b("StrapAcrossTop",Vector3(x,0.37,0),Vector3(0.025,0.012,0.54),iron,0.002)
		for z in [-0.27,0.27]:
			b("StrapSide",Vector3(x,0.19,z),Vector3(0.025,0.36,0.012),iron,0.002)
	collision_box(Vector3(0,0.2,0),Vector3(1.6,0.4,0.58))

func cabinet(electrical: bool) -> void:
	bounds = Vector3(0.65,1.5,0.42) if electrical else Vector3(0.48,1.12,0.6)
	b("FoldedSteelCarcass",Vector3(0,bounds.y/2,0),bounds,olive if electrical else blue,0.018)
	var drawers := 1 if electrical else 3
	for i in range(drawers):
		var y := bounds.y * (i+0.5)/drawers
		b("DoorPanel",Vector3(0,y,bounds.z/2+0.008),Vector3(bounds.x-0.035,bounds.y/drawers-0.025,0.024),olive if electrical else blue)
		b("RecessedHandle",Vector3(bounds.x*0.27 if electrical else 0,y,bounds.z/2+0.03),Vector3(0.025,0.13,0.025) if electrical else Vector3(0.15,0.025,0.025),iron)
		if not electrical:
			b("DrawerIndex",Vector3(0,y+0.08,bounds.z/2+0.025),Vector3(0.11,0.04,0.008),paper,0.001)
	if electrical:
		for y in [0.25,1.16]:
			for i in range(6):
				b("VentSlot",Vector3(0,y+i*0.026,0.238),Vector3(0.4,0.009,0.004),rubber,0.001)
		b("WarningLabel",Vector3(0,0.9,0.24),Vector3(0.19,0.16,0.004),yellow,0.001)
		fitted_text("HIGH\nVOLTAGE",Vector3(0,0.9,0.246),12,Vector2(0.16,0.13)).modulate = Color("24291f")
	collision_box(Vector3(0,bounds.y/2,0),bounds)

func shelving() -> void:
	bounds = Vector3(1.25,1.8,0.48)
	for x in [-0.6,0.6]:
		for z in [-0.21,0.21]:
			b("AngleIronUpright",Vector3(x,0.9,z),Vector3(0.04,1.8,0.04),blue)
			collision_box(Vector3(x,0.9,z),Vector3(0.04,1.8,0.04))
	for y in [0.12,0.64,1.16,1.68]:
		b("SheetMetalShelf",Vector3(0,y,0),Vector3(1.25,0.035,0.48),blue)
		collision_box(Vector3(0,y,0),Vector3(1.25,0.035,0.48))
	beam("RearDiagonalBrace",Vector3(-0.58,0.15,-0.22),Vector3(0.58,1.68,-0.22),0.018,iron)

func bench() -> void:
	bounds = Vector3(1.7,0.85,0.55)
	for z in [-0.17,0,0.17]:
		b("SeatSlat",Vector3(0,0.45,z),Vector3(1.7,0.055,0.15),timber)
	for x in [-0.64,0.64]:
		for z in [-0.18,0.18]:
			beam("BenchLeg",Vector3(x,0.02,z*1.3),Vector3(x,0.44,z),0.045,iron)
		beam("BackrestSupport",Vector3(x,0.4,-0.2),Vector3(x,0.85,-0.28),0.04,iron)
	for y in [0.64,0.8]:
		b("BackrestSlat",Vector3(0,y,-0.26),Vector3(1.7,0.13,0.045),timber)
	collision_box(Vector3(0,0.23,0),Vector3(1.7,0.46,0.5))
	collision_box(Vector3(0,0.65,-0.25),Vector3(1.7,0.4,0.06))

func radio() -> void:
	bounds = Vector3(0.3,0.32,0.14)
	b("RadioBody",Vector3(0,0.1,0),Vector3(0.3,0.2,0.14),olive,0.018)
	b("SpeakerRecess",Vector3(-0.055,0.1,0.073),Vector3(0.15,0.14,0.008),rubber)
	for i in range(9):
		b("SpeakerGrille",Vector3(-0.055,0.04+i*0.015,0.079),Vector3(0.14,0.003,0.004),iron,0.001)
	b("TuningScale",Vector3(0.09,0.14,0.076),Vector3(0.065,0.035,0.008),paper)
	for x in [0.06,0.12]:
		pipe("TuningKnob",Vector3(x,0.065,0.073),Vector3(x,0.065,0.09),0.017,rubber)
	pipe("Antenna",Vector3(-0.12,0.2,0),Vector3(-0.16,0.32,0),0.0035,iron)
	pipe("CarryHandle",Vector3(-0.08,0.23,0),Vector3(0.08,0.23,0),0.009,rubber)
	for x in [-0.08,0.08]:
		pipe("HandleBracket",Vector3(x,0.2,0),Vector3(x,0.23,0),0.008,iron)
	collision_box(Vector3(0,0.1,0),Vector3(0.3,0.2,0.14))

func bucket(mug: bool) -> void:
	var radius := 0.045 if mug else 0.15
	var height := 0.09 if mug else 0.28
	bounds = Vector3(radius*2.8,height*1.5,radius*2)
	var mat := enamel if mug else iron
	lathe("OpenVessel",PackedVector2Array([Vector2(0,0.004),Vector2(radius*0.72,0.004),Vector2(radius, height),Vector2(radius-0.004,height),Vector2(radius*0.72-0.004,0.009),Vector2(0,0.009)]),mat)
	ring("RolledLip",Vector3(0,height,0),radius,0.003 if mug else 0.006,mat)
	if mug:
		var handle := ring("MugHandle",Vector3(radius, height*0.55,0),0.025,0.005,enamel)
		handle.rotation.x = PI/2
	else:
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_LINE_STRIP)
		for i in range(25):
			var angle := i*PI/24
			surface.add_vertex(Vector3(cos(angle)*radius,height+sin(angle)*radius,0))
		var handle := MeshInstance3D.new()
		handle.name = "WireBail"
		handle.mesh = surface.commit()
		handle.material_override = iron
		root.add_child(handle)
	collision_cylinder(radius,height)

func rubble() -> void:
	bounds = Vector3(1.4,0.22,1.0)
	for i in range(20):
		var size := Vector3(rng.randf_range(0.07,0.28),rng.randf_range(0.03,0.1),rng.randf_range(0.06,0.18))
		var piece := b("BrokenMasonry",Vector3(rng.randf_range(-0.58,0.58),size.y/2,rng.randf_range(-0.4,0.4)),size,masonry,0.01)
		piece.rotation.y = rng.randf_range(0,TAU)
	# Small loose debris intentionally does not catch the player's capsule.

func canvas_material(tint: Color) -> StandardMaterial3D:
	var mat := plain(tint,1)
	var noise := FastNoiseLite.new()
	noise.seed = 111
	noise.frequency = 0.06
	var texture := NoiseTexture2D.new()
	texture.width = 256
	texture.height = 256
	texture.generate_mipmaps = true
	texture.noise = noise
	var colors := Gradient.new()
	colors.set_color(0,Color("66665d"))
	colors.set_color(1,Color("c4beb0"))
	texture.color_ramp = colors
	mat.albedo_texture = texture
	mat.uv1_triplanar = true
	mat.uv1_scale = Vector3.ONE*0.8
	return mat

func radiator() -> void:
	bounds = Vector3(0.88,0.73,0.24)
	for i in range(9):
		var x := -0.35+i*0.0875
		b("CastIronSection",Vector3(x,0.39,0),Vector3(0.067,0.65,0.19),olive,0.025)
		b("SectionRecess",Vector3(x,0.39,0.099),Vector3(0.027,0.49,0.006),rust,0.006)
	for y in [0.12,0.65]:
		pipe("RadiatorManifold",Vector3(-0.43,y,0),Vector3(0.43,y,0),0.035,iron)
	for x in [-0.29,0.29]:
		b("IronFoot",Vector3(x,0.04,0),Vector3(0.07,0.08,0.24),iron)
	pipe("ValveStem",Vector3(0.43,0.65,0),Vector3(0.43,0.73,0),0.018,iron)
	collision_box(Vector3(0,0.365,0),bounds)

func mattress() -> void:
	bounds = Vector3(0.76,0.15,1.86)
	var cloth := canvas_material(Color("9e9d82"))
	b("StainedMattress",Vector3(0,0.075,0),bounds,cloth,0.035)
	for side in [-1,1]:
		pipe("PipedSeam",Vector3(side*0.37,0.105,-0.88),Vector3(side*0.37,0.105,0.88),0.005,paper)
	for z in [-0.62,-0.22,0.22,0.62]:
		for x in [-0.2,0.2]:
			b("QuiltButton",Vector3(x,0.151,z),Vector3(0.022,0.002,0.022),olive,0.001)
	collision_box(Vector3(0,0.075,0),bounds)

func cot() -> void:
	bounds = Vector3(0.83,0.72,1.98)
	for x in [-0.4,0.4]:
		pipe("BedFrameRail",Vector3(x,0.4,-0.95),Vector3(x,0.4,0.95),0.027,iron)
		for z in [-0.93,0.93]:
			pipe("BedLeg",Vector3(x,0,z),Vector3(x,0.7,z),0.026,olive)
	for z in [-0.93,0.93]:
		pipe("HeadFootRail",Vector3(-0.4,0.7,z),Vector3(0.4,0.7,z),0.026,olive)
	for z in [-0.8,-0.4,0,0.4,0.8]:
		pipe("BedSlat",Vector3(-0.4,0.39,z),Vector3(0.4,0.39,z),0.014,iron)
	b("SaggingCanvas",Vector3(0,0.42,0),Vector3(0.76,0.045,1.86),canvas_material(Color("777e66")),0.01)
	b("AbandonedPillow",Vector3(0,0.49,-0.61),Vector3(0.5,0.11,0.34),canvas_material(Color("b2ae98")),0.035)
	collision_box(Vector3(0,0.23,0),Vector3(0.83,0.46,1.98))

func fusebox() -> void:
	bounds = Vector3(0.47,0.5,0.23)
	b("FuseboxShell",Vector3(0,0.25,0),Vector3(0.32,0.5,0.14),olive)
	b("DarkInset",Vector3(0,0.25,0.074),Vector3(0.27,0.43,0.008),rubber)
	for x in [-0.085,0,0.085]:
		for y in [0.15,0.33]:
			b("CeramicFuse",Vector3(x,y,0.09),Vector3(0.045,0.1,0.025),enamel)
		pipe("ExposedWire",Vector3(x,0.04,0.085),Vector3(x,0.44,0.085),0.004,red)
	var door := b("BentOpenDoor",Vector3(-0.26,0.25,0.13),Vector3(0.3,0.48,0.018),olive)
	door.rotation.y = -0.55
	collision_box(Vector3(0,0.25,0),Vector3(0.32,0.5,0.14))

func valve_pipe() -> void:
	bounds = Vector3(0.48,1.04,0.34)
	lathe("OpenStandpipe",PackedVector2Array([Vector2(0.065,0),Vector2(0.065,1),Vector2(0.048,1),Vector2(0.048,0),Vector2(0.065,0)]),rust)
	for y in [0.08,0.64]:
		ring("PipeFlange",Vector3(0,y,0),0.105,0.018,iron)
	pipe("ValveSpindle",Vector3(0,0.7,0),Vector3(0,0.7,0.2),0.018,iron)
	var wheel := ring("RedValveWheel",Vector3(0,0.7,0.2),0.16,0.012,red)
	wheel.rotation.x = PI/2
	for angle in [0.0,TAU/3,2*TAU/3]:
		pipe("WheelSpoke",Vector3(0,0.7,0.2),Vector3(sin(angle)*0.15,0.7+cos(angle)*0.15,0.2),0.008,red)
	b("MountingFoot",Vector3(0,0.025,0),Vector3(0.32,0.05,0.3),iron)
	collision_box(Vector3(0,0.52,0),Vector3(0.15,1.04,0.15))

func pendant() -> void:
	bounds = Vector3(0.42,1.22,0.42)
	lathe("EnamelLampShade",PackedVector2Array([Vector2(0.2,0.25),Vector2(0.21,0.27),Vector2(0.18,0.3),Vector2(0.1,0.44),Vector2(0.04,0.47),Vector2(0,0.47)]),olive)
	pipe("SuspensionCable",Vector3(0,0.45,0),Vector3(0,1.2,0),0.005,rubber)
	b("CeilingRose",Vector3(0,1.2,0),Vector3(0.1,0.03,0.1),iron)
	pipe("FrostedBulb",Vector3(0,0.23,0),Vector3(0,0.34,0),0.028,enamel)
	var light := OmniLight3D.new()
	light.name = "OptionalPendantLight"
	light.position.y = 0.2
	light.light_color = Color("ffce99")
	light.light_energy = 0.9
	light.omni_range = 6
	light.visible = false
	root.add_child(light)
	collision_box(Vector3(0,0.36,0),Vector3(0.42,0.25,0.42))

func fence() -> void:
	bounds = Vector3(1.92,1.8,0.24)
	for side in [-1,1]:
		pipe("FencePost",Vector3(side*0.9,0,0),Vector3(side*0.9,1.78,0),0.026,rust)
	for y in [0.08,1.7]:
		pipe("FenceRail",Vector3(-0.9,y,0),Vector3(0.9,y,0),0.018,iron)
	for i in range(18):
		var x := -0.85+i*0.1
		var bend := 0.12 if i > 10 else 0.0
		pipe("MeshWire",Vector3(x,0.09,0),Vector3(x,1.69,bend),0.0035,iron)
	for i in range(16):
		var y := 0.14+i*0.1
		pipe("MeshWire",Vector3(-0.89,y,0),Vector3(0.89,y,0.12),0.0035,iron)
	collision_box(Vector3(0,0.9,0.05),Vector3(1.92,1.8,0.14))

func sandbags() -> void:
	bounds = Vector3(1.5,0.62,0.65)
	var cloth := canvas_material(Color("a09b75"))
	for layer in range(3):
		for i in range(3 if layer < 2 else 2):
			var bag := MeshInstance3D.new()
			bag.name = "CanvasSandbag"
			var shape := SphereMesh.new()
			shape.radius = 0.5
			shape.height = 1
			shape.radial_segments = 20
			shape.rings = 10
			bag.mesh = shape
			bag.scale = Vector3(0.58,0.23,0.39)
			bag.position = Vector3(-0.48+i*0.48+(0.24 if layer==2 else 0),0.115+layer*0.19,0.07 if layer==1 else -0.04)
			bag.rotation.y = rng.randf_range(-0.13,0.13)
			bag.material_override = cloth
			root.add_child(bag)
	collision_box(Vector3(0,0.3,0),Vector3(1.5,0.6,0.6))

func build_prop(id: String) -> Node3D:
	root = StaticBody3D.new() if id != "rubble_pile" else Node3D.new()
	root.name = id.to_pascal_case()
	rng.seed = hash(id)
	match id:
		"steel_drum", "rusted_drum": drum(id == "rusted_drum")
		"wooden_pallet": pallet()
		"shipping_crate", "equipment_case": crate(id == "equipment_case")
		"jerrycan": jerrycan()
		"gas_cylinder": gas_cylinder()
		"cable_spool": spool()
		"portable_generator": generator()
		"traffic_cone": cone()
		"concrete_barrier": barrier()
		"warning_sign": warning_sign()
		"work_light": work_light()
		"hand_truck": hand_truck()
		"tool_box": toolbox()
		"pipe_bundle": pipes()
		"electrical_cabinet": cabinet(true)
		"filing_cabinet": cabinet(false)
		"shelving_unit": shelving()
		"wooden_bench": bench()
		"desk_radio": radio()
		"metal_bucket": bucket(false)
		"enamel_mug": bucket(true)
		"rubble_pile": rubble()
		"radiator": radiator()
		"field_cot": cot()
		"worn_mattress": mattress()
		"wall_fusebox": fusebox()
		"valve_pipe": valve_pipe()
		"pendant_light": pendant()
		"damaged_fence": fence()
		"sandbag_stack": sandbags()
	root.set_meta("prop_id",id)
	root.set_meta("display_name",CATALOG[id][0])
	root.set_meta("category",CATALOG[id][1])
	root.set_meta("approximate_size_metres",bounds)
	root.set_meta("physics", "Static set dressing; small debris has no collision")
	return root
