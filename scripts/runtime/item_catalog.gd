class_name ItemCatalog
extends RefCounted
const ORDER := ["flashlight","food_tin","bandage","batteries","water_bottle","antiseptic","detector","field_radio"]
const ITEMS := {
	"flashlight":{"name":"Field flashlight","category":"TOOLS","description":"A hand-held search light. F switches the beam; spare batteries restore its charge.","effect":"Toggle beam","mass":0.32},
	"food_tin":{"name":"Canned provisions","category":"SUPPLIES","description":"A sealed tin of field rations. Restores 45 stamina when needed.","effect":"Eat · +45 stamina","mass":0.38},
	"bandage":{"name":"Cotton bandage","category":"MEDICAL","description":"A wrapped cotton roll for field dressing. Restores 35 condition.","effect":"Apply · +35 condition","mass":0.08},
	"batteries":{"name":"Spare batteries","category":"SUPPLIES","description":"A matched pair of cells for the search light. Restores 60 charge.","effect":"Replace · +60 charge","mass":0.09},
	"water_bottle":{"name":"Water flask","category":"SUPPLIES","description":"A ribbed field bottle of clean water. Restores 30 stamina.","effect":"Drink · +30 stamina","mass":0.55},
	"antiseptic":{"name":"Antiseptic bottle","category":"MEDICAL","description":"An amber bottle from the checkpoint medical stores. Restores 20 condition.","effect":"Apply · +20 condition","mass":0.16},
	"detector":{"name":"Anomaly meter","category":"TOOLS","description":"A portable sensor. Equip it and activate it to read the nearest anomaly.","effect":"Toggle sensor","mass":0.44},
	"field_radio":{"name":"Field receiver","category":"TOOLS","description":"A short-range receiver tuned to the expedition beacon. Reports the objective bearing and distance.","effect":"Request bearings","mass":0.36}
}
static func entry(id: String) -> Dictionary:return ITEMS.get(id,{})
static func grip(id: String) -> HandGripProfile:
	if not ITEMS.has(id):return null
	return load("res://assets/grips/"+id+".tres")
static func initial_loadout() -> Dictionary:
	return {"flashlight":1,"food_tin":2,"bandage":2,"batteries":2,"water_bottle":2,"antiseptic":2,"detector":1,"field_radio":1}
static func total_mass(pack: Dictionary) -> float:
	var total := 0.0
	for id in ORDER:total+=float(ITEMS[id].mass)*pack.get(id,0)
	return total
