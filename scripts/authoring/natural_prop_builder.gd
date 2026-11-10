extends "res://scripts/authoring/prop_builder.gd"
## Original geometry, metre scale, no lettering, merged by material.

const NATURAL_CATALOG := {
	"fern_clump":Vector3(1.1,0.65,1.1),
	"dry_bramble":Vector3(1.4,1.1,1.4),
	"reed_clump":Vector3(0.8,1.5,0.8),
	"mossy_boulder":Vector3(1.4,0.9,1.2),
	"fallen_log":Vector3(2.7,0.55,0.75),
	"tree_stump":Vector3(0.95,0.65,0.95),
	"dead_branch_pile":Vector3(1.8,0.35,1.3),
	"forest_pine":Vector3(5.8,8.6,5.8),
	"bare_tree":Vector3(4.4,6.5,4.4),
	"low_shrub":Vector3(1.5,1.1,1.5)
}

var bark: Material
var endgrain: Material
var needles: Material
var fronds: Material
var dry: Material
var stone: Material

func prepare_natural_materials() -> void:
	var folder := "res://assets/nature/"
	DirAccess.make_dir_recursive_absolute(folder)
	var shader := Shader.new()
	shader.code = """shader_type spatial;
varying vec3 local;
void vertex(){local=VERTEX;}
void fragment(){
float ridge=sin(local.y*1.3+sin(local.x*31.0+local.z*25.0)*3.0);
float grain=sin(local.x*113.0+local.z*87.0+sin(local.y*7.0));
ALBEDO=(mix(vec3(0.115,0.105,0.082),vec3(0.29,0.265,0.205),ridge*0.23+0.5)+grain*0.025)*0.3;
ROUGHNESS=0.98;
}"""
	var bark_mat := ShaderMaterial.new()
	bark_mat.shader = shader
	var leaf_shader := Shader.new()
	leaf_shader.code = """shader_type spatial;
render_mode cull_disabled, specular_disabled;
void vertex(){vec3 p=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; VERTEX.x+=sin(TIME*0.9+p.x*0.6+p.z*0.4)*UV.y*0.02;}
void fragment(){ALBEDO=COLOR.rgb*vec3(0.15,0.42,0.12); ROUGHNESS=0.96; NORMAL=FRONT_FACING?NORMAL:-NORMAL; BACKLIGHT=ALBEDO*0.08;}
"""
	var foliage := ShaderMaterial.new()
	foliage.shader = leaf_shader
	var definitions := {"bark":bark_mat,"foliage":foliage,"endgrain":plain(Color("6d5d44")),"dry":plain(Color("3f3c2f")),"stone":plain(Color("616b53"))}
	definitions.stone.vertex_color_use_as_albedo = true
	for key: String in definitions:
		var path := folder+key+".tres"
		if not FileAccess.file_exists(path) or "--refresh-natural-materials" in OS.get_cmdline_user_args():
			ResourceSaver.save(definitions[key],path)
	bark = load(folder+"bark.tres")
	fronds = load(folder+"foliage.tres")
	needles = fronds
	endgrain = load(folder+"endgrain.tres")
	dry = load(folder+"dry.tres")
	stone = load(folder+"stone.tres")

func branch(start: Vector3, end: Vector3, radius: float, top: float = -1.0, material: Material = null) -> void:
	var mesh := MeshInstance3D.new()
	mesh.name = "Branch"
	var shape := CylinderMesh.new()
	shape.bottom_radius = radius
	shape.top_radius = top if top >= 0 else radius*0.5
	shape.height = start.distance_to(end)
	shape.radial_segments = 8
	mesh.mesh = shape
	mesh.material_override = bark if material == null else material
	mesh.position = (start+end)*0.5
	mesh.quaternion = Quaternion(Vector3.UP,(end-start).normalized())
	root.add_child(mesh)

func leaf(surface: SurfaceTool, start: Vector3, tip: Vector3, width: float, color: Color, along: float) -> void:
	var direction := (tip-start).normalized()
	var side := direction.cross(Vector3.UP).normalized()
	if side.length()<0.1:
		side = Vector3.RIGHT
	var mid := start.lerp(tip,0.45)+Vector3.UP*0.012
	var vertices := [start,mid-side*width,tip,mid+side*width]
	for index in [0,1,2,0,2,3]:
		surface.set_normal(Vector3.UP)
		surface.set_uv(Vector2(0.5,along))
		surface.set_color(color)
		surface.add_vertex(vertices[index])

