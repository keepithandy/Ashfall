extends Node3D
## Isolates the actual skinned hand and the live item socket for grip authoring.
const FLASHLIGHT = preload("res://assets/grips/flashlight.tres")
const TIN = preload("res://assets/grips/food_tin.tres")
@export var character_scene: PackedScene = preload("res://scenes/characters/mannequin_player.tscn")
@export var capture_directory := "res://reviews/hand_grips"
@export var flashlight_profile: HandGripProfile = FLASHLIGHT
@export var tin_profile: HandGripProfile = TIN
var character: Node3D
var controller: CharacterBody3D
var eyes: Camera3D
var camera: Camera3D
var label: Label
var angle := 0.7
var elevation := 0.35
var distance := 0.55
var show_contacts := false
var show_item := true
var marker_root: Node3D
var markers: Dictionary = {}
var capture := false
var aim_index := 0
var crouched := false
var near_wall := false
var walking := false
var phase := 0.0
var focus_locked := false
var locked_focus := Vector3.ZERO

func _ready() -> void:
	capture = "--capture-grips" in OS.get_cmdline_user_args()
	controller = CharacterBody3D.new()
	add_child(controller)
	eyes = Camera3D.new()
	eyes.position = Vector3(0,1.69,-0.065)
	controller.add_child(eyes)
	character = character_scene.instantiate()
	controller.add_child(character)
	character.build(eyes,controller)
	character.floor_ik_enabled = false
	character.torch.visible = false
	character.held_items.item_changed.connect(_hide_review_beam)
	isolate_hand()
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 0.32
	camera.near = 0.01
	camera.cull_mask = 1
	add_child(camera)
	camera.current = true
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("182126")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("bbcbd2")
	environment.ambient_light_energy = 0.5
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = environment
	add_child(world)
	for lighting in [[Vector3(-40,-30,0),Color("f1dfc9"),1.3],[Vector3(-25,135,0),Color("a2c1dd"),0.7]]:
		var light := DirectionalLight3D.new()
		light.rotation_degrees = lighting[0]
		light.light_color = lighting[1]
		light.light_energy = lighting[2]
		add_child(light)
	marker_root = Node3D.new()
	add_child(marker_root)
	for finger in ["index","middle","ring","pinky","thumb"]:
		var pair := []
		for color in [Color("6ac6a1"),Color("75bded")]:
			var marker := MeshInstance3D.new()
			var sphere := SphereMesh.new()
			sphere.radius = 0.0018
			sphere.height = 0.0036
			marker.mesh = sphere
			var material := StandardMaterial3D.new()
			material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			material.albedo_color = color
			marker.material_override = material
			marker_root.add_child(marker)
			pair.append(marker)
		markers[finger] = pair
	var canvas := CanvasLayer.new()
	add_child(canvas)
	label = Label.new()
	label.position = Vector2(22,22)
	label.add_theme_color_override("font_color",Color("d8e0dd"))
	canvas.add_child(label)
	if capture:
		canvas.hide()
		capture_views.call_deferred()
	if "--capture-transitions" in OS.get_cmdline_user_args():
		canvas.hide()
		capture_transition_demo.call_deferred()

func _hide_review_beam(_item_id: StringName) -> void:
	character.torch.visible=false

func isolate_hand() -> void:
	var body: MeshInstance3D = character.model.find_child("MaleMannequinBody",true,false)
	var wrist: Vector3 = character.profile_vector("wrist_rest")
	var hand_mesh := ArrayMesh.new()
	for surface in range(body.mesh.get_surface_count()):
		var arrays := body.mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var kept := PackedInt32Array()
		for i in range(0,indices.size(),3):
			var center := (vertices[indices[i]]+vertices[indices[i+1]]+vertices[indices[i+2]])/3
			if center.distance_to(wrist)<0.205:
				kept.append(indices[i])
				kept.append(indices[i+1])
				kept.append(indices[i+2])
		if not kept.is_empty():
			arrays[Mesh.ARRAY_INDEX] = kept
			hand_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
			hand_mesh.surface_set_material(hand_mesh.get_surface_count()-1,body.get_active_material(surface))
	body.mesh = hand_mesh
	for mesh: MeshInstance3D in character.model.find_children("*","MeshInstance3D",true,false):
		if mesh != body and not character.held_items.item.is_ancestor_of(mesh):
			mesh.visible = false

func equip(profile: HandGripProfile) -> void:
	character.equip_item(profile)
	character.torch.visible = false
	show_item = true
	character.held_items.grip_strength = 1

