"""Anatomy-only adult male mannequin from the existing CC0 body source.

No clothing, hair, equipment or skin textures. Metres, +Y forward, Z up in
Blender. A continuous anatomical cage stays editable beneath subdivision.
"""
import bpy
import json
import math
import os
import sys
import tempfile
from mathutils import Vector, Quaternion
from mathutils.geometry import intersect_point_line

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)
from scavenger_head import obj_data

OUT = os.path.join(ROOT, 'assets', 'characters', 'male_mannequin')
SOURCE = os.path.join(OUT, 'source')
UPSTREAM = os.path.join(ROOT, 'assets', 'characters', 'scavenger', 'source', 'makehuman')
os.makedirs(SOURCE, exist_ok=True)
tempfile.tempdir = os.path.join(ROOT, '.godot', 'mannequin-export')
os.makedirs(tempfile.tempdir, exist_ok=True)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)

vertices, uvs, faces = obj_data(os.path.join(UPSTREAM, 'base.obj'))
with open(os.path.join(UPSTREAM, 'adult-male.target')) as handle:
    for line in handle:
        a = line.split()
        if len(a) == 4 and not line.startswith('#'):
            vertices[int(a[0])] += Vector(tuple(map(float, a[1:])))

body_faces = [face for face in faces if face[2] == 'body']
body_ids = sorted({i for ids, _, _ in body_faces for i in ids})
floor_y = min(vertices[i].y for i in body_ids)
top_y = max(vertices[i].y for i in body_ids)
scale = 1.80 / (top_y - floor_y)
raw_joints = {}
for ids, _, group in faces:
    if group.startswith('joint-'):
        raw_joints.setdefault(group, set()).update(ids)
raw_joints = {name: sum((vertices[i] for i in ids), Vector())/len(ids) for name, ids in raw_joints.items()}
depth = raw_joints['joint-pelvis'].z

def convert(v):
    # Proper rotation (not a reflected head/body) from MakeHuman's axes.
    return Vector((-v.x*scale, (v.z-depth)*scale, (v.y-floor_y)*scale))

joints = {name: convert(p) for name, p in raw_joints.items()}
mapping = {old: new for new, old in enumerate(body_ids)}
coords = [convert(vertices[i]) for i in body_ids]
hip_height = joints['joint-pelvis'].z
# The plain display mannequin has a deliberately smooth, featureless groin.
for p in coords:
    x = abs(p.x)/.053
    z = abs(p.z-(hip_height-.10))/.075
    if x < 1 and z < 1 and p.y > .015:
        influence = (1-x*x)**2 * (1-z*z)**2
        p.y += (min(p.y,.070)-p.y)*influence

me = bpy.data.meshes.new('Continuous male anatomical cage')
me.from_pydata(coords, [], [tuple(mapping[i] for i in ids) for ids, _, _ in body_faces])
me.update()
uv = me.uv_layers.new(name='AnatomicalUV')
for poly, (_, ui, _) in zip(me.polygons, body_faces):
    for li, ti in zip(poly.loop_indices, ui):
        uv.data[li].uv = uvs[ti]
body = bpy.data.objects.new('MaleMannequinBody', me)
bpy.context.collection.objects.link(body)
for poly in me.polygons:
    poly.use_smooth = True

def material(name, color, roughness):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    p = m.node_tree.nodes.get('Principled BSDF')
    p.inputs['Base Color'].default_value = (*color,1)
    p.inputs['Roughness'].default_value = roughness
    m.diffuse_color=(*color,1)
    return m

clay = material('Neutral matte mannequin', (.38,.42,.43), .65)
eye_mat = material('Unpainted mannequin eyes', (.34,.375,.385), .55)
body.data.materials.append(clay)

bones = {}
def bone(name, head, tail, parent=None):
    assert (tail-head).length > .0001, name
    bones[name] = (head.copy(), tail.copy(), parent)

def joint(name):
    return joints['joint-'+name]

