extends Node3D

var hands: Node3D
var body: Node3D
var flashlight: Node3D
var legs: Array[Node3D]=[]
var lens: MeshInstance3D
var lens_on: StandardMaterial3D
var lens_off: StandardMaterial3D

func material(color: String, metallic: float=0.0) -> StandardMaterial3D:
	var result:=StandardMaterial3D.new()
	result.albedo_color=Color(color)
	result.roughness=0.82
	result.metallic=metallic
	return result

func capsule_between(parent: Node3D, a: Vector3, b: Vector3, radius: float, mat: Material, cast: bool=true) -> MeshInstance3D:
	var instance:=MeshInstance3D.new()
	var mesh:=CapsuleMesh.new()
	mesh.radius=radius
	mesh.height=maxf(radius*2.0,a.distance_to(b)+radius*2.0)
	instance.mesh=mesh
	instance.material_override=mat
	instance.position=(a+b)*0.5
	parent.add_child(instance)
	instance.quaternion=Quaternion(Vector3.UP,(b-a).normalized())
	if not cast:
		instance.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return instance

func box(parent: Node3D, position_: Vector3, dimensions: Vector3, mat: Material, cast: bool=true) -> MeshInstance3D:
	var instance:=MeshInstance3D.new()
	var mesh:=BoxMesh.new()
	mesh.size=dimensions
	instance.mesh=mesh
	instance.material_override=mat
	instance.position=position_
	if not cast:
		instance.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)
	return instance

func cylinder(parent: Node3D, position_: Vector3, radius: float, height: float, mat: Material) -> MeshInstance3D:
	var instance:=MeshInstance3D.new()
	var mesh:=CylinderMesh.new()
	mesh.top_radius=radius
	mesh.bottom_radius=radius
	mesh.height=height
	mesh.radial_segments=24
	instance.mesh=mesh
	instance.material_override=mat
	instance.position=position_
	instance.rotation.x=PI/2
	instance.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)
	return instance

