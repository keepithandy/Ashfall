"""Blender architectural refinement for the actual Ashfall v0.3 station.

Keeps the imported station modules as editable reference collections, and exports
only the new architectural meshes. Blender is Z-up; the GLB exporter converts to
Godot Y-up. Run in Blender 4.5 from the project directory.
"""
import bpy, math, os
from mathutils import Matrix, Vector
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
OUT = ROOT / 'assets' / 'crossroads_refined'
OUT.mkdir(parents=True, exist_ok=True)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
for col in list(bpy.data.collections):
    if col.name != 'Collection' and col.users == 0:
        bpy.data.collections.remove(col)
scene = bpy.context.scene
bpy.context.preferences.filepaths.save_version = 0
scene.unit_settings.system = 'METRIC'
scene.unit_settings.scale_length = 1.0
base_col = bpy.data.collections.new('01 | Existing station modules - reference')
new_col = bpy.data.collections.new('02 | Blender architectural refinement - exported')
scene.collection.children.link(base_col)
scene.collection.children.link(new_col)

def move_to(obj, col):
    for old in list(obj.users_collection): old.objects.unlink(obj)
    col.objects.link(obj)

def put(x, h, z):
    return Vector((x, -z, h))

def import_module(filename, placements):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=str(filename))
    bpy.context.view_layer.update()
    imported = [o for o in bpy.data.objects if o not in before]
    meshes = [o for o in imported if o.type == 'MESH']
    transforms = [(o, o.matrix_world.copy()) for o in meshes]
    for label, x, h, z, yaw in placements:
        transform = Matrix.Translation(put(x, h, z)) @ Matrix.Rotation(yaw, 4, 'Z')
        for original, mat in transforms:
            new = original.copy()
            new.data = original.data
            new.name = label + ' | ' + original.name
            base_col.objects.link(new)
            new.matrix_world = transform @ mat
    for obj in imported:
        bpy.data.objects.remove(obj, do_unlink=True)

g=ROOT/'assets'/'crossroads_v03'/'geometry'
v=ROOT/'assets'/'crossroads_v02'/'geometry'
import_module(g/'floor_slab_4m_v03.glb', [(f'Floor {x},{z}',x,0,z,0) for x in (-4,0,4) for z in (-2,2)])
import_module(g/'wall_solid_4m_v03.glb', [('Rear left',-4,0,-4,math.pi),('Side left A',-6,0,-2,-math.pi/2),('Side left B',-6,0,2,-math.pi/2),('Side right A',6,0,-2,math.pi/2),('Side right B',6,0,2,math.pi/2)])
import_module(g/'wall_window_4m_v03.glb', [('Front window',-4,0,4,0),('Rear window',0,0,-4,math.pi)])
import_module(g/'wall_garage_4m_v03.glb', [('Garage front',0,0,4,0)])
import_module(g/'wall_doorway_4m_v03.glb', [('Personnel opening',4,0,4,0)])
import_module(v/'damaged_wall_4m_v02.glb', [('Damaged rear',4,0,-4,math.pi)])
import_module(v/'steel_door_leaf_v02.glb', [('Personnel door leaf',3.39,0,4,0)])
import_module(g/'roof_panel_4m_v03.glb', [(f'Original roof {x},{z}',x,3.28,z,0) for x in (-4,0,4) for z in (-2,2)])
# Keep the replaced roof editable in Blender without obscuring the new roof.
for obj in base_col.objects:
    if obj.name.startswith('Original roof'):
        obj.hide_set(True)
        obj.hide_render = True

def solid(name, rgba, metallic=0.0, rough=0.8):
    mat=bpy.data.materials.new(name)
    mat.diffuse_color=rgba
    mat.use_nodes=True
    p=mat.node_tree.nodes.get('Principled BSDF')
    p.inputs['Base Color'].default_value=rgba
    p.inputs['Metallic'].default_value=metallic
    p.inputs['Roughness'].default_value=rough
    return mat

