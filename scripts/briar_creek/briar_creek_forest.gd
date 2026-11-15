@tool
extends Node3D
## Briar Creek deterministic woodland. Reuses existing Ashfall meshes, with
## cell-sized MultiMeshes instead of thousands of scene instances.
const PROFILE = preload("res://scripts/briar_creek/briar_creek_profile.gd")
const SOURCES := {
    "Pine": preload("res://scenes/nature/forest_pine.tscn"),
    "Bare": preload("res://scenes/nature/bare_tree.tscn"),
    "Shrub": preload("res://scenes/nature/low_shrub.tscn")
}
const CELL := 100.0
var profile = PROFILE.new()
var trees_planted := 0
var shrubs_planted := 0
var trunk_colliders := 0
var draw_batches := 0

func _ready() -> void:
    build()

func _distance_to_path(p: Vector2, points: Array) -> float:
    var smallest := INF
    for i in range(points.size()-1):
        var a: Vector3 = points[i]
        var b: Vector3 = points[i+1]
        var begin := Vector2(a.x,a.z)
        var delta := Vector2(b.x,b.z)-begin
        var t := clampf((p-begin).dot(delta)/maxf(delta.length_squared(),0.001),0.0,1.0)
        smallest = minf(smallest,p.distance_to(begin+delta*t))
    return smallest

func _blocked(x: float, north: float, margin: float = 0.0) -> bool:
    var p := Vector2(x,north)
    if absf(x - profile.creek_x(north)) < 10.0 + margin:
        return true
    var clearings := [
        [305.0,65.0,27.0],[350.0,305.0,76.0],
        [145.0,390.0,66.0],[470.0,445.0,52.0],
        [335.0,550.0,25.0],[220.0,460.0,43.0]
    ]
    for area in clearings:
        if p.distance_to(Vector2(float(area[0]),float(area[1]))) < float(area[2])+margin:
            return true
    for route in PROFILE.ROUTES:
        var clearance := float(route["width"])*0.5 + 4.0 + margin
        if _distance_to_path(p,route["points"]) < clearance:
            return true
    return false

func _queue_plant(batches: Dictionary, kind: String, p: Vector2, scale_value: float, rng: RandomNumberGenerator) -> Transform3D:
    var cx := floori(p.x/CELL)
    var cz := floori(p.y/CELL)
    var key := "%s|%d|%d" % [kind,cx,cz]
    if not batches.has(key):
        batches[key]=[]
    var world := profile.to_world(p.x,p.y)
    world.y=profile.surface_height_at(world.x,world.z)-0.05
    var basis := Basis(Vector3.UP,rng.randf_range(-PI,PI)).scaled(Vector3.ONE*scale_value)
    var tf := Transform3D(basis,world)
    var items: Array = batches[key]
    items.append(tf)
    return tf

func build() -> void:
    if has_node("GeneratedForest"):
        return
    var root := Node3D.new()
    root.name="GeneratedForest"
    add_child(root)
    var trees := Node3D.new()
    trees.name="BatchedCanopy"
    root.add_child(trees)
    var trunk := StaticBody3D.new()
    trunk.name="TrunkColliders"
    trunk.collision_layer=1
    trunk.collision_mask=0
    root.add_child(trunk)
    var shared_shape := CylinderShape3D.new()
    shared_shape.radius=0.27
    shared_shape.height=6.7
    var rng := RandomNumberGenerator.new()
    rng.seed=245901
    var batches: Dictionary={}
    trees_planted=0
    shrubs_planted=0
    trunk_colliders=0
    draw_batches=0
    # Deterministic uneven stands with ragged meadow/clearcut edges.
    # Batches contain no physics; slim colliders attach to one static body.
    for i in range(2600):
        var x := rng.randf_range(6.0,594.0)
        var north := rng.randf_range(6.0,594.0)
        var density := 0.65 + 0.25*sin(x*0.025 + 0.6)*cos(north*0.018)
        if rng.randf() > density:
            continue
        if _blocked(x,north,2.0):
            continue
        var size := rng.randf_range(1.0,1.65)
        var kind := "Bare" if (i%7==0) else "Pine"
        var tf := _queue_plant(batches,kind,Vector2(x,north),size,rng)
        trees_planted += 1
        # No invisible walls; trunk shapes roughly match visible tree stems.
        # Every planted trunk gets a proxy so the player cannot walk through it.
        var shape := CollisionShape3D.new()
        shape.name="Trunk_%04d" % trees_planted
        shape.shape=shared_shape
        shape.position=tf.origin + Vector3(0,3.35,0)
        trunk.add_child(shape)
        trunk_colliders += 1
        if i%3==0:
            var brush_pos := Vector2(x + rng.randf_range(-3.0,3.0),north+rng.randf_range(-3.0,3.0))
            if not _blocked(brush_pos.x,brush_pos.y):
                _queue_plant(batches,"Shrub",brush_pos,rng.randf_range(0.9,1.5),rng)
                shrubs_planted+=1
    # Only load each source scene once and reuse existing material/mesh assets.
    for kind in SOURCES.keys():
        var sample := (SOURCES[kind] as PackedScene).instantiate() as Node3D
        if sample == null:
            push_error("Briar Creek missing source woodland scene: "+str(kind))
            continue
        var meshes: Array=sample.find_children("*","MeshInstance3D",true,false)
        for key in batches.keys():
            var parts := str(key).split("|")
            if parts[0]!=str(kind):
                continue
            var placements: Array=batches[key]
            for part in range(meshes.size()):
                var source := meshes[part] as MeshInstance3D
                if source.mesh==null:
                    continue
                var mm := MultiMesh.new()
                mm.transform_format=MultiMesh.TRANSFORM_3D
                mm.mesh=source.mesh
                mm.instance_count=placements.size()
                for j in range(placements.size()):
                    var placement: Transform3D=placements[j]
                    mm.set_instance_transform(j,placement*source.transform)
                var node := MultiMeshInstance3D.new()
                node.name="Cell_%s_Mesh%d" % [str(key).replace("|","_"),part]
                node.multimesh=mm
                node.material_override=source.material_override
                node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
                node.visibility_range_end=720.0
                trees.add_child(node)
                draw_batches+=1
        sample.free()
