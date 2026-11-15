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
    _outer_country(generated)
    _boundary(generated)
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

func _boundary(root: Node3D) -> void:
    # Keep the walker on the physical terrain while the surrounding hills
    # remain visual-only and area transitions are not implemented.
    var body := StaticBody3D.new()
    body.name = "TerrainBoundary"
    body.collision_layer = 1
    body.collision_mask = 0
    root.add_child(body)
    for spec in [
        [Vector3(-299.5, 35.0, 0.0), Vector3(1.0, 200.0, 600.0)],
        [Vector3(299.5, 35.0, 0.0), Vector3(1.0, 200.0, 600.0)],
        [Vector3(0.0, 35.0, -299.5), Vector3(600.0, 200.0, 1.0)],
        [Vector3(0.0, 35.0, 299.5), Vector3(600.0, 200.0, 1.0)]
    ]:
        var collision := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = spec[1]
        collision.shape = shape
        collision.position = spec[0]
        body.add_child(collision)

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

func _joined_side(points: Array[Vector3], index: int) -> Vector2:
    # Shared miter at each polyline vertex avoids cracks and overlapping road
    # strips when two successive logging-road segments turn.
    var here := profile.to_world(points[index].x, points[index].z)
    var before := profile.to_world(points[maxi(0,index-1)].x, points[maxi(0,index-1)].z)
    var after := profile.to_world(points[mini(points.size()-1,index+1)].x, points[mini(points.size()-1,index+1)].z)
    var incoming := Vector2(here.x-before.x,here.z-before.z).normalized()
    var outgoing := Vector2(after.x-here.x,after.z-here.z).normalized()
    if incoming.is_zero_approx():
        incoming=outgoing
    if outgoing.is_zero_approx():
        outgoing=incoming
    var a := Vector2(-incoming.y,incoming.x)
    var b := Vector2(-outgoing.y,outgoing.x)
    var joined := (a+b).normalized()
    if joined.is_zero_approx():
        return b
    return joined * minf(1.4,1.0/maxf(0.71,joined.dot(b)))

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
        var sampled: Array[Vector3] = []
        sampled.append(points[0])
        # Connect all segments through one continuous strip with shared
        # mitered side normals; avoid separately capped segment cards.
        for i in range(points.size()-1):
            var a: Vector3=points[i]
            var b: Vector3=points[i+1]
            var distance := Vector2(b.x-a.x,b.z-a.z).length()
            var subdivisions := maxi(1,ceili(distance/2.5))
            for j in range(1,subdivisions+1):
                sampled.append(a.lerp(b,float(j)/float(subdivisions)))
        for i in range(sampled.size()-1):
            var side0 := _joined_side(sampled,i)
            var side1 := _joined_side(sampled,i+1)
            var l0 := _road_vertex(sampled[i],side0,half_width,1.0)
            var r0 := _road_vertex(sampled[i],side0,half_width,-1.0)
            var l1 := _road_vertex(sampled[i+1],side1,half_width,1.0)
            var r1 := _road_vertex(sampled[i+1],side1,half_width,-1.0)
            _tri(st,l0,r0,l1)
            _tri(st,r0,r1,l1)
        var mesh := st.commit()
        var node := MeshInstance3D.new()
        node.name=str(route["id"])
        node.mesh=mesh
        holder.add_child(node)
        route_count+=1

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

func _outer_height(x: float, z: float) -> float:
    # Visual continuation exactly meets the physical 600m terrain at x/z
    # +/-300. Hills rise gradually toward the far rim without vertical cliffs.
    var out := maxf(maxf(absf(x)-300.0,absf(z)-300.0),0.0)
    var fade := clampf(out/256.0,0.0,1.0)
    fade=fade*fade*(3.0-2.0*fade)
    var ridge := 11.0*fade*(0.78+0.22*sin(x*0.009+z*0.005))
    return profile.height_at(x,z)+ridge

func _outer_country(root: Node3D) -> void:
    # Four non-overlapping skirts: adjacent border vertices share the exact
    # 4m samples of the collision-matched inner heightfield. These are purely
    # distant visual country; gameplay collision stops at the original rim.
    var holder := Node3D.new()
    holder.name="OuterVisualCountry"
    root.add_child(holder)
    _outer_strip(holder,"NorthernHills",-300.0,300.0,-556.0,-300.0,150,16)
    _outer_strip(holder,"SouthernCountry",-300.0,300.0,300.0,556.0,150,16)
    _outer_strip(holder,"WesternRidges",-556.0,-300.0,-556.0,556.0,16,278)
    _outer_strip(holder,"EasternRidges",300.0,556.0,-556.0,556.0,16,278)

func _outer_strip(parent: Node3D, label: String, west: float, east: float, north: float, south: float, columns: int, rows: int) -> void:
    var stride := columns+1
    var step_x := (east-west)/float(columns)
    var step_z := (south-north)/float(rows)
    var count := stride*(rows+1)
    var verts := PackedVector3Array()
    var normals := PackedVector3Array()
    var uv := PackedVector2Array()
    verts.resize(count)
    normals.resize(count)
    uv.resize(count)
    for row in range(rows+1):
        var z := north+row*step_z
        for col in range(columns+1):
            var x := west+col*step_x
            var i := row*stride+col
            verts[i]=Vector3(x,_outer_height(x,z),z)
            uv[i]=Vector2(x/12.0,z/12.0)
    for row in range(rows+1):
        for col in range(columns+1):
            var i := row*stride+col
            var w := maxi(0,col-1)
            var e := mini(columns,col+1)
            var n := maxi(0,row-1)
            var so := mini(rows,row+1)
            var dx := float(e-w)*step_x
            var dz := float(so-n)*step_z
            var west_h: float = verts[row*stride+w].y
            var east_h: float = verts[row*stride+e].y
            var north_h: float = verts[n*stride+col].y
            var south_h: float = verts[so*stride+col].y
            normals[i]=Vector3((west_h-east_h)/dx,1.0,(north_h-south_h)/dz).normalized()
    var faces := PackedInt32Array()
    faces.resize(columns*rows*6)
    var offset := 0
    for row in range(rows):
        for col in range(columns):
            var a := row*stride+col
            var b := a+1
            var c := a+stride
            var d := c+1
            faces[offset]=a; faces[offset+1]=b; faces[offset+2]=c
            faces[offset+3]=b; faces[offset+4]=d; faces[offset+5]=c
            offset+=6
    var arrays: Array=[]
    arrays.resize(Mesh.ARRAY_MAX)
    arrays[Mesh.ARRAY_VERTEX]=verts
    arrays[Mesh.ARRAY_NORMAL]=normals
    arrays[Mesh.ARRAY_TEX_UV]=uv
    arrays[Mesh.ARRAY_INDEX]=faces
    var mesh := ArrayMesh.new()
    mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
    mesh.surface_set_material(0,EARTH_SURFACE)
    var visual := MeshInstance3D.new()
    visual.name=label
    visual.mesh=mesh
    visual.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    parent.add_child(visual)