def image_mat(name, folder, metallic=0.0, normal_strength=.45):
    m=solid(name,(1,1,1,1),metallic,1.0)
    nodes=m.node_tree.nodes; links=m.node_tree.links; p=nodes.get('Principled BSDF')
    for kind in ('albedo','roughness','normal'):
        node=nodes.new('ShaderNodeTexImage')
        node.name=kind.title()
        node.image=bpy.data.images.load(str(ROOT/'assets'/'materials'/folder/(kind+'.jpg')),check_existing=True)
        if kind != 'albedo': node.image.colorspace_settings.name='Non-Color'
        if kind == 'albedo': links.new(node.outputs['Color'],p.inputs['Base Color'])
        elif kind == 'roughness': links.new(node.outputs['Color'],p.inputs['Roughness'])
        else:
            normal=nodes.new('ShaderNodeNormalMap'); normal.inputs['Strength'].default_value=normal_strength
            links.new(node.outputs['Color'],normal.inputs['Color']); links.new(normal.outputs['Normal'],p.inputs['Normal'])
    return m

roofmat=image_mat('Weathered corrugated steel | CC0 Poly Haven','rusty_corrugated_iron',0.48,0.40)
concrete=image_mat('Worn concrete | CC0 Poly Haven','concrete_floor_worn_001',0,0.32)
plaster=image_mat('Weathered maintenance wall | CC0 Poly Haven','grey_plaster',0,0.45)
steel=solid('Oxidised graphite steel',(0.105,0.125,0.12,1),.62,.72)
edge=solid('Faded galvanised edge',(0.22,0.24,0.21,1),.56,.7)
rust=solid('Old brown rust accents',(0.17,0.09,0.055,1),.45,.91)
ceiling=solid('Dusty underside and purlins',(0.18,0.19,0.17,1),.30,.87)

# Update the imported wall meshes in the editable Blender assembly. The
# original v0.3 GLBs are left untouched; only copies are exported below.
wall_labels=('Rear left','Side left A','Side left B','Side right A','Side right B','Front window','Rear window','Garage front','Personnel opening')
for obj in base_col.objects:
    if obj.name.startswith(wall_labels) and 'concrete_combined' in obj.name:
        if obj.data.materials: obj.data.materials[0]=plaster
        for face in obj.data.polygons: face.use_smooth=False
    if obj.name.startswith('Damaged rear | DamagedConcreteStructuralCore'):
        if obj.data.materials: obj.data.materials[0]=plaster
        for face in obj.data.polygons: face.use_smooth=False

def box(name, center, dims, mat, bevel=.01):
    bpy.ops.mesh.primitive_cube_add(size=1,location=put(*center))
    o=bpy.context.object; o.name=name; move_to(o,new_col)
    o.dimensions=(dims[0],dims[2],dims[1])
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    o.data.materials.append(mat)
    if bevel:
        mod=o.modifiers.new('Manufactured edge wear','BEVEL'); mod.width=bevel; mod.segments=2
        mod=o.modifiers.new('Weighted face normals','WEIGHTED_NORMAL'); mod.keep_sharp=True
    bpy.context.view_layer.objects.active=o
    bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='SELECT'); bpy.ops.uv.cube_project(cube_size=2.0); bpy.ops.object.mode_set(mode='OBJECT')
    return o

def rod(name, a, b, radius, mat, vertices=12):
    a=put(*a); b=put(*b); delta=b-a
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=delta.length, location=(a+b)*.5)
    o=bpy.context.object; o.name=name; move_to(o,new_col)
    o.rotation_mode='QUATERNION'; o.rotation_quaternion=delta.to_track_quat('Z','Y')
    o.data.materials.append(mat)
    for poly in o.data.polygons: poly.use_smooth=(len(poly.vertices)==4)
    return o

def corrugated(name, x0, x1, z0, z1, height_func, mat, step=.075, amp=.015, wavelength=.30):
    # Modelled corrugation catches real highlights and avoids coplanar roof seams.
    nx=int(math.ceil((x1-x0)/step)); nz=max(1,int(math.ceil((z1-z0)/2)))
    verts=[]; faces=[]
    for iz in range(nz+1):
        z=z0+(z1-z0)*iz/nz
        for ix in range(nx+1):
            x=x0+(x1-x0)*ix/nx
            h=height_func(x,z)+amp*math.cos((x-x0)*math.tau/wavelength)
            verts.append(tuple(put(x,h,z)))
    for iz in range(nz):
        for ix in range(nx):
            a=iz*(nx+1)+ix; faces.append((a,a+nx+1,a+1+nx+1,a+1))
    mesh=bpy.data.meshes.new(name); mesh.from_pydata(verts,[],faces); mesh.update()
    o=bpy.data.objects.new(name,mesh); new_col.objects.link(o); o.data.materials.append(mat)
    uv=mesh.uv_layers.new(name='World scale')
    for face in mesh.polygons:
        for li in face.loop_indices:
            co=mesh.vertices[mesh.loops[li].vertex_index].co
            uv.data[li].uv=(co.x/3.0, co.y/3.0)
    o.data.polygons.foreach_set('use_smooth',[True]*len(o.data.polygons))
    return o

