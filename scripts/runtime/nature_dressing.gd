extends Node3D
## First natural dressing pass: deterministic, non-colliding, chunked vegetation.

var dressing: Node3D
var additional_dressing: Array = []
var rng := RandomNumberGenerator.new()
var exclusion_zones: Array[Rect2] = []
var grass_count := 0
var stone_count := 0
var leaf_count := 0

func _ready() -> void:
	name = "NaturalDressing"
	rng.seed = 91477
	# Architecture, puddle, road, and the walking approach to the doorway.
	exclusion_zones = [
		Rect2(-14,7.5,8,7.3),Rect2(6,7.5,8,7.3),Rect2(-15.4,-37.5,12.8,13.1),
		Rect2(12,-24,8.5,24),Rect2(-24,-17,12,14),Rect2(-11.4,13.7,2.8,4.3),
		Rect2(2.5,25,4,6)
	]
	var groups := [dressing]
	groups.append_array(additional_dressing)
	for group in groups:
		if not is_instance_valid(group):
			continue
		for prop in group.get_children():
			if not prop.has_meta("approximate_size_metres"):
				continue
			var size: Vector3 = prop.get_meta("approximate_size_metres")
			var rectangle := Rect2(Vector2(prop.position.x,prop.position.z),Vector2.ZERO)
			for x in [-1,1]:
				for z in [-1,1]:
					var p: Vector3 = prop.transform*Vector3(x*size.x/2,0,z*size.z/2)
					rectangle = rectangle.expand(Vector2(p.x,p.z))
			exclusion_zones.append(rectangle.grow(0.12))
	build_grass()
	build_stones_and_leaves()
	set_meta("grass_clumps",grass_count)
	set_meta("stones",stone_count)
	set_meta("leaves",leaf_count)

func allowed(at: Vector3) -> bool:
	if absf(at.x) < 4.15 or at.z > 30 or at.z < -51 or absf(at.x)>30:
		return false
	for area in exclusion_zones:
		if area.has_point(Vector2(at.x,at.z)):
			return false
	return true

func grass_mesh() -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for blade in range(9):
		var angle := float(blade)*2.399
		var radial := Vector3(sin(angle),0,cos(angle))
		var across := Vector3(cos(angle),0,-sin(angle))
		var origin := radial*rng.randf_range(0,0.09)
		var height := rng.randf_range(0.23,0.49)
		var width := rng.randf_range(0.008,0.018)
		for segment in range(3):
			var t0 := float(segment)/3
			var t1 := float(segment+1)/3
			var corners: Array[Vector3] = []
			for data in [Vector2(-1,t0),Vector2(1,t0),Vector2(1,t1),Vector2(-1,t1)]:
				var t: float = data.y
				corners.append(origin+Vector3.UP*height*t+radial*t*t*0.1+across*data.x*width*(1-t))
			var uvs := [Vector2(0,t0),Vector2(1,t0),Vector2(1,t1),Vector2(0,t1)]
			for index in [0,2,1,0,3,2]:
				surface.set_normal(radial)
				surface.set_uv(uvs[index])
				surface.add_vertex(corners[index])
	return surface.commit()