func _process(delta: float) -> void:
	if camera == null:
		return
	var speed := 3.5 if walking else 0.0
	controller.velocity=Vector3(0,0,-speed)
	phase+=delta*speed*2.6
	eyes.rotation.x=[0.0,-1.1,1.1][aim_index]
	eyes.position.y=lerpf(eyes.position.y,1.07 if crouched else 1.69,1-exp(-delta*12))
	character.animate_motion(delta,speed/6.4,phase,crouched,true,Vector2.ZERO,character.torch.visible,0.6 if near_wall else 0.0)
	var held: HeldItemController = character.held_items
	var focus: Vector3 = held.socket.global_position
	if held.item != null:
		focus = held.item.global_position
		held.item.visible = show_item
	if focus_locked:focus=locked_focus
	camera.position = focus+Vector3(sin(angle)*cos(elevation),sin(elevation),-cos(angle)*cos(elevation))*distance
	camera.look_at(focus)
	marker_root.visible = show_contacts and held.item != null
	var readout := ""
	if held.active_grip and held.item:
		for finger in markers:
			if not held.contact_positions.has(finger):continue
			var goal: Vector3 = held.item.to_global(held.active_grip.contact_targets[finger])
			var actual: Vector3 = held.contact_positions[finger]
			markers[finger][0].global_position = goal
			markers[finger][1].global_position = actual
			readout += finger+": "+str(snappedf(goal.distance_to(actual)*1000,0.1))+" mm  "
	label.text = "ASHFALL / HAND GRIP WORKSHOP\n1 Flashlight   2 Food tin   0 Empty hand   Space Open / close   I Hide item   G Contact markers\nP Aim level / down / up   C Crouch   V Wall retraction   W Walking\nRight-drag orbit   Wheel zoom   F Beam\n"+(held.active_grip.display_name if held.active_grip else "Empty hand")+"\n"+readout

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		angle -= event.relative.x*0.006
		elevation = clampf(elevation+event.relative.y*0.006,-1.2,1.2)
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:camera.size = maxf(0.12,camera.size*0.9)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:camera.size = minf(0.7,camera.size*1.1)
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_1:equip(flashlight_profile)
			KEY_2:equip(tin_profile)
			KEY_0:character.equip_item(null)
			KEY_SPACE:character.held_items.grip_strength = 1-character.held_items.grip_strength
			KEY_I:show_item = not show_item
			KEY_G:show_contacts = not show_contacts
			KEY_P:aim_index=(aim_index+1)%3
			KEY_C:crouched=not crouched
			KEY_V:near_wall=not near_wall
			KEY_W:walking=not walking
			KEY_F:
				if character.can_use_flashlight():character.torch.visible = not character.torch.visible

func capture_views() -> void:
	var dir := capture_directory
	DirAccess.make_dir_recursive_absolute(dir)
	for selection in [[flashlight_profile,"flashlight"],[tin_profile,"food_tin"]]:
		equip(selection[0])
		for view in [[0.7,0.35,"side"],[2.9,0.2,"palm"],[-1.2,-0.45,"under"]]:
			angle = view[0]
			elevation = view[1]
			await get_tree().create_timer(0.8).timeout
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(dir+"/"+selection[1]+"-"+view[2]+".png")
		for state in [[1,false,false,false,"aim-down"],[2,false,false,false,"aim-up"],[0,true,false,true,"crouch-walk"],[0,false,true,false,"wall"]]:
			aim_index=state[0]
			crouched=state[1]
			near_wall=state[2]
			walking=state[3]
			angle=0.7
			elevation=0.35
			await get_tree().create_timer(0.8).timeout
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(dir+"/"+selection[1]+"-"+state[4]+".png")
		aim_index=0
		crouched=false
		near_wall=false
		walking=false
	print("HAND_GRIP_REVIEW_CAPTURED")
	get_tree().quit()

func capture_transition_demo() -> void:
	# Fixed 60 Hz offline capture; every third frame makes a 20 fps review GIF.
	var dir := "res://.godot/grip-transition-frames"
	DirAccess.make_dir_recursive_absolute(dir)
	camera.size=0.40
	angle=0.7
	elevation=0.25
	for frame in range(645):
		match frame:
			60:
				locked_focus=character.held_items.item.global_position
				focus_locked=true
			120:equip(tin_profile)
			210:equip(flashlight_profile)
			300:character.held_items.grip_strength=0
			330:character.held_items.grip_strength=1
			390:character.equip_item(null)
			450:equip(flashlight_profile)
			540:near_wall=true
			585:near_wall=false
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		if frame>=60 and frame%3==0:
			get_viewport().get_texture().get_image().save_png(dir+"/frame-%04d.png"%frame)
	print("GRIP_TRANSITION_PREVIEW_CAPTURED")
	get_tree().quit()
