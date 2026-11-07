extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var preview=load("res://preview.tscn").instantiate()
	root.add_child(preview)
	await physics_frame
	var skeletons=preview.model.find_children("*","Skeleton3D",true,false)
	var animations=preview.model.find_children("*","AnimationPlayer",true,false)
	assert(skeletons.size()==1 and skeletons[0].get_bone_count()>=30,"Hand rig was not imported")
	assert(animations.size()>0 and animations[0].get_animation_list().size()>0,"Animation was not imported")
	var skinned:=0
	for mesh in preview.model.find_children("*","MeshInstance3D",true,false):
		if mesh.skin!=null:
			skinned+=1
	assert(skinned==2,"Both gloves must have skin weights")
	var key:=InputEventKey.new()
	key.pressed=true
	key.physical_keycode=KEY_F
	var before: bool=preview.light.visible
	preview._unhandled_input(key)
	assert(preview.light.visible!=before,"Light toggle failed")
	key.physical_keycode=KEY_TAB
	preview._unhandled_input(key)
	assert(preview.studio,"Studio view switch failed")
	var emitter: Node3D=preview.model.find_child("BeamOrigin",true,false)
	var initial: Vector3=emitter.global_position
	key.physical_keycode=KEY_A
	preview._unhandled_input(key)
	assert(preview.animator.is_playing(),"Shared motion toggle failed")
	preview.animator.seek(0.75,true)
	await process_frame
	assert(emitter.global_position.distance_to(initial)>0.0001,"Flashlight did not follow the animated rig")
	print("PLAYER_ASSET_CHECK: ",skeletons[0].get_bone_count()," bones, two skinned gloves, animation, beam toggle and camera modes passed")
	quit()