func build_grass() -> void:
	var shader := Shader.new()
	shader.code = """shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_disabled;
varying float height;
void vertex(){
  height=UV.y;
  vec3 world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
  float wind=sin(TIME*1.15+world.x*0.7+world.z*0.5+INSTANCE_CUSTOM.r*6.28);
  VERTEX.x+=wind*UV.y*UV.y*0.045;
  VERTEX.z+=wind*UV.y*UV.y*0.025;
}
void fragment(){
  ALBEDO=mix(vec3(0.13,0.17,0.075),vec3(0.38,0.40,0.21),height)*COLOR.rgb;
  ROUGHNESS=1.0;
  NORMAL=FRONT_FACING?NORMAL:-NORMAL;
}"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	var mesh := grass_mesh()
	var patches := FastNoiseLite.new()
	patches.seed = 721
	patches.frequency = 0.15
	# Small batches allow distant parts to be culled independently.
	for tx in range(-3,3):
		for tz in range(-5,3):
			var points: Array[Vector3] = []
			for attempt in range(190):
				var at := Vector3(tx*10+rng.randf_range(0,10),0.01,tz*10+rng.randf_range(0,10))
				if allowed(at) and patches.get_noise_2d(at.x,at.z)>-0.15:
					points.append(at)
			if points.is_empty():
				continue
			var batch := MultiMesh.new()
			batch.transform_format = MultiMesh.TRANSFORM_3D
			batch.use_colors = true
			batch.use_custom_data = true
			batch.mesh = mesh
			batch.instance_count = points.size()
			for i in range(points.size()):
				var scale := rng.randf_range(0.6,1.25)
				var basis := Basis(Vector3.UP,rng.randf_range(0,TAU)).scaled(Vector3(scale,scale,scale))
				batch.set_instance_transform(i,Transform3D(basis,points[i]))
				batch.set_instance_color(i,Color(rng.randf_range(0.7,1),rng.randf_range(0.76,1),rng.randf_range(0.68,0.95)))
				batch.set_instance_custom_data(i,Color(rng.randf(),0,0,1))
			var instance := MultiMeshInstance3D.new()
			instance.name = "Grass_%s_%s" % [tx,tz]
			instance.multimesh = batch
			instance.material_override = mat
			instance.visibility_range_end = 60
			instance.visibility_range_end_margin = 8
			instance.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
			instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(instance)
			grass_count += points.size()

func build_stones_and_leaves() -> void:
	var stone_mesh := SphereMesh.new()
	stone_mesh.radius = 0.5
	stone_mesh.height = 1
	stone_mesh.radial_segments = 10
	stone_mesh.rings = 5
	var stone_mat := load("res://assets/props/concrete.tres").duplicate() as StandardMaterial3D
	stone_mat.albedo_color = Color("818777")
	var leaf_mat := StandardMaterial3D.new()
	leaf_mat.vertex_color_use_as_albedo = true
	leaf_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	leaf_mat.roughness = 1
	var leaf_surface := SurfaceTool.new()
	leaf_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var points := [Vector3(0,0,-0.06),Vector3(-0.023,0.005,-0.01),Vector3(-0.016,0,0.035),Vector3(0,0,0.06),Vector3(0.02,0,0.01),Vector3(0.015,0,-0.025)]
	for i in range(6):
		for vertex in [Vector3(0,0.008,0),points[i],points[(i+1)%6]]:
			leaf_surface.set_normal(Vector3.UP)
			leaf_surface.set_color(Color("777052") if i%2==0 else Color("5c6145"))
			leaf_surface.add_vertex(vertex)
	var leaf_mesh := leaf_surface.commit()
	var stone_positions: Array[Vector3] = []
	var leaf_positions: Array[Vector3] = []
	for attempt in range(850):
		var at := Vector3(rng.randf_range(-29,29),0.012,rng.randf_range(-50,29))
		if not allowed(at):
			continue
		if stone_positions.size()<110:
			stone_positions.append(at)
		else:
			leaf_positions.append(at)
	make_batch("LowStones",stone_mesh,stone_mat,stone_positions,true)
	make_batch("DryLeafLitter",leaf_mesh,leaf_mat,leaf_positions,false)
	stone_count = stone_positions.size()
	leaf_count = leaf_positions.size()

func make_batch(label: String, mesh: Mesh, material: Material, points: Array[Vector3], stones: bool) -> void:
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.mesh = mesh
	batch.instance_count = points.size()
	for i in range(points.size()):
		var scale := rng.randf_range(0.08,0.24) if stones else rng.randf_range(0.8,1.8)
		var size := Vector3(scale,scale*0.45,scale*1.3) if stones else Vector3.ONE*scale
		var at := points[i]+Vector3(0,scale*0.13 if stones else 0,0)
		batch.set_instance_transform(i,Transform3D(Basis(Vector3.UP,rng.randf_range(0,TAU)).scaled(size),at))
	var instance := MultiMeshInstance3D.new()
	instance.name = label
	instance.multimesh = batch
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)
