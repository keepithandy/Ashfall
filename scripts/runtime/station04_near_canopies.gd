@tool
extends Node3D
## A visual-only canopy supplement for Station 04's 46 existing authored pines.
## Their scenes, colliders, transforms and gameplay remain unchanged.
## Reuses the distant-forest spruce meshes so trunk and crown silhouettes match.
@export var show_canopies: bool = true
@export_range(0.75, 1.40, 0.05) var crown_width: float = 1.08

var generated_canopy_count: int = 0

func _ready() -> void:
    if show_canopies:
        _build()

func _build() -> void:
    if has_node("CanopyBatches"):
        return
    var backdrop := get_node_or_null("../../Terrain/DistantTreeLine") as Node3D
    if backdrop == null or backdrop.get_script() == null:
        push_warning("Station 04 near canopies require the distant conifer mesh generator")
        return
    var source := get_parent()
    if source == null:
        return
    var groups: Array = [[], [], []]
    var rng := RandomNumberGenerator.new()
    rng.seed = 404202
    generated_canopy_count = 0
    for candidate in source.get_children():
        var tree := candidate as Node3D
        if tree == null or not str(tree.name).begins_with("Pine"):
            continue
        var profile := generated_canopy_count % 3
        var height := rng.randf_range(7.7, 9.6)
        var width := height * crown_width * rng.randf_range(0.93, 1.14)
        var rotation := Basis(Vector3.UP, rng.randf_range(-PI, PI))
        var transform := Transform3D(rotation.scaled(Vector3(width, height, width)), tree.position)
        var tint := Color(
            rng.randf_range(0.90, 1.06),
            rng.randf_range(0.88, 1.08),
            rng.randf_range(0.86, 1.03)
        )
        groups[profile].append({"transform": transform, "tint": tint, "origin": tree.position, "height": height})
        generated_canopy_count += 1

    var forest := Node3D.new()
    forest.name = "CanopyBatches"
    add_child(forest)
    for profile in range(3):
        var entries: Array = groups[profile]
        if entries.is_empty():
            continue
        var mesh: ArrayMesh = backdrop.call("_tree_mesh", profile) as ArrayMesh
        if mesh == null:
            push_error("Station 04 near canopy profile mesh could not be generated")
            return
        var batch := MultiMesh.new()
        batch.transform_format = MultiMesh.TRANSFORM_3D
        batch.use_colors = true
        batch.mesh = mesh
        batch.instance_count = entries.size()
        var lower := Vector3(100000.0, 100000.0, 100000.0)
        var upper := Vector3(-100000.0, -100000.0, -100000.0)
        for i in range(entries.size()):
            var entry: Dictionary = entries[i]
            batch.set_instance_transform(i, entry["transform"])
            batch.set_instance_color(i, entry["tint"])
            var base: Vector3 = entry["origin"]
            var height: float = entry["height"]
            lower = lower.min(base - Vector3(height * 0.42, 0.4, height * 0.42))
            upper = upper.max(base + Vector3(height * 0.42, height + 0.4, height * 0.42))
        batch.custom_aabb = AABB(lower, upper - lower)
        var node := MultiMeshInstance3D.new()
        node.name = "CanopyProfile%d" % profile
        node.multimesh = batch
        node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        forest.add_child(node)