func build(camera: Camera3D, player: CharacterBody3D) -> SpotLight3D:
	var coat:=material("474e3c")
	var cuff:=material("303a2d")
	var glove:=material("2b302a")
	var trousers:=material("383e35")
	var boot:=material("211f1a")
	var seam:=material("777766")
	var leather:=material("44493b")
	# Fine, low-contrast surface variation helps the fabric catch the torch light.
	var noise:=FastNoiseLite.new()
	noise.seed=417
	noise.frequency=0.07
	var weave:=NoiseTexture2D.new()
	weave.width=128
	weave.height=128
	weave.noise=noise
	coat.albedo_texture=weave
	coat.uv1_triplanar=true
	coat.uv1_scale=Vector3(5,5,5)
	var metal:=material("252c29",0.45)
	var rim:=material("697064",0.6)
	lens_on=material("ddd5ad")
	lens_on.emission_enabled=true
	lens_on.emission=Color("d7d0a9")
	lens_on.emission_energy_multiplier=0.5
	lens_off=material("535b54")
	body=Node3D.new()
	body.name="HeadlessBody"
	player.add_child(body)
	box(body,Vector3(0,0.94,0.19),Vector3(0.43,0.48,0.18),coat)
	box(body,Vector3(0,0.70,0.14),Vector3(0.42,0.10,0.19),cuff)
	for x in [-0.13,0.13]:
		var leg:=Node3D.new()
		leg.position=Vector3(x,0.69,-0.13)
		body.add_child(leg)
		capsule_between(leg,Vector3(0,-0.06,0),Vector3(0,-0.52,0),0.10,trousers)
		box(leg,Vector3(0,-0.61,-0.04),Vector3(0.19,0.14,0.32),boot)
		box(leg,Vector3(0,-0.685,-0.05),Vector3(0.20,0.025,0.33),cuff)
		for z in [-0.12,-0.07,-0.02]:
			box(leg,Vector3(0,-0.531,z),Vector3(0.12,0.008,0.012),seam)
		legs.append(leg)
	hands=Node3D.new()
	hands.name="FirstPersonHands"
	camera.add_child(hands)
	# Sleeves run from below the frame toward the glove around the torch.
	capsule_between(hands,Vector3(0.50,-0.49,-0.17),Vector3(0.32,-0.30,-0.57),0.09,coat,false)
	capsule_between(hands,Vector3(0.32,-0.30,-0.57),Vector3(0.29,-0.25,-0.67),0.075,glove,false)
	capsule_between(hands,Vector3(0.35,-0.29,-0.57),Vector3(0.32,-0.27,-0.62),0.088,cuff,false)
	for z in [-0.70,-0.74,-0.78]:
		capsule_between(hands,Vector3(0.25,-0.20,z),Vector3(0.33,-0.20,z),0.014,leather,false)
	capsule_between(hands,Vector3(0.24,-0.26,-0.65),Vector3(0.24,-0.20,-0.73),0.018,glove,false)
	for z in [-0.52,-0.45,-0.38]:
		capsule_between(hands,Vector3(0.37,-0.32,z),Vector3(0.40,-0.31,z+0.025),0.004,seam,false)
	# A second sleeve is visible at the lower left as the player moves.
	capsule_between(hands,Vector3(-0.43,-0.52,-0.16),Vector3(-0.25,-0.43,-0.43),0.085,coat,false)
	capsule_between(hands,Vector3(-0.25,-0.43,-0.43),Vector3(-0.23,-0.40,-0.49),0.07,glove,false)
	flashlight=Node3D.new()
	flashlight.name="HandheldFlashlight"
	flashlight.position=Vector3(0.29,-0.22,-0.82)
	hands.add_child(flashlight)
	cylinder(flashlight,Vector3(0,0,0),0.035,0.25,metal)
	cylinder(flashlight,Vector3(0,0,-0.14),0.052,0.065,metal)
	cylinder(flashlight,Vector3(0,0,-0.176),0.046,0.009,rim)
	lens=cylinder(flashlight,Vector3(0,0,-0.182),0.038,0.005,lens_on)
	for z in [0.045,0.065,0.085]:
		cylinder(flashlight,Vector3(0,0,z),0.037,0.006,rim)
	box(flashlight,Vector3(0,0.036,0.02),Vector3(0.024,0.009,0.036),cuff,false)
	var light:=SpotLight3D.new()
	light.name="FlashlightBeam"
	light.position=Vector3(0,0,-0.19)
	light.light_color=Color(0.91,0.92,0.78)
	light.light_energy=3.5
	light.spot_range=24
	light.spot_angle=34
	light.spot_attenuation=0.75
	light.shadow_enabled=true
	flashlight.add_child(light)
	return light

func animate_motion(delta: float, speed_ratio: float, phase: float, is_crouching: bool, grounded: bool, look_sway: Vector2, light_on: bool, wall_retraction: float=0.0) -> void:
	var sway:=sin(phase)*speed_ratio if grounded else 0.0
	var target:=Vector3(sway*0.012-look_sway.x*0.02,absf(cos(phase))*speed_ratio*0.012-look_sway.y*0.02-wall_retraction*0.12,wall_retraction)
	hands.position=hands.position.lerp(target,1.0-exp(-delta*9.0))
	hands.rotation.z=lerpf(hands.rotation.z,-sway*0.025-look_sway.x*0.04,1.0-exp(-delta*8.0))
	body.scale.y=lerpf(body.scale.y,0.68 if is_crouching else 1.0,1.0-exp(-delta*12.0))
	for i in range(legs.size()):
		legs[i].rotation.x=lerpf(legs[i].rotation.x,sway*0.28*(1 if i==0 else -1),1.0-exp(-delta*10.0))
	lens.material_override=lens_on if light_on else lens_off
