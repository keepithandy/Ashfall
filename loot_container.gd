extends StaticBody3D

@export var contents := {"bandage": 2, "food_tin": 1, "batteries": 1}
var lid: Node3D
var display: Node3D
var opened := false

func _ready() -> void:
	name="LootContainer"
	set_meta("interaction","loot_container")
	var wood: Material=load("res://assets/props/wood.tres")
	var iron: Material=load("res://assets/props/iron.tres")
	var lining:=StandardMaterial3D.new()
	lining.albedo_color=Color("292c24")
	lining.roughness=1.0
	part(self,Vector3(0,0.045,0),Vector3(0.85,0.09,0.55),wood)
	for x in [-0.4,0.4]:
		part(self,Vector3(x,0.24,0),Vector3(0.05,0.4,0.55),wood)
	for z in [-0.25,0.25]:
		part(self,Vector3(0,0.24,z),Vector3(0.8,0.4,0.05),wood)
	part(self,Vector3(0,0.1,0),Vector3(0.74,0.01,0.44),lining)
	for x in [-0.28,0.28]:
		part(self,Vector3(x,0.23,0.282),Vector3(0.045,0.36,0.015),iron)
		part(self,Vector3(x,0.23,-0.282),Vector3(0.045,0.36,0.015),iron)
	lid=Node3D.new()
	lid.name="HingedLid"
	lid.position=Vector3(0,0.44,-0.275)
	add_child(lid)
	part(lid,Vector3(0,0,0.275),Vector3(0.87,0.07,0.57),wood)
	for x in [-0.28,0.28]:
		part(lid,Vector3(x,0.04,0.275),Vector3(0.05,0.012,0.57),iron)
	part(lid,Vector3(0,-0.065,0.56),Vector3(0.1,0.12,0.025),iron)
	var collision:=CollisionShape3D.new()
	var shape:=BoxShape3D.new()
	shape.size=Vector3(0.85,0.45,0.55)
	collision.shape=shape
	collision.position=Vector3(0,0.225,0)
	add_child(collision)
	display=Node3D.new()
	display.name="VisibleContents"
	add_child(display)
	for entry in [["bandage",Vector3(-0.22,0.11,0.04)],["food_tin",Vector3(0,0.11,0)],["batteries",Vector3(0.21,0.11,0.03)]]:
		if contents.get(entry[0],0)<=0:
			continue
		var model: Node3D=load("res://scenes/loot/"+entry[0]+".tscn").instantiate()
		model.position=entry[1]
		display.add_child(model)
	display.hide()

func part(parent: Node3D, at: Vector3, size: Vector3, mat: Material) -> void:
	var mesh:=MeshInstance3D.new()
	var shape:=BoxMesh.new()
	shape.size=size
	mesh.mesh=shape
	mesh.material_override=mat
	mesh.position=at
	parent.add_child(mesh)

func set_open(value: bool) -> void:
	opened=value
	var tween:=create_tween()
	tween.tween_property(lid,"rotation:x",-1.8 if value else 0.0,0.3)
	display.visible=value and not contents.is_empty()

func take_all() -> Dictionary:
	var taken=contents.duplicate()
	contents.clear()
	display.hide()
	return taken
