extends SceneTree

func _initialize() -> void:
	var script=load("res://scripts/authoring/workshop_prop_builder.gd")
	if not script.can_instantiate():
		quit(1)
		return
	var builder=script.new()
	builder.prepare_workshop_materials()
	DirAccess.make_dir_recursive_absolute("res://scenes/workshop")
	DirAccess.make_dir_recursive_absolute("res://assets/workshop")
	var manifest: Array[Dictionary]=[]
	for id: String in builder.WORKSHOP_CATALOG:
		var prop: Node3D=builder.build_workshop(id)
		for child in prop.get_children():
			child.owner=prop
		var packed:=PackedScene.new()
		packed.pack(prop)
		var path:="res://scenes/workshop/"+id+".tscn"
		if ResourceSaver.save(packed,path)!=OK:
			push_error("Workshop prop save failed: "+id)
			quit(1)
			return
		manifest.append({"id":id,"scene":path,"size_metres":str(builder.WORKSHOP_CATALOG[id])})
		prop.free()
	var file:=FileAccess.open("res://assets/workshop/catalog.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest,"\t"))
	file.close()
	build_placement()
	build_gallery(builder)
	print("WORKSHOP_BAKED: 8 new text-free props, separate layout, separate gallery")
	quit()

func add_prop(parent: Node3D,id: String,at: Vector3,yaw: float=0) -> Node3D:
	var prop: Node3D=load("res://scenes/workshop/"+id+".tscn").instantiate()
	prop.name=id+"_"+str(parent.get_child_count())
	prop.position=at
	prop.rotation.y=yaw
	parent.add_child(prop)
	prop.owner=parent
	return prop

func build_placement() -> void:
	var root:=Node3D.new()
	root.name="WorkshopDressing"
	var placements:=[
		["workbench_vise",Vector3(20,0,-14),0],
		["open_wood_crate",Vector3(19.65,0.2275,-14),0],
		["metal_chair",Vector3(20.1,0,-12.8),PI],
		["fire_extinguisher",Vector3(20.9,0,-14.1),0],
		["discarded_tyre",Vector3(22.5,0,-1.5),0.2],
		["discarded_tyre",Vector3(22,0,-2.3),-0.3],
		["wheelbarrow",Vector3(-16,0,15.2),0.4],
		["steel_ladder",Vector3(-13.72,0,10),PI/2],
		["coiled_hose",Vector3(-23.5,0,-1),0.2],
		["fire_extinguisher",Vector3(-12.5,0.18,12.7),0],
		["open_wood_crate",Vector3(-18,0,-33.8),0.1],
		["coiled_hose",Vector3(26.1,0,-38),0.2]
	]
	for p in placements:
		add_prop(root,p[0],p[1],p[2])
	var packed:=PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed,"res://scenes/workshop_dressing.tscn")
	root.free()

func build_gallery(builder: RefCounted) -> void:
	var gallery:=Node3D.new()
	gallery.name="WorkshopGallery"
	gallery.set_script(load("res://scripts/review/prop_gallery.gd"))
	var displays:=Node3D.new()
	displays.name="Displays"
	gallery.add_child(displays)
	displays.owner=gallery
	var index:=0
	for id: String in builder.WORKSHOP_CATALOG:
		var display:=Node3D.new()
		display.name=id
		display.position=Vector3((index%6-2.5)*2.8,0,-(index/6)*3)
		display.set_meta("title",id.replace("_"," ").capitalize())
		displays.add_child(display)
		display.owner=gallery
		var prop:=add_prop(display,id,Vector3(0,0.02,0))
		prop.owner=gallery
		var label:=Label3D.new()
		label.name="Caption"
		label.text=id.replace("_"," ").capitalize()
		label.position=Vector3(0,0.16,1.1)
		label.font_size=24
		label.pixel_size=0.0035
		display.add_child(label)
		label.owner=gallery
		index+=1
	var packed:=PackedScene.new()
	packed.pack(gallery)
	ResourceSaver.save(packed,"res://scenes/workshop_gallery.tscn")
	gallery.free()