bone('root', Vector((0,0,0)), Vector((0,0,.12)))
bone('pelvis', joint('pelvis'), joint('spine-4'), 'root')
bone('spine', joint('spine-4'), joint('spine-3'), 'pelvis')
bone('spine_mid', joint('spine-3'), joint('spine-2'), 'spine')
bone('chest', joint('spine-2'), joint('spine-1'), 'spine_mid')
bone('neck', joint('spine-1'), joint('head'), 'chest')
bone('head', joint('head'), joint('head-2'), 'neck')
bone('jaw', joint('jaw'), joint('mouth'), 'head')
for side, raw in [('R','r'),('L','l')]:
    bone('clavicle.'+side, joint('spine-1'), joint(raw+'-shoulder'), 'chest')
    bone('upper_arm.'+side, joint(raw+'-shoulder'), joint(raw+'-elbow'), 'clavicle.'+side)
    bone('forearm.'+side, joint(raw+'-elbow'), joint(raw+'-hand'), 'upper_arm.'+side)
    bone('hand.'+side, joint(raw+'-hand'), joint(raw+'-hand-3'), 'forearm.'+side)
    bone('thigh.'+side, joint(raw+'-upper-leg'), joint(raw+'-knee'), 'pelvis')
    bone('shin.'+side, joint(raw+'-knee'), joint(raw+'-ankle'), 'thigh.'+side)
    bone('foot.'+side, joint(raw+'-ankle'), joint(raw+'-foot-2'), 'shin.'+side)
    bone('toe.'+side, joint(raw+'-foot-2'), joint(raw+'-toe-2-3'), 'foot.'+side)
    bone('eye.'+side, joint(raw+'-eye'), joint(raw+'-eye-target'), 'head')
    for k,name in enumerate(['thumb','index','middle','ring','pinky'],1):
        for segment in range(1,4):
            bone(name+str(segment)+'.'+side, joint(f'{raw}-finger-{k}-{segment}'), joint(f'{raw}-finger-{k}-{segment+1}'), 'hand.'+side if segment==1 else name+str(segment-1)+'.'+side)

arm_data = bpy.data.armatures.new('Male anatomical deform skeleton')
rig = bpy.data.objects.new('MannequinRig', arm_data)
bpy.context.collection.objects.link(rig)
bpy.context.view_layer.objects.active = rig
rig.select_set(True)
bpy.ops.object.mode_set(mode='EDIT')
for name,(a,b,parent) in bones.items():
    eb = arm_data.edit_bones.new(name)
    eb.head = a
    eb.tail = b
    if parent:
        eb.parent = arm_data.edit_bones[parent]
bpy.ops.object.mode_set(mode='OBJECT')
rig.show_in_front = True

def distance_to_segment(p, name):
    a,b,_ = bones[name]
    _,t = intersect_point_line(p,a,b)
    return (p-a.lerp(b,max(0,min(1,t)))).length

def candidates(p):
    side = 'R' if p.x >= 0 else 'L'
    wrist = bones['hand.'+side][0]
    hand_direction = (bones['hand.'+side][1]-wrist).normalized()
    if (p-wrist).dot(hand_direction) > .018 and (p-wrist).length < .24:
        finger_names = ['thumb','index','middle','ring','pinky']
        best = min(finger_names,key=lambda n:min(distance_to_segment(p,n+str(j)+'.'+side) for j in range(1,4)))
        return ['hand.'+side]+[best+str(j)+'.'+side for j in range(1,4)]
    if p.z > joint('head').z-.025:
        return ['neck','head']
    if p.z < hip_height-.09:
        return ['pelvis','thigh.'+side,'shin.'+side,'foot.'+side,'toe.'+side]
    return ['pelvis','spine','spine_mid','chest','neck','clavicle.'+side,'upper_arm.'+side,'forearm.'+side,'hand.'+side]

groups = {name:body.vertex_groups.new(name=name) for name in bones}
for v in body.data.vertices:
    chosen = sorted(((distance_to_segment(v.co,n),n) for n in candidates(v.co)))[:4]
    values = [1/max(.008,d)**5 for d,_ in chosen]
    total = sum(values)
    for value,(_,name) in zip(values,chosen):
        if value/total > .0001:
            groups[name].add([v.index], value/total, 'REPLACE')
    # Renormalize after trimming negligible weights.
    remaining = sum(g.weight for g in v.groups)
    for g in list(v.groups):
        body.vertex_groups[g.group].add([v.index],g.weight/remaining,'REPLACE')
body.parent = rig
skin = body.modifiers.new('Full body skin weights', 'ARMATURE')
skin.object = rig
sub = body.modifiers.new('Editable anatomical subdivision', 'SUBSURF')
sub.levels = 2
sub.render_levels = 2

# Eyeballs are unpainted clay, with no iris, hair, eyebrows or face texture.
eyes = []
for side,raw in [('R','r'),('L','l')]:
    center = joint(raw+'-eye')
    bpy.ops.mesh.primitive_uv_sphere_add(segments=32,ring_count=20,location=center)
    eye = bpy.context.object
    eye.name = 'MannequinEye.'+side
    eye.scale = (.0118,.0118,.0118)
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    eye.data.materials.append(eye_mat)
    for p in eye.data.polygons:
        p.use_smooth=True
    group=eye.vertex_groups.new(name='eye.'+side)
    group.add(list(range(len(eye.data.vertices))),1,'REPLACE')
    modifier=eye.modifiers.new('Eye joint','ARMATURE');modifier.object=rig
    eye.parent=rig
    eyes.append(eye)

