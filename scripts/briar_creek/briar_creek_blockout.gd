@tool
extends Node3D
## Isolated, disposable Area 02 geometry preview. No gameplay, loot or transitions.
## Never use this scene as the project main scene without explicit acceptance.
const PROFILE = preload("res://scripts/briar_creek/briar_creek_profile.gd")
var profile = PROFILE.new()
var generated_vertices := 0
var route_count := 0

func _ready() -> void:
    rebuild()
    var camera := get_node_or_null("PlanCamera") as Camera3D
    if camera != null:
        camera.look_at(Vector3.ZERO, Vector3.UP)

func rebuild() -> void:
    var old := get_node_or_null("Generated")
    if old != null:
        remove_child(old)
        old.free()
    var generated := Node3D.new()
    generated.name = "Generated"
    add_child(generated)
    _terrain(generated)
    _roads(generated)
    _markers(generated)

func _terrain(root: Node3D) -> void:
    var cells: int = PROFILE.GRID_CELLS
    var step: float = PROFILE.GRID_STEP
    var stride := cells + 1
    var count := stride * stride
    var vertices := PackedVector3Array()
    var normals := PackedVector3Array()
    var uvs := PackedVector2Array()
    vertices.resize(count)
    normals.resize(count)
    uvs.resize(count)
    for row in range(stride):
        var z := -300.0 + float(row) * step
        for col in range(stride):
            var x := -300.0 + float(col) * step
            var i := row * stride + col
            var h := profile.height_at(x,z)
            vertices[i] = Vector3(x,h,z)
            var west: float = profile.height_at(x - step,z)
            var east: float = profile.height_at(x + step,z)
            var north: float = profile.height_at(x,z - step)
            var south: float = profile.height_at(x,z + step)
            normals[i] = Vector3((west - east)/(2.0*step),1.0,(north - south)/(2.0*step)).normalized()
            uvs[i] = Vector2(x/12.0,z/12.0)
    var tris := PackedInt32Array()
    tris.resize(cells*cells*6)
    var k := 0
    for row in range(cells):
        for col in range(cells):
            var a := row*stride+col
            var b := a+1
            var c := a+stride
            var d := c+1
            # Same top-visible winding as the current Crossroads terrain.
            tris[k]=a; tris[k+1]=b; tris[k+2]=c
            tris[k+3]=b; tris[k+4]=d; tris[k+5]=c
            k += 6
    var arrays: Array = []
    arrays.resize(Mesh.ARRAY_MAX)
    arrays[Mesh.ARRAY_VERTEX]=vertices
    arrays[Mesh.ARRAY_NORMAL]=normals
    arrays[Mesh.ARRAY_TEX_UV]=uvs
    arrays[Mesh.ARRAY_INDEX]=tris
    var mesh := ArrayMesh.new()
    mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
    var earth := StandardMaterial3D.new()
    earth.albedo_color=Color(0.27,0.31,0.24)
    earth.roughness=1.0
    mesh.surface_set_material(0,earth)
    var body := StaticBody3D.new()
    body.name="WalkableTerrain"
    body.collision_layer=1
    body.collision_mask=0
    root.add_child(body)
    var visual := MeshInstance3D.new()
    visual.name="TerrainVisual"
    visual.mesh=mesh
    body.add_child(visual)
    var collider := CollisionShape3D.new()
    collider.name="TerrainCollision"
    var shape := mesh.create_trimesh_shape() as ConcavePolygonShape3D
    shape.backface_collision=true
    collider.shape=shape
    body.add_child(collider)
    generated_vertices=count

func _road_vertex(point: Vector3, side: Vector2, half_width: float, sign: float) -> Vector3:
    var local := profile.to_world(point.x,point.z)
    var x := local.x + side.x*half_width*sign
    var z := local.z + side.y*half_width*sign
    return Vector3(x,profile.surface_height_at(x,z)+0.055,z)

func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
    st.set_normal(Vector3.UP)
    st.add_vertex(a)
    st.set_normal(Vector3.UP)
    st.add_vertex(b)
    st.set_normal(Vector3.UP)
    st.add_vertex(c)

func _roads(root: Node3D) -> void:
    var holder := Node3D.new()
    holder.name="RoadSurfaces"
    root.add_child(holder)
    var gravel := StandardMaterial3D.new()
    gravel.albedo_color=Color(0.43,0.38,0.30)
    gravel.roughness=1.0
    var foot := StandardMaterial3D.new()
    foot.albedo_color=Color(0.34,0.33,0.25)
    foot.roughness=1.0
    route_count=0
    for route in PROFILE.ROUTES:
        var st := SurfaceTool.new()
        st.begin(Mesh.PRIMITIVE_TRIANGLES)
        st.set_material(foot if str(route["kind"])=="footpath" else gravel)
        var points: Array=route["points"]
        var half_width := float(route["width"])*0.5
        for i in range(points.size()-1):
            var a: Vector3=points[i]
            var b: Vector3=points[i+1]
            var d := Vector2(b.x-a.x, a.z-b.z).normalized()
            var side := Vector2(-d.y,d.x)
            var length := Vector2(b.x-a.x,b.z-a.z).length()
            var subdivisions := maxi(1,ceili(length/3.0))
            for j in range(subdivisions):
                var p0 := a.lerp(b,float(j)/float(subdivisions))
                var p1 := a.lerp(b,float(j+1)/float(subdivisions))
                var l0 := _road_vertex(p0,side,half_width,1.0)
                var r0 := _road_vertex(p0,side,half_width,-1.0)
                var l1 := _road_vertex(p1,side,half_width,1.0)
                var r1 := _road_vertex(p1,side,half_width,-1.0)
                _tri(st,l0,l1,r0)
                _tri(st,r0,l1,r1)
        var mesh := st.commit()
        var node := MeshInstance3D.new()
        node.name=str(route["id"])
        node.mesh=mesh
        holder.add_child(node)
        route_count += 1

func _markers(root: Node3D) -> void:
    var holder := Node3D.new()
    holder.name="SiteFootprintMarkers"
    root.add_child(holder)
    for site in PROFILE.SITES:
        var pos := profile.to_world(float(site["x"]),float(site["n"]))
        pos.y=profile.surface_height_at(pos.x,pos.z)+0.2
        var box := BoxMesh.new()
        box.size=Vector3(float(site["w"]),0.35,float(site["d"]))
        var mat := StandardMaterial3D.new()
        mat.albedo_color=Color(0.57,0.56,0.45)
        mat.roughness=1.0
        box.material=mat
        var node := MeshInstance3D.new()
        node.name=str(site["id"])
        node.mesh=box
        node.position=pos
        holder.add_child(node)
