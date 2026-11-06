extends RefCounted
## Builds and bakes an editable checkpoint house. Dimensions are in metres.

var root: Node3D
var rng := RandomNumberGenerator.new()
var masonry: StandardMaterial3D
var plaster: StandardMaterial3D
var concrete: StandardMaterial3D
var timber: StandardMaterial3D
var roofing: StandardMaterial3D
var iron: StandardMaterial3D
var paint: StandardMaterial3D
var dirt: StandardMaterial3D

func plain(color: Color, roughness: float = 0.8, metallic: float = 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = metallic
	return mat

func scanned(id: String, metres: float, tint: Color = Color.WHITE) -> StandardMaterial3D:
	var mat := plain(tint)
	var folder := "res://assets/materials/" + id + "/"
	mat.albedo_texture = load(folder + "albedo.jpg")
	mat.normal_enabled = true
	mat.normal_texture = load(folder + "normal.jpg")
	mat.normal_scale = 0.48
	mat.roughness_texture = load(folder + "roughness.jpg")
	mat.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	mat.ao_enabled = true
	mat.ao_texture = load(folder + "ao.jpg")
	mat.ao_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	mat.ao_light_affect = 0.35
	mat.uv1_triplanar = true
	mat.uv1_world_triplanar = true
	mat.uv1_scale = Vector3.ONE / metres
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return mat

func box(label: String, at: Vector3, size: Vector3, mat: Material, collision: bool = false, parent: Node3D = null) -> Node3D:
	if parent == null:
		parent = root
	var part: Node3D = StaticBody3D.new() if collision else Node3D.new()
	part.name = label
	part.position = at
	parent.add_child(part)
	var mesh := MeshInstance3D.new()
	mesh.name = "Surface"
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.material_override = mat
	part.add_child(mesh)
	if collision:
		var collider := CollisionShape3D.new()
		var volume := BoxShape3D.new()
		volume.size = size
		collider.shape = volume
		part.add_child(collider)
	return part

func pipe(label: String, start: Vector3, end: Vector3, radius: float, mat: Material, parent: Node3D = null) -> MeshInstance3D:
	if parent == null:
		parent = root
	var mesh := MeshInstance3D.new()
	mesh.name = label
	var shape := CylinderMesh.new()
	shape.top_radius = radius
	shape.bottom_radius = radius
	shape.height = start.distance_to(end)
	shape.radial_segments = 16
	mesh.mesh = shape
	mesh.material_override = mat
	parent.add_child(mesh)
	mesh.position = (start + end) * 0.5
	var axis := (end - start).normalized()
	mesh.quaternion = Quaternion(Vector3.UP, axis)
	return mesh

func polygon(label: String, points: PackedVector2Array, at: Vector3, mat: Material, parent: Node3D = null) -> MeshInstance3D:
	if parent == null:
		parent = root
	var indices := Geometry2D.triangulate_polygon(points)
	indices.reverse()
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in indices:
		var point := points[index]
		surface.set_normal(Vector3.BACK)
		surface.set_uv(Vector2(point.x, -point.y))
		surface.add_vertex(Vector3(point.x, point.y, 0))
	surface.generate_tangents()
	var mesh := MeshInstance3D.new()
	mesh.name = label
	mesh.mesh = surface.commit()
	mesh.material_override = mat
	mesh.position = at
	parent.add_child(mesh)
	return mesh

func text(words: String, at: Vector3, size: int, parent: Node3D = null) -> Label3D:
	if parent == null:
		parent = root
	var label := Label3D.new()
	label.text = words
	label.name = "PaintedLettering"
	label.position = at
	label.font_size = size
	label.pixel_size = 0.004
	label.outline_size = 0
	label.modulate = Color("c1bc9b")
	parent.add_child(label)
	return label

func wall(label: String, at: Vector3, width: float, holes: Array[Rect2], angle: float) -> Node3D:
	var face := Node3D.new()
	face.name = label
	face.position = at
	face.rotation.y = angle
	root.add_child(face)
	var boundaries: Array[float] = [-width / 2, width / 2]
	for hole in holes:
		boundaries.append(hole.position.x)
		boundaries.append(hole.end.x)
	boundaries.sort()
	for i in range(boundaries.size() - 1):
		var left := boundaries[i]
		var right := boundaries[i + 1]
		if right - left < 0.001:
			continue
		var bottom := 0.14
		var top := 3.15
		var opening := false
		for hole in holes:
			if (left + right) * 0.5 > hole.position.x and (left + right) * 0.5 < hole.end.x:
				opening = true
				bottom = hole.position.y
				top = hole.end.y
		if not opening:
			box("MasonryPier", Vector3((left + right) / 2, 1.645, 0), Vector3(right - left, 3.01, 0.34), masonry, true, face)
			polygon("RemainingPierRender", PackedVector2Array([
				Vector2(left + 0.025, 0.75), Vector2(lerpf(left, right, 0.3), 0.93),
				Vector2(lerpf(left, right, 0.5), 0.83), Vector2(right - 0.035, 1.09),
				Vector2(right - 0.035, 3.1), Vector2(left + 0.025, 3.1)
			]), Vector3(0, 0, 0.177), plaster, face)
		else:
			if bottom > 0.15:
				box("WallBelowWindow", Vector3((left + right) / 2, (bottom + 0.14) / 2, 0), Vector3(right - left, bottom - 0.14, 0.34), masonry, true, face)
				polygon("RenderBelowSill", PackedVector2Array([
					Vector2(left + 0.02, bottom - 0.36), Vector2(lerpf(left, right, 0.35), bottom - 0.49),
					Vector2(lerpf(left, right, 0.56), bottom - 0.28), Vector2(right - 0.04, bottom - 0.4),
					Vector2(right - 0.02, bottom - 0.01), Vector2(left + 0.02, bottom - 0.01)
				]), Vector3(0, 0, 0.177), plaster, face)
			box("Lintel", Vector3((left + right) / 2, (top + 3.15) / 2, 0), Vector3(right - left, 3.15 - top, 0.34), masonry, true, face)
	# Subtle continuous upper render and individually broken lower edges.
	polygon("CrackedUpperRender", PackedVector2Array([
		Vector2(-width/2, 2.72), Vector2(-width/2 + 0.4, 2.69), Vector2(-width/2 + 0.9, 2.81),
				Vector2(-0.9, 2.67), Vector2(0.2, 2.78), Vector2(1.3, 2.72), Vector2(width/2, 2.79),
		Vector2(width/2, 3.14), Vector2(-width/2, 3.14)]), Vector3(0, 0, 0.176), plaster, face)
	return face

func window_frame(parent: Node3D, center: Vector2, boarded: bool = false) -> void:
	var window := Node3D.new()
	window.name = "RecessedTimberWindow"
	window.position = Vector3(center.x, center.y, 0)
	parent.add_child(window)
	# The wall is actually cut away; the reveal has 34 cm of depth.
	for side in [-1, 1]:
		box("WindowJamb", Vector3(side * 0.73, 0, 0.045), Vector3(0.11, 1.46, 0.22), timber, true, window)
		box("FrameRail", Vector3(0, side * 0.68, 0.045), Vector3(1.45, 0.105, 0.22), timber, true, window)
	box("Mullion", Vector3(0, 0, 0.025), Vector3(0.065, 1.33, 0.13), timber, false, window)
	box("Transom", Vector3(0, 0.15, 0.025), Vector3(1.32, 0.055, 0.13), timber, false, window)
	var sill := box("ConcreteSill", Vector3(0, -0.77, 0.12), Vector3(1.7, 0.11, 0.55), concrete, true, window)
	sill.rotation.x = -0.04
	var glass := plain(Color(0.29, 0.38, 0.36, 0.2), 0.17)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	glass.metallic = 0.15
	# Uneven broken shards leave the room visible through the window.
	polygon("BrokenGlassLeft", PackedVector2Array([Vector2(-0.66, -0.6), Vector2(-0.32, -0.6), Vector2(-0.4, -0.13), Vector2(-0.56, 0.05), Vector2(-0.66, -0.05)]), Vector3(0, 0, 0.04), glass, window)
	polygon("BrokenGlassTop", PackedVector2Array([Vector2(0.04, 0.2), Vector2(0.25, 0.2), Vector2(0.47, 0.36), Vector2(0.62, 0.28), Vector2(0.66, 0.62), Vector2(0.04, 0.62)]), Vector3(0, 0, 0.04), glass, window)
	box("IntactUpperPane", Vector3(-0.35, 0.415, 0.04), Vector3(0.59, 0.43, 0.009), glass, false, window)
	if boarded:
		for i in range(2):
			var plank := box("LooseBoard", Vector3(0, -0.13 + i * 0.38, 0.2), Vector3(1.7, 0.16, 0.045), timber, false, window)
			plank.rotation.z = -0.08 + i * 0.13
			for side in [-1, 1]:
				pipe("Nail", Vector3(side * 0.64, 0, 0.018), Vector3(side * 0.64, 0, 0.032), 0.013, iron, plank)

func roof_surface() -> void:
	var roof_mat := roofing.duplicate() as StandardMaterial3D
	roof_mat.uv1_triplanar = false
	roof_mat.uv1_scale = Vector3.ONE
	roof_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for side in [-1, 1]:
		for section in range(44):
			var z0 := -3.5 + section * 7.0 / 44
			var z1 := -3.5 + (section + 1) * 7.0 / 44
			var corners: Array[Vector3] = []
			for v in [Vector2(0, z0), Vector2(3.95 * side, z0), Vector2(3.95 * side, z1), Vector2(0, z1)]:
				corners.append(Vector3(v.x, 4.22 - absf(v.x) * 0.29 + sin(v.y * TAU / 0.16) * 0.016, v.y))
			var order := [0, 2, 1, 0, 3, 2] if side > 0 else [0, 1, 2, 0, 2, 3]
			for index in order:
				var vertex := corners[index]
				surface.set_uv(Vector2(vertex.x / 2, vertex.z / 2))
				surface.add_vertex(vertex)
	surface.generate_normals()
	surface.generate_tangents()
	var mesh := MeshInstance3D.new()
	mesh.name = "CorrugatedPitchedRoof"
	mesh.mesh = surface.commit()
	mesh.material_override = roof_mat
	root.add_child(mesh)
	for side in [-1, 1]:
		pipe("Gutter", Vector3(side * 3.93, 3.04, -3.45), Vector3(side * 3.93, 3.04, 3.45), 0.065, iron)
		box("EavesFascia", Vector3(side * 3.77, 3.09, 0), Vector3(0.1, 0.18, 7), timber)
		for z in [-3.28, 3.28]:
			pipe("RoofBargeboard", Vector3(0, 4.2, z), Vector3(side * 3.9, 3.07, z), 0.07, timber)
	pipe("RidgeCap", Vector3(0, 4.25, -3.55), Vector3(0, 4.25, 3.55), 0.09, iron)
	pipe("Drainpipe", Vector3(3.94, 2.9, 2.7), Vector3(3.94, 0.45, 2.7), 0.055, iron)
	pipe("DrainElbow", Vector3(3.94, 0.45, 2.7), Vector3(4.16, 0.2, 2.9), 0.055, iron)
	for y in [0.8, 2.3]:
		box("PipeBracket", Vector3(3.78, y, 2.7), Vector3(0.36, 0.04, 0.16), iron)
	for z in [-2.6, -1, 1, 2.6]:
		box("CeilingTieBeam", Vector3(0, 3.06, z), Vector3(7, 0.16, 0.14), timber)

func interior() -> void:
	# Furniture provides familiar scale and a believable use for the room.
	var interior_render := plaster.duplicate() as StandardMaterial3D
	interior_render.albedo_color = Color("c9c9b8")
	var lower_paint := plaster.duplicate() as StandardMaterial3D
	lower_paint.albedo_color = Color("718c7c")
	box("InteriorUpperPlaster", Vector3(0, 2.12, -2.81), Vector3(6.65, 1.87, 0.018), interior_render)
	box("InteriorPaintedDado", Vector3(0, 0.68, -2.798), Vector3(6.65, 1.0, 0.02), lower_paint)
	box("PaintedDadoBorder", Vector3(0, 1.2, -2.78), Vector3(6.65, 0.045, 0.02), paint)
	box("DeskTop", Vector3(0, 0.77, -1), Vector3(1.7, 0.075, 0.8), timber, true)
	for x in [-0.68, 0.68]:
		for z in [-1.28, -0.72]:
			box("DeskLeg", Vector3(x, 0.46, z), Vector3(0.06, 0.57, 0.06), iron)
	box("DeskDrawer", Vector3(0.53, 0.62, -1), Vector3(0.5, 0.22, 0.65), paint)
	box("DrawerHandle", Vector3(0.53, 0.62, -0.66), Vector3(0.16, 0.025, 0.025), iron)
	for i in range(3):
		var paper := box("AbandonedPaper", Vector3(0.48 + i * 0.06, 0.818 + i * 0.003, -1.06), Vector3(0.22, 0.003, 0.3), plain(Color("b9b59f")))
		paper.rotation.y = i * 0.13
	var chair := Node3D.new()
	chair.name = "OldChair"
	chair.position = Vector3(0.3, 0, -2)
	chair.rotation.y = 0.2
	root.add_child(chair)
	box("Seat", Vector3(0, 0.58, 0), Vector3(0.45, 0.06, 0.45), timber, false, chair)
	box("Back", Vector3(0, 0.95, -0.2), Vector3(0.43, 0.35, 0.05), timber, false, chair)
	for x in [-0.18, 0.18]:
		for z in [-0.18, 0.18]:
			pipe("ChairLeg", Vector3(x, 0.17, z), Vector3(x, 0.58, z), 0.021, iron, chair)
		pipe("ChairBackSupport", Vector3(x, 0.58, -0.2), Vector3(x, 1.13, -0.2), 0.018, iron, chair)
	box("SteelLocker", Vector3(-2.6, 1.03, -2.3), Vector3(0.85, 1.76, 0.6), paint, true)
	for y in [0.5, 1.45]:
		for n in range(5):
			box("LockerVent", Vector3(-2.6, y + n * 0.05, -1.992), Vector3(0.55, 0.016, 0.008), dirt)
	box("LockerHandle", Vector3(-2.32, 1.03, -1.97), Vector3(0.025, 0.15, 0.03), iron)
	box("NoticeBoard", Vector3(1.8, 1.9, -2.81), Vector3(1.25, 0.9, 0.055), timber)
	for i in range(4):
		box("FadedNotice", Vector3(1.46 + (i % 2) * 0.5, 1.7 + (i / 2) * 0.35, -2.775), Vector3(0.3, 0.28, 0.005), plain(Color("a9a991")))
	# An old wall lamp has a small actual light, rather than glowing windows.
	box("WallLampBase", Vector3(2.8, 2.6, 2.77), Vector3(0.25, 0.35, 0.12), iron)
	var bulb_mat := plain(Color("d6ad71"))
	bulb_mat.emission_enabled = true
	bulb_mat.emission = Color("e5ac62")
	bulb_mat.emission_energy_multiplier = 0.8
	box("WallLampGlass", Vector3(2.8, 2.6, 2.66), Vector3(0.18, 0.24, 0.09), bulb_mat)
	var light := OmniLight3D.new()
	light.name = "WarmInteriorLamp"
	light.position = Vector3(2.75, 2.5, 2.4)
	light.light_color = Color("ffce98")
	light.light_energy = 0.8
	light.omni_range = 6
	light.shadow_enabled = true
	root.add_child(light)

func build() -> Node3D:
	rng.seed = 7631
	root = Node3D.new()
	root.name = "CheckpointHouse"
	masonry = scanned("rough_plaster_brick_02", 1.5, Color("bfc2bb"))
	masonry.roughness = 1.0
	masonry.metallic_specular = 0.22
	plaster = scanned("grey_plaster", 1.0, Color("e8dfc3"))
	plaster.metallic_specular = 0.2
	concrete = scanned("concrete_floor_worn_001", 3.0)
	timber = scanned("wood_peeling_paint_weathered", 0.762, Color("9caaa0"))
	roofing = scanned("rusty_corrugated_iron", 2.0, Color("b0b4b2"))
	iron = plain(Color("454d48"), 0.74, 0.35)
	paint = plain(Color("455a52"), 0.82, 0.1)
	dirt = plain(Color("242d25"), 1)
	# World-aligned runoff streaks add weathering at a different scale than the scan.
	var streak_noise := FastNoiseLite.new()
	streak_noise.seed = 272
	streak_noise.frequency = 0.035
	var streak_texture := NoiseTexture2D.new()
	streak_texture.width = 256
	streak_texture.height = 256
	streak_texture.generate_mipmaps = true
	streak_texture.noise = streak_noise
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.09, 0.11, 0.08, 0.0))
	gradient.set_color(1, Color(0.09, 0.11, 0.08, 0.34))
	streak_texture.color_ramp = gradient
	var streaks := plain(Color.WHITE, 1)
	streaks.albedo_texture = streak_texture
	streaks.uv1_triplanar = true
	streaks.uv1_world_triplanar = true
	streaks.uv1_scale = Vector3(1.2, 0.045, 1.2)
	streaks.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	streaks.metallic_specular = 0.05
	plaster.next_pass = streaks
	box("Foundation", Vector3(0, 0.04, 0), Vector3(7.24, 0.24, 6.24), concrete, true)
	box("WornFloor", Vector3(0, 0.15, 0), Vector3(6.98, 0.06, 5.98), concrete, true)
	var front := wall("FrontFacade", Vector3(0, 0, 3), 7.0, [Rect2(-2.78, 1.12, 1.56, 1.46), Rect2(-0.6, 0.14, 1.2, 2.27), Rect2(1.22, 1.12, 1.56, 1.46)], 0)
	window_frame(front, Vector2(-2, 1.85))
	window_frame(front, Vector2(2, 1.85), true)
	var east := wall("RoadFacingFacade", Vector3(3.5, 0, 0), 6.0, [Rect2(-2.18, 1.12, 1.56, 1.46), Rect2(0.62, 1.12, 1.56, 1.46)], PI / 2)
	window_frame(east, Vector2(-1.4, 1.85))
	window_frame(east, Vector2(1.4, 1.85), true)
	wall("RearFacade", Vector3(0, 0, -3), 7.0, [], PI)
	wall("WestFacade", Vector3(-3.5, 0, 0), 6.0, [], -PI / 2)
	for facade in [front, east]:
		var half_width := 3.5 if facade == front else 3.0
		polygon("FlakingLowerRender", PackedVector2Array([Vector2(-half_width, 0.42), Vector2(-half_width + 0.3, 0.6), Vector2(-half_width + 0.7, 0.49), Vector2(-half_width + 1.1, 0.77), Vector2(-0.85, 0.62), Vector2(-0.85, 0.93), Vector2(-half_width, 1.02)]), Vector3(0, 0, 0.177), plaster, facade)
		for i in range(14):
			var x := rng.randf_range(-half_width, half_width)
			if facade == front and absf(x) < 0.65:
				continue
			var stain_mat := plain(Color(0.13, 0.17, 0.12, rng.randf_range(0.08, 0.2)), 1)
			stain_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			var height := rng.randf_range(0.1, 0.5)
			polygon("RisingDamp", PackedVector2Array([Vector2(x - 0.13, 0.15), Vector2(x + 0.15, 0.15), Vector2(x + 0.1, height), Vector2(x - 0.04, height + 0.14)]), Vector3(0, 0, 0.183), stain_mat, facade)
	# Exterior door is fixed open, with hinges, separate planks and a latch.
	for x in [-0.63, 0.63]:
		box("DoorJamb", Vector3(x, 1.27, 3.02), Vector3(0.1, 2.3, 0.3), timber, true)
	box("DoorLintel", Vector3(0, 2.45, 3.02), Vector3(1.4, 0.12, 0.32), timber)
	var door := Node3D.new()
	door.name = "OpenTimberDoor"
	door.position = Vector3(-0.57, 0.17, 3.06)
	door.rotation.y = deg_to_rad(-104)
	root.add_child(door)
	for i in range(6):
		box("DoorPlank", Vector3(0.095 + i * 0.183, 1.08, 0), Vector3(0.177, 2.15, 0.06), timber, true, door)
	for y in [0.25, 1.9]:
		box("DoorBrace", Vector3(0.56, y, -0.05), Vector3(1.08, 0.1, 0.045), iron, false, door)
	pipe("DoorHandle", Vector3(0.99, 1, 0.035), Vector3(0.99, 1.13, 0.035), 0.02, iron, door)
	# Low threshold and approach ramp let the character walk in without jumping.
	box("DoorThreshold", Vector3(0, 0.07, 3.23), Vector3(1.3, 0.14, 0.4), concrete)
	var ramp := box("ShallowApproach", Vector3(0, 0.02, 3.8), Vector3(1.7, 0.08, 1.5), concrete, true)
	ramp.rotation.x = deg_to_rad(5)
	for z in [-3.01, 3.01]:
		var gable := polygon("GableMasonry", PackedVector2Array([Vector2(-3.5, 3.14), Vector2(3.5, 3.14), Vector2(0, 4.16)]), Vector3(0, 0, z), masonry)
		if z < 0:
			gable.rotation.y = PI
	box("Ceiling", Vector3(0, 3.12, 0), Vector3(6.7, 0.08, 5.7), plaster, true)
	roof_surface()
	box("ChimneyStack", Vector3(-1.7, 4.27, -1.5), Vector3(0.56, 1.25, 0.58), masonry)
	box("ChimneyCap", Vector3(-1.7, 4.91, -1.5), Vector3(0.75, 0.12, 0.77), concrete)
	box("ChimneySoot", Vector3(-1.7, 4.977, -1.5), Vector3(0.43, 0.012, 0.45), dirt)
	box("NumberPlate", Vector3(-0.98, 2.32, 3.215), Vector3(0.38, 0.3, 0.035), paint)
	box("GuardhouseSign", Vector3(0, 2.89, 3.23), Vector3(1.7, 0.28, 0.035), paint)
	box("ElectricalBox", Vector3(3.7, 1.6, 1.95), Vector3(0.24, 0.5, 0.36), paint)
	pipe("ElectricalConduit", Vector3(3.72, 1.85, 1.95), Vector3(3.72, 2.85, 1.95), 0.018, iron)
	# Local ground dressing breaks the perfectly straight meeting with the terrain.
	for i in range(34):
		var at := Vector3(rng.randf_range(-3.5, 3.5), 0.045, rng.randf_range(3.35, 4.4))
		if absf(at.x) < 1:
			continue
		var rubble := box("PlasterRubble", at, Vector3(rng.randf_range(0.04, 0.19), rng.randf_range(0.02, 0.07), rng.randf_range(0.04, 0.15)), masonry)
		rubble.rotation = Vector3(rng.randf_range(-0.2, 0.2), rng.randf_range(0, TAU), 0)
	for side in [-1, 1]:
		for i in range(12):
			var at := Vector3(side * rng.randf_range(3.7, 4.3), 0.02, rng.randf_range(-3.3, 3.3))
			for blade in range(4):
				var height := rng.randf_range(0.14, 0.45)
				var grass := polygon("DryWeed", PackedVector2Array([Vector2(-0.018, 0), Vector2(0.035, height * 0.5), Vector2(0.04, height), Vector2(0.0, 0.1)]), at, plain(Color("5c6550")))
				grass.rotation.y = rng.randf_range(0, TAU)
	interior()
	return root