func spray(origin: Vector3, direction: Vector3, length: float, spread: float, count: int, color: Color, pine: bool = false) -> void:
	var forward := direction.normalized()
	var across := forward.cross(Vector3.UP).normalized()
	if across.is_zero_approx():
		across = Vector3.RIGHT
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(count):
		var t := float(i+1)/(count+1)
		var height := (sin(t*PI)*0.17 if not pine else t*0.06)
		var center := origin+forward*length*t+Vector3.UP*height
		var extent := sin(t*PI)*spread
		for side in [-1,1]:
			var tip: Vector3 = center+across*side*extent+forward*(0.06 if pine else 0.04)
			leaf(surface,center,tip,0.065 if pine else 0.017,color.lightened(rng.randf_range(0,0.08)),t)
	leaf(surface,origin+forward*length*0.8,origin+forward*length,0.015,color,1)
	var mesh := MeshInstance3D.new()
	mesh.name = "NeedleBough" if pine else "FernFrond"
	mesh.mesh = surface.commit()
	mesh.material_override = fronds
	root.add_child(mesh)
	branch(origin,origin+forward*length,0.006 if pine else 0.003,0.001,dry)

func fern() -> void:
	for i in range(8):
		var angle := i*TAU/8+rng.randf_range(-0.12,0.12)
		var direction := Vector3(sin(angle),0.55,cos(angle))
		spray(Vector3(0,0.035,0),direction,rng.randf_range(0.48,0.7),0.12,10,Color("3d5736"))

func bramble(shrub: bool) -> void:
	for i in range(12):
		var angle := i*2.399
		var end := Vector3(sin(angle)*rng.randf_range(0.28,0.65),rng.randf_range(0.45,1.05),cos(angle)*rng.randf_range(0.28,0.65))
		var middle := end*0.55+Vector3.UP*0.1
		branch(Vector3.ZERO,middle,0.012,0.007)
		branch(middle,end,0.007,0.002)
		var fork := end+Vector3(rng.randf_range(-0.18,0.18),0.12,rng.randf_range(-0.18,0.18))
		branch(middle,fork,0.005,0.001)
		if shrub:
			spray(middle,(end-middle).normalized(),0.33,0.1,5,Color("536044"))

func reeds() -> void:
	for i in range(16):
		var at := Vector3(rng.randf_range(-0.25,0.25),0,rng.randf_range(-0.25,0.25))
		var height := rng.randf_range(0.7,1.45)
		var tip := at+Vector3(0.06,height,0.04)
		branch(at,tip,0.006,0.002,dry)
		if i%3==0:
			branch(tip-Vector3.UP*0.12,tip+Vector3.UP*0.02,0.017,0.014,bark)
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		leaf(surface,at+Vector3.UP*height*0.3,at+Vector3(rng.randf_range(-0.25,0.25),height*0.9,0.18),0.018,Color("73774c"),1)
		var mesh := MeshInstance3D.new()
		mesh.mesh = surface.commit()
		mesh.material_override = fronds
		root.add_child(mesh)

func boulder() -> void:
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1
	sphere.radial_segments = 64
	sphere.rings = 32
	var arrays := sphere.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var noise := FastNoiseLite.new()
	noise.seed = 6662
	noise.frequency = 3.1
	for i in range(vertices.size()):
		var p := vertices[i]
		var wobble := 1+noise.get_noise_3dv(p)*0.32
		p *= Vector3(1.38,0.86,1.16)*wobble
		# Broad fractured faces and a flattened buried base break the sphere shape.
		p.x = minf(p.x,0.51+p.y*0.2)
		p.z = maxf(p.z,-0.45+p.x*0.16)
		p.y = minf(p.y,0.34-p.x*0.12+p.z*0.1)
		p.y = maxf(p.y,-0.35)
		p.y += 0.36
		vertices[i] = p
	arrays[Mesh.ARRAY_VERTEX] = vertices
	var array_mesh := ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var tool := SurfaceTool.new()
	tool.create_from(array_mesh,0)
	tool.generate_normals()
	tool.generate_tangents()
	var mesh := MeshInstance3D.new()
	mesh.name = "MossCoveredStone"
	mesh.mesh = tool.commit()
	var granite := ShaderMaterial.new()
	granite.shader = load("res://assets/nature/mossy_granite.gdshader")
	mesh.material_override = granite
	root.add_child(mesh)
	var collider := CollisionShape3D.new()
	# Match the new shape rather than retaining the old spherical collision.
	collider.shape = mesh.mesh.create_convex_shape(true,false)
	root.add_child(collider)

