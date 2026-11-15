@tool
extends Node3D
## Isolated, disposable Area 02 geometry preview. No gameplay, loot or transitions.
## Never use this scene as the project main scene without explicit acceptance.
const PROFILE = preload("res://scripts/briar_creek/briar_creek_profile.gd")
const EARTH_SURFACE = preload("res://assets/materials/crossroads_earth.tres")
const GRAVEL_SURFACE = preload("res://assets/roads/gravel_shoulder.tres")
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
    _creek(generated)

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
    # Cache height queries before calculating normals. The original version
    # evaluated expensive road/pad grading five times per grid vertex.
    for row in range(stride):
        var z := -300.0 + float(row) * step
        for col in range(stride):
            var x := -300.0 + float(col) * step
            var i := row * stride + col
            vertices[i] = Vector3(x,profile.height_at(x,z),z)
            uvs[i] = Vector2(x/12.0,z/12.0)
    for row in range(stride):
        for col in range(stride):
            var i := row * stride + col
            var west := maxi(col-1,0)
            var east := mini(col+1,cells)
            var north := maxi(row-1,0)
            var south := mini(row+1,cells)
            var dx := float(east-west)*step
            var dz := float(south-north)*step
            var west_h: float = vertices[row*stride+west].y
            var east_h: float = vertices[row*stride+east].y
            var north_h: float = vertices[north*stride+col].y
            var south_h: float = vertices[south*stride+col].y
            normals[i] = Vector3((west_h-east_h)/dx,1.0,(north_h-south_h)/dz).normalized()
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
    mesh.surface_set_material(0,EARTH_SURFACE)
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
    # World-space UVs keep the existing gravel material tiled along the full
    # road rather than sampling one constant corner of its texture.
    for vertex in [a,b,c]:
        st.set_normal(Vector3.UP)
        st.set_uv(Vector2(vertex.x/5.0,vertex.z/5.0))
        st.add_vertex(vertex)

func _roads(root: Node3D) -> void:
    var holder := Node3D.new()
    holder.name="RoadSurfaces"
    root.add_child(holder)
    var gravel: Material = GRAVEL_SURFACE
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
                # Use the same top-visible face winding as terrain triangles.
                _tri(st,l0,r0,l1)
                _tri(st,r0,r1,l1)
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

func _creek(root: Node3D) -> void:
    # Visual-only shallow stream. The independent water surface follows the
    # depressed western bed; no water physics or gameplay are implied.
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var water := StandardMaterial3D.new()
    water.albedo_color=Color(0.16,0.23,0.24,0.83)
    water.roughness=0.24
    water.metallic=0.10
    water.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
    water.cull_mode=BaseMaterial3D.CULL_DISABLED
    st.set_material(water)
    for j in range(120):
        var n0 := float(j)*5.0
        var n1 := float(j+1)*5.0
        var x0 := profile.creek_x(n0)
        var x1 := profile.creek_x(n1)
        var mid0 := profile.to_world(x0,n0)
        var mid1 := profile.to_world(x1,n1)
        var h0 := profile.surface_height_at(mid0.x,mid0.z)+0.13
        var h1 := profile.surface_height_at(mid1.x,mid1.z)+0.13
        var a := profile.to_world(x0-3.0,n0,h0)
        var b := profile.to_world(x0+3.0,n0,h0)
        var c := profile.to_world(x1-3.0,n1,h1)
        var d := profile.to_world(x1+3.0,n1,h1)
        _tri(st,a,c,b)
        _tri(st,b,c,d)
    var flow := MeshInstance3D.new()
    flow.name="WesternCreekVisualOnly"
    flow.mesh=st.commit()
    flow.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    root.add_child(flow)
