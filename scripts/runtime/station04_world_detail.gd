extends Node3D
## Station 04 near-ground reconstruction using existing licensed project assets.
## Decorative foliage has no physics; four hand-placed landmarks keep their
## native collision. All placements are seeded, bounded, and off main routes.
## Never changes the authored ground, trees, roads, buildings or objectives.

@export var enabled: bool = true
@export_range(0.25, 1.0, 0.05) var density: float = 1.0
@export_range(40.0, 160.0, 10.0) var foliage_view_range: float = 90.0

const FOLIAGE := [
    "res://scenes/nature/fern_clump.tscn",
    "res://scenes/nature/low_shrub.tscn",
    "res://scenes/nature/dry_bramble.tscn",
    "res://scenes/nature/reed_clump.tscn",
    "res://scenes/extra_dressing/dry_grass_tuft.tscn",
    "res://scenes/nature/dead_branch_pile.tscn"
]
const PATCHES := [
    # No main road, interaction, cottage threshold or service-yard crossings.
    {"center": Vector2(-62, -16), "spread": Vector2(11, 20), "count": 27},
    {"center": Vector2(-64, 39), "spread": Vector2(9, 19), "count": 23},
    {"center": Vector2(65, -29), "spread": Vector2(10, 19), "count": 25},
    {"center": Vector2(65, 32), "spread": Vector2(10, 19), "count": 24},
    {"center": Vector2(-17, 70), "spread": Vector2(34, 8), "count": 23},
    {"center": Vector2(18, -69), "spread": Vector2(36, 9), "count": 26}
]
const LANDMARKS := [
    {"scene": "res://scenes/decorative_world/roadside_memorial.tscn", "name": "QuietMemorial", "at": Vector3(-12, 0, 65), "turn": 0.2},
    {"scene": "res://scenes/decorative_world/fallen_utility_pole.tscn", "name": "SnappedUtilityPole", "at": Vector3(53, 0, -47), "turn": -0.3},
    {"scene": "res://scenes/decorative_world/collapsed_bus_shelter.tscn", "name": "CollapsedShelter", "at": Vector3(53, 0, 47), "turn": 1.4},
    {"scene": "res://scenes/decorative_world/rusted_mailbox.tscn", "name": "AbandonedMailbox", "at": Vector3(-62, 0, -49), "turn": 1.1}
]
var foliage_count: int = 0
var landmark_count: int = 0
var placement_points: Array[Vector3] = []


func _ready() -> void:
    if enabled:
        rebuild()


func _safe_site(at: Vector2) -> bool:
    if absf(at.x) > 79.0 or absf(at.y) > 78.0:
        return false
    # Crossroad and research walkways. Clear periphery near the three houses.
    if absf(at.x) < 11.0 and at.y > -63.0 and at.y < 36.0:
        return false
    if at.y > 32.0 and at.y < 58.0 and absf(at.x) < 41.0:
        return false
    if at.x > 18.0 and at.x < 48.0 and at.y > -39.0 and at.y < 17.0:
        return false
    if at.x < -28.0 and at.x > -61.0 and at.y > 0.0 and at.y < 35.0:
        return false
    return true


func rebuild() -> void:
    if has_node("DecorativeDetail"):
        return
    var root := Node3D.new()
    root.name = "DecorativeDetail"
    add_child(root)
    var patches := Node3D.new()
    patches.name = "Understory"
    root.add_child(patches)
    var landmarks := Node3D.new()
    landmarks.name = "NarrativeProps"
    root.add_child(landmarks)

    var rng := RandomNumberGenerator.new()
    rng.seed = 42021
    var scenes: Array[PackedScene] = []
    for path in FOLIAGE:
        scenes.append(load(path) as PackedScene)
    foliage_count = 0
    placement_points.clear()
    for zone in PATCHES:
        var target := int(round(float(zone["count"]) * density))
        for i in range(target):
            # Averaged offsets produce natural clusters without uniform grid lines.
            var center: Vector2 = zone["center"]
            var spread: Vector2 = zone["spread"]
            var x := center.x + (rng.randf_range(-1.0, 1.0) + rng.randf_range(-1.0, 1.0)) * 0.5 * spread.x
            var z := center.y + (rng.randf_range(-1.0, 1.0) + rng.randf_range(-1.0, 1.0)) * 0.5 * spread.y
            var at := Vector2(x, z)
            if not _safe_site(at):
                continue
            var model: Node3D = scenes[rng.randi_range(0, scenes.size() - 1)].instantiate()
            model.position = Vector3(x, 0.0, z)
            model.rotation.y = rng.randf_range(-PI, PI)
            var width := rng.randf_range(0.62, 1.15)
            model.scale = Vector3(width, rng.randf_range(0.72, 1.06), width)
            model.set_meta("ashfall_visual_only", true)
            _make_visual_only(model)
            patches.add_child(model)
            placement_points.append(model.position)
            foliage_count += 1

    landmark_count = 0
    for anchor in LANDMARKS:
        var hero: Node3D = (load(anchor["scene"]) as PackedScene).instantiate()
        hero.name = anchor["name"]
        hero.position = anchor["at"]
        hero.rotation.y = anchor["turn"]
        # Keep authored obstacle colliders for substantial environmental props.
        hero.set_meta("ashfall_story_landmark", true)
        landmarks.add_child(hero)
        landmark_count += 1


func _make_visual_only(model: Node3D) -> void:
    if model is CollisionObject3D:
        model.collision_layer = 0
        model.collision_mask = 0
    for child in model.find_children("*", "CollisionObject3D", true, false):
        var object := child as CollisionObject3D
        object.collision_layer = 0
        object.collision_mask = 0
    for child in model.find_children("*", "GeometryInstance3D", true, false):
        var visual := child as GeometryInstance3D
        visual.set_meta("ashfall_visual_only", true)
        visual.visibility_range_end = foliage_view_range
        visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