# A single weathered sheet ties the six original roof modules together. The
# underlying collision remains the original modular collision in Godot.
box('Continuous roof deck',(0,3.29,0),(12.38,.16,8.38),ceiling,.014)
corrugated('Continuous standing-corrugation roof',-6.25,6.25,-4.22,4.22,
           lambda x,z:3.465-.008*z,roofmat)
# Edge flashings give the roof a coherent silhouette, with a modest overhang.
for z in (-4.23,4.23):
    box('Long eave flashing',(0,3.45,z),(12.56,.13,.085),edge,.009)
for x in (-6.25,6.25):
    box('Gable edge flashing',(x,3.45,0),(.09,.13,8.48),edge,.009)
# Visible underside structure, kept clear of the pendant light.
for z in (-3.4,-1.35,1.35,3.4):
    box('Ceiling steel purlin',(0,3.155,z),(12.06,.13,.10),steel,.008)
# Seams, modest counter-flashing and fasteners instead of oversized trim.
for x in (-4,-2,0,2,4):
    for z in (-3.85,3.85):
        h=3.465-.008*z+.015
        rod('Roof fastener',(x,h,z),(x,h+.018,z),.018,rust,8)
# Gutters and two downpipes on outside corners, both clear of the doorway.
for z in (-4.31,4.31):
    box('Eaves gutter',(0,3.27,z),(12.52,.11,.14),steel,.01)
    for x in (-5.65,-3.0,0,3.0,5.65):
        box('Gutter hanger',(x,3.26,z),(.035,.14,.18),edge,.004)
for x,z in ((-5.72,4.32),(5.70,-4.32)):
    rod('Downpipe',(x,0.30,z),(x,3.24,z),.045,steel,12)
    rod('Downpipe lower elbow',(x,.30,z),(x,.18,z+(.15 if z>0 else -.15)),.045,steel,12)
    for h in (.54,1.72,2.78):
        rod('Downpipe clamp',(x-.07,h,z),(x+.07,h,z),.012,edge,10)
# Ventilation flue gives the roof an identifiable, practical silhouette.
box('Vent flashing plinth',(-3.0,3.49,-1.7),(.55,.075,.55),steel,.018)
rod('Vent stack',(-3.0,3.50,-1.7),(-3.0,4.03,-1.7),.11,edge,20)
rod('Vent hood',(-3.0,4.03,-1.7),(-3.0,4.085,-1.7),.19,steel,20)
# A small corrugated rain hood over the actual personnel door. It starts above
# the 2.4 m door and has no collision, leaving the player's route clear.
corrugated('Personnel door rain hood',3.13,4.87,4.16,5.03,
           lambda x,z:2.87-(z-4.16)*.16,roofmat,step=.05,amp=.012,wavelength=.20)
box('Door hood wall flashing',(4,2.88,4.14),(1.80,.11,.06),edge,.006)
for x in (3.22,4.78):
    rod('Hood support strut',(x,2.43,4.15),(x,2.73,4.88),.018,steel,10)
    rod('Hood front rail',(x,2.75,4.18),(x,2.73,4.96),.015,steel,10)
# Door and window drip caps cover seams without blocking the existing openings.
for x,z,h,w in [(-4,4.19,2.34,1.98),(0,-4.19,2.34,1.98)]:
    box('Window drip cap',(x,h,z),(w,.045,.16),edge,.006)
# Slim exposed uprights soften the module joins and anchor the industrial facade.
for x in (-5.92,-2.0,2.0,5.92):
    box('Front seam upright',(x,1.66,4.155),(.075,3.12,.065),edge,.009)
for x in (-5.92,-2.0,2.0,5.92):
    box('Rear seam upright',(x,1.66,-4.155),(.075,3.12,.065),edge,.009)