func log_or_stump(stump: bool) -> void:
	if stump:
		branch(Vector3(0,0.01,0),Vector3(0.025,0.58,0),0.26,0.21)
		branch(Vector3(0.025,0.58,0),Vector3(0.025,0.59,0),0.205,0.205,endgrain)
		for i in range(5):
			var a := i*TAU/5
			branch(Vector3(sin(a)*0.44,0.035,cos(a)*0.44),Vector3(0,0.28,0),0.045,0.085)
		collision_cylinder(0.27,0.6)
	else:
		branch(Vector3(-1.3,0.24,0),Vector3(1.3,0.25,0.05),0.24,0.19)
		branch(Vector3(-1.305,0.24,0),Vector3(-1.315,0.24,0),0.22,0.22,endgrain)
		branch(Vector3(1.305,0.25,0.05),Vector3(1.315,0.25,0.05),0.18,0.18,endgrain)
		branch(Vector3(-0.2,0.35,0),Vector3(0.15,0.55,-0.3),0.07,0.035)
		collision_box(Vector3(0,0.24,0),Vector3(2.6,0.48,0.48))

func branch_pile() -> void:
	for i in range(9):
		var start := Vector3(rng.randf_range(-0.8,-0.3),0.05+i*0.018,rng.randf_range(-0.4,0.4))
		var end := Vector3(rng.randf_range(0.3,0.8),0.08+i*0.018,rng.randf_range(-0.4,0.4))
		branch(start,end,0.025,0.012)
		branch(start.lerp(end,0.6),end+Vector3(-0.15,0.14,0.25),0.013,0.003)

func pine() -> void:
	branch(Vector3.ZERO,Vector3(0.12,8.5,0),0.18,0.025)
	collision_cylinder(0.18,8.5)
	for tier in range(7):
		var y := 2.1+tier*0.87
		var length := 2.5-tier*0.29
		for limb in range(5):
			var angle := limb*TAU/5+tier*1.9
			var origin := Vector3(0,y,0)
			var direction := Vector3(sin(angle),-0.12,cos(angle))
			branch(origin,origin+direction*length,0.025,0.006)
			spray(origin+direction*0.15,direction,length,0.6-tier*0.04,12,Color("304a35"),true)
			for fork in [-1,1]:
				var branch_direction := direction.rotated(Vector3.UP,fork*0.6)
				spray(origin+direction*length*0.55,branch_direction,length*0.4,0.15,6,Color("3d5439"),true)

func dead_tree() -> void:
	branch(Vector3.ZERO,Vector3(0.13,6.4,0),0.19,0.025)
	collision_cylinder(0.18,6.4)
	for i in range(11):
		var y := 1.8+i*0.36
		var angle := i*2.399
		var start := Vector3(0,y,0)
		var end := start+Vector3(sin(angle),0.7,cos(angle))*rng.randf_range(0.7,1.7)
		var middle := start.lerp(end,0.65)
		branch(start,middle,0.055,0.025)
		branch(middle,end,0.025,0.005)
		branch(middle,end+Vector3(0.3,0.4,-0.2),0.018,0.003)

func merge_meshes() -> void:
	var groups := {}
	var source_meshes := root.find_children("*","MeshInstance3D",true,false)
	for source in source_meshes:
		var mat: Material = source.material_override
		var id := mat.get_instance_id()
		if not groups.has(id):
			var surface := SurfaceTool.new()
			surface.begin(Mesh.PRIMITIVE_TRIANGLES)
			groups[id] = [surface,mat]
		for surface_index in range(source.mesh.get_surface_count()):
			# Mixing indexed primitives with non-indexed custom meshes otherwise
			# leaves earlier vertices unreferenced when the combined mesh gains indices.
			var normalized:=SurfaceTool.new()
			normalized.create_from(source.mesh,surface_index)
			normalized.deindex()
			groups[id][0].append_from(normalized.commit(),0,source.transform)
	for id in groups:
		var mesh := MeshInstance3D.new()
		mesh.name = "NaturalSurface"
		mesh.mesh = groups[id][0].commit()
		mesh.material_override = groups[id][1]
		root.add_child(mesh)
	for mesh in source_meshes:
		mesh.free()

func build_natural(id: String) -> Node3D:
	root = StaticBody3D.new() if id in ["mossy_boulder","fallen_log","tree_stump","forest_pine","bare_tree"] else Node3D.new()
	root.name = id.to_pascal_case()
	rng.seed = hash(id)
	match id:
		"fern_clump": fern()
		"dry_bramble": bramble(false)
		"low_shrub": bramble(true)
		"reed_clump": reeds()
		"mossy_boulder": boulder()
		"fallen_log": log_or_stump(false)
		"tree_stump": log_or_stump(true)
		"dead_branch_pile": branch_pile()
		"forest_pine": pine()
		"bare_tree": dead_tree()
	merge_meshes()
	root.set_meta("prop_id",id)
	root.set_meta("approximate_size_metres",NATURAL_CATALOG[id])
	root.set_meta("world_text_policy","No attached text")
	return root