# Neutral anatomy pose, plus a bounded joint test for inspecting deformation.
def pose_world(name, axis, angle):
    rest=rig.data.bones[name].matrix_local.to_quaternion()
    rig.pose.bones[name].rotation_mode='QUATERNION'
    rig.pose.bones[name].rotation_quaternion=rest.inverted()@Quaternion(axis,angle)@rest

rig.animation_data_create()
for frame,amount in [(1,0),(31,1),(61,0)]:
    for p in rig.pose.bones:
        p.rotation_mode='QUATERNION';p.rotation_quaternion=Quaternion()
    for side,s in [('R',1),('L',-1)]:
        pose_world('forearm.'+side,Vector((1,0,0)),amount*.8)
        pose_world('upper_arm.'+side,Vector((0,1,0)),amount*s*.20)
        pose_world('thigh.'+side,Vector((1,0,0)),amount*.25)
        pose_world('shin.'+side,Vector((1,0,0)),-amount*.55)
    for p in rig.pose.bones:
        p.keyframe_insert('rotation_quaternion',frame=frame,group=p.name)
rig.animation_data.action.name='JointInspection'
for p in rig.pose.bones:
    p.rotation_quaternion=Quaternion()
bpy.context.scene.frame_set(1)
bpy.context.scene.render.fps=30

anatomy=bpy.data.collections.new('01 Anatomy — edit the continuous body here')
bpy.context.scene.collection.children.link(anatomy)
for ob in [body,*eyes]:
    for collection in list(ob.users_collection):collection.objects.unlink(ob)
    anatomy.objects.link(ob)
rig_collection=bpy.data.collections.new('02 Deformation rig')
bpy.context.scene.collection.children.link(rig_collection)
for collection in list(rig.users_collection):collection.objects.unlink(rig)
rig_collection.objects.link(rig)

for v in body.data.vertices:
    assert v.groups and abs(sum(g.weight for g in v.groups)-1)<.001
assert abs(min(p.z for p in coords))<.00001
assert abs(max(p.z for p in coords)-1.8)<.00001
rig['study']='Male anatomy mannequin; unpainted clay; no clothing or equipment'
rig['height_m']=1.8
rig['source']='MakeHuman core base and adult male target, CC0. See CREDITS.md.'
bpy.ops.object.select_all(action='DESELECT')
body.select_set(True)
bpy.context.view_layer.objects.active=body
rig.hide_set(True)
for screen in bpy.data.screens:
    for area in screen.areas:
        if area.type=='VIEW_3D':
            area.spaces.active.region_3d.view_location=Vector((0,0,.92))
            area.spaces.active.region_3d.view_distance=3.0
            area.spaces.active.region_3d.view_rotation=Vector((0,-1,0)).to_track_quat('-Z','Y')
            area.spaces.active.shading.color_type='MATERIAL'
manifest={
    'height_m':1.8,'base_vertices':len(me.vertices),'base_faces':len(me.polygons),
    'bone_count':len(bones),'material':'neutral matte clay','wardrobe_included':False,
    'design':'Adult male display mannequin, bald, unpainted and with a smooth neutral groin',
    'source_cage':'Continuous original body/neck/head topology, with editable subdivision',
    'joints_blender':{n:list(v) for n,v in joints.items() if n in ['joint-pelvis','joint-neck','joint-head','joint-r-shoulder','joint-r-knee','joint-r-hand','joint-r-ankle']}
}
with open(os.path.join(OUT,'manifest.json'),'w') as f:json.dump(manifest,f,indent=2)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(SOURCE,'male_mannequin.blend'))
rig.hide_set(False)
# Export a single subdivision level; keep the two-level editable source intact.
sub.levels=1
bpy.context.view_layer.objects.active=body
bpy.ops.object.modifier_apply(modifier=sub.name)
for v in body.data.vertices:
    chosen=sorted(((g.group,g.weight) for g in v.groups),key=lambda entry:entry[1],reverse=True)[:4]
    keep={index for index,_ in chosen}
    for group in list(v.groups):
        if group.group not in keep:
            body.vertex_groups[group.group].remove([v.index])
    total=sum(w for _,w in chosen)
    for index,w in chosen:
        body.vertex_groups[index].add([v.index],w/total,'REPLACE')
bpy.ops.export_scene.gltf(filepath=os.path.join(OUT,'male_mannequin.glb'),export_format='GLB',export_yup=True,export_animations=True,export_skins=True,export_force_sampling=True)
print('MALE_MANNEQUIN_EXPORTED',json.dumps(manifest))
