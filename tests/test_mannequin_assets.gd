extends SceneTree
## Check the anatomy study and the separated wardrobe as actual imported assets.
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("MANNEQUIN_FAIL: " + message)

func run() -> void:
	var review: Node3D = load("res://scenes/mannequin_review.tscn").instantiate()
	root.add_child(review)
	await process_frame
	var subject: Node3D = review.mannequin
	var meshes := subject.find_children("*","MeshInstance3D",true,false)
	var skeletons := subject.find_children("*","Skeleton3D",true,false)
	check(meshes.size()==3,"Anatomy study must contain only the continuous body and two unpainted eyes")
	check(skeletons.size()==1 and skeletons[0].get_bone_count()==56,"Anatomical rig did not import")
	var body: MeshInstance3D = review.mannequin.find_child("MaleMannequinBody",true,false)
	check(is_instance_valid(body) and body.skin!=null,"The continuous body lost its skin")
	if is_instance_valid(body):
		check(absf(body.mesh.get_aabb().size.y-1.80)<0.005,"Body must measure 1.80 metres")
		for surface in range(body.mesh.get_surface_count()):
			var mat: BaseMaterial3D = body.get_active_material(surface)
			check(mat.albedo_texture==null and mat.normal_texture==null,"Anatomy study contains a skin or clothing texture")
			var arrays := body.mesh.surface_get_arrays(surface)
			var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
			check(not weights.is_empty(),"Subdivision lost body skin weights")
			for i in range(0,weights.size(),4):
				if absf(weights[i]+weights[i+1]+weights[i+2]+weights[i+3]-1)>0.015:
					check(false,"Exported body weights are not normalized")
					break
	var event := InputEventKey.new()
	event.pressed=true
	event.physical_keycode=KEY_P
	review._unhandled_input(event)
	check(review.animator.is_playing(),"Joint inspection control failed")
	var skeleton: Skeleton3D = skeletons[0]
	var elbow := skeleton.find_bone("forearm.R")
	review.animator.seek(1.0,true)
	await process_frame
	check(skeleton.get_bone_pose_rotation(elbow).angle_to(Quaternion.IDENTITY)>0.2,"Inspection clip does not bend the anatomical rig")
	review._unhandled_input(event)
	check(not review.animator.is_playing(),"Inspection pose cannot return to neutral")
	event.physical_keycode=KEY_3
	review._unhandled_input(event)
	check(review.camera.position.x>2.0,"Side-view control failed")
	event.physical_keycode=KEY_O
	review._unhandled_input(event)
	check(review.camera.projection==Camera3D.PROJECTION_PERSPECTIVE,"Perspective control failed")
	var wardrobe := {"field_jacket":"Jacket","collar_and_underlayer":"Neckwear","cargo_trousers":"Trousers","boots":"Boots","gloves":"Gloves","belt_and_strap":"Equipment","shoulder_bag":"Satchel","flashlight":"Flashlight"}
	for file in wardrobe:
		var item: Node3D = load("res://scenes/characters/wardrobe/"+file+".tscn").instantiate()
		root.add_child(item)
		var item_meshes := item.find_children("*","MeshInstance3D",true,false)
		var item_skeletons := item.find_children("*","Skeleton3D",true,false)
		check(item_meshes.size()==1 and String(item_meshes[0].name)==wardrobe[file],"Wardrobe asset contains another garment: "+file)
		check(item_skeletons.size()==1 and item_meshes.size()==1 and item_meshes[0].skin!=null,"Wardrobe asset lost its original fitting rig: "+file)
		item.queue_free()
	review.queue_free()
	await process_frame
	print("MANNEQUIN_ASSETS_CHECK: failures=",failures)
	quit(1 if failures else 0)