# Sill flashing and a discreet utility sleeve read clearly from the yard.
box('Window sill cap',(-4,.88,4.20),(1.90,.045,.22),edge,.005)
rod('Wall conduit vertical',(-5.44,.34,4.17),(-5.44,2.72,4.17),.018,steel,10)
for h in (.58,1.4,2.34):
    box('Conduit fixing',(-5.44,h,4.17),(.12,.04,.075),edge,.004)

# Save the editable assembled source, including packed images and original refs.
scene.render.engine='CYCLES'
bpy.ops.object.select_all(action='DESELECT')
bpy.ops.file.pack_all()
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'source'/'crossroads_station_refined.blend'))
# Export the revised wall modules in their original local coordinates. Each
# remains interchangeable with its existing Godot collision wrapper.
variants=[('Rear left',(-4,0,-4,math.pi),'wall_solid_refined.glb'),
          ('Front window',(-4,0,4,0),'wall_window_refined.glb'),
          ('Personnel opening',(4,0,4,0),'wall_doorway_refined.glb'),
          ('Garage front',(0,0,4,0),'wall_garage_refined.glb'),
          ('Damaged rear',(4,0,-4,math.pi),'damaged_wall_refined.glb')]
for label, (x,h,z,yaw), filename in variants:
    originals=[o for o in base_col.objects if o.name.startswith(label+' | ')]
    inverse=(Matrix.Translation(put(x,h,z)) @ Matrix.Rotation(yaw,4,'Z')).inverted()
    bpy.ops.object.select_all(action='DESELECT')
    copies=[]
    for obj in originals:
        clone=obj.copy(); clone.data=obj.data.copy(); scene.collection.objects.link(clone)
        clone.matrix_world=inverse @ obj.matrix_world
        clone.hide_set(False); clone.hide_render=False; clone.select_set(True)
        copies.append(clone)
    # The damaged wall has many small crack and rebar objects; combine copies
    # with the same material for the exported game asset only.
    material_groups={}
    for clone in copies:
        key=clone.data.materials[0].name if clone.data.materials else ''
        material_groups.setdefault(key,[]).append(clone)
    batched=[]
    for group in material_groups.values():
        bpy.ops.object.select_all(action='DESELECT')
        for clone in group: clone.select_set(True)
        bpy.context.view_layer.objects.active=group[0]
        if len(group)>1: bpy.ops.object.join()
        batched.append(group[0])
    bpy.ops.object.select_all(action='DESELECT')
    for clone in batched: clone.select_set(True)
    bpy.context.view_layer.objects.active=batched[0]
    bpy.ops.export_scene.gltf(filepath=str(OUT/filename),export_format='GLB',use_selection=True,export_apply=True,export_yup=True,export_normals=True,export_texcoords=True)
    for clone in batched: bpy.data.objects.remove(clone,do_unlink=True)
# Keep the saved Blender objects editable. Batch temporary copies by material
# for the game, so all the small fasteners don't become separate draw calls.
export_col=bpy.data.collections.new('Export staging - not in saved source')
scene.collection.children.link(export_col)
groups={}
for original in list(new_col.objects):
    copy=original.copy(); copy.data=original.data.copy()
    export_col.objects.link(copy)
    bpy.ops.object.select_all(action='DESELECT')
    copy.select_set(True); bpy.context.view_layer.objects.active=copy
    for modifier in list(copy.modifiers):
        bpy.ops.object.modifier_apply(modifier=modifier.name)
    groups.setdefault(copy.data.materials[0].name, []).append(copy)
combined=[]
for name, objects in groups.items():
    bpy.ops.object.select_all(action='DESELECT')
    for obj in objects: obj.select_set(True)
    bpy.context.view_layer.objects.active=objects[0]
    if len(objects)>1: bpy.ops.object.join()
    objects[0].name='Architecture | '+name
    combined.append(objects[0])
bpy.ops.object.select_all(action='DESELECT')
for obj in combined: obj.select_set(True)
bpy.context.view_layer.objects.active=combined[0]
bpy.ops.export_scene.gltf(filepath=str(OUT/'architecture_pass.glb'),export_format='GLB',use_selection=True,export_apply=True,export_yup=True,export_normals=True,export_texcoords=True)
print('REFINEMENT_OBJECTS',len(new_col.objects),'REFERENCE_OBJECTS',len(base_col.objects),'EXPORT_BATCHES',len(combined),flush=True)
