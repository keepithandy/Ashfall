extends "res://nature_dressing.gd"
func _ready() -> void:
	name="VillageNature"
	rng.seed=51647
	exclusion_zones=[Rect2(-4.65,3.7,9.3,11.2),Rect2(-30,18.6,45,2.8),Rect2(-1.5,12,3,10),Rect2(-15.5,-20,3,50)]
	build_grass()
	build_stones_and_leaves()
	set_meta("grass_clumps",grass_count)
func allowed(at: Vector3) -> bool:
	if not Rect2(-28,-20,40,49).has_point(Vector2(at.x,at.z)):
		return false
	for area in exclusion_zones:
		if area.has_point(Vector2(at.x,at.z)):
			return false
	return true
