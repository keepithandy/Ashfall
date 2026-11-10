"""Derive the playable mannequin without changing the anatomy study or wardrobe.

Fits the existing torch to the anatomical right palm, adds a real item bone,
calibrates the finger grip, and authors in-place locomotion for this rest rig.
"""
import bpy
import json
import math
import os
import tempfile
import sys
from mathutils import Vector, Quaternion, Matrix, Euler
from mathutils.geometry import intersect_point_line

ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if os.path.exists(os.path.join(ROOT,'assets','characters','hand_authoring','source','hand_authoring.blend')) and '--legacy-rebuild' not in sys.argv:
    raise RuntimeError('Current player hand poses are authored in Blender. Use export_authored_hand.py; --legacy-rebuild explicitly rebuilds the older player baseline.')
BASE=os.path.join(ROOT,'assets','characters','male_mannequin')
OUT=os.path.join(ROOT,'assets','characters','mannequin_player')
SOURCE=os.path.join(OUT,'source')
os.makedirs(SOURCE,exist_ok=True)
tempfile.tempdir=os.path.join(ROOT,'.godot','mannequin-player-export')
os.makedirs(tempfile.tempdir,exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=os.path.join(BASE,'source','male_mannequin.blend'))
rig=bpy.data.objects['MannequinRig']
body=bpy.data.objects['MaleMannequinBody']
rig.hide_set(False)
if rig.animation_data:
    rig.animation_data_clear()
for pose in rig.pose.bones:
    pose.rotation_mode='QUATERNION';pose.rotation_quaternion=Quaternion();pose.location=(0,0,0)

def head(name):return rig.data.bones[name].head_local.copy()
def unit(v):return v.normalized()
def godot(v):return [v.x,v.z,-v.y]

wrist=head('hand.R')
knuckles=[head(n+'1.R') for n in ['index','middle','ring','pinky']]
distal=unit(sum(knuckles,Vector())/4-wrist)
across=unit(knuckles[0]-knuckles[3])
across=unit(across-distal*across.dot(distal))
palm_normal=unit(across.cross(distal))
# In the neutral source the backs/nails face forward; curl into the palm.
if palm_normal.y>0:
    across=-across;palm_normal=-palm_normal
torch_forward=unit(distal*.8660254-across*.5)
up=unit(distal-torch_forward*distal.dot(torch_forward))
side=unit(torch_forward.cross(up))
palm=sum(knuckles,Vector())/4-distal*.015
center=palm+palm_normal*.037+distal*.010
torch_scale=.84
orientation=Matrix((side,torch_forward,up)).transposed()

# Keep the palm on the hand bone until each real knuckle. The study's generic
# nearest-bone weights let finger roots drag the palm when closing a tight grip.
def segment_distance(point,bone_name):
    b=rig.data.bones[bone_name]
    _,t=intersect_point_line(point,b.head_local,b.tail_local)
    return (point-b.head_local.lerp(b.tail_local,max(0,min(1,t)))).length

for v in body.data.vertices:
    offset=v.co-wrist
    if offset.length>.22 or offset.dot(distal)<-.012:continue
    fingers=['thumb','index','middle','ring','pinky']
    finger=min(fingers,key=lambda n:min(segment_distance(v.co,n+str(j)+'.R') for j in range(1,4)))
    start=head(finger+'1.R')
    along=(v.co-start).dot(distal)
    blend=max(0,min(1,(along+.010)/.022))
    blend=blend*blend*(3-2*blend)
    # The thumb begins closer to the wrist and follows its own root direction.
    if finger=='thumb':
        direction=unit(rig.data.bones['thumb1.R'].tail_local-start)
        along=(v.co-start).dot(direction)
        blend=max(0,min(1,(along+.006)/.020))
    chosen=sorted((segment_distance(v.co,finger+str(j)+'.R'),finger+str(j)+'.R') for j in range(1,4))[:2]
    strengths=[1/max(.003,d)**4 for d,_ in chosen];total=sum(strengths)
    weights={'hand.R':1-blend}
    for strength,(_,name) in zip(strengths,chosen):weights[name]=blend*strength/total
    for group in list(v.groups):body.vertex_groups[group.group].remove([v.index])
    for name,value in weights.items():
        if value>0.00001:body.vertex_groups[name].add([v.index],value,'REPLACE')

old_source=os.path.join(ROOT,'assets','characters','scavenger','source','ashfall_scavenger.blend')
with bpy.data.libraries.load(old_source,link=False) as (data_from,data_to):
    data_to.objects=['Flashlight']
torch=data_to.objects[0]
torch.parent=None
bpy.context.scene.collection.objects.link(torch)
with open(os.path.join(ROOT,'assets','characters','scavenger','manifest.json')) as f:
    old_center=Vector(json.load(f)['torch_center_blender'])
for vertex in torch.data.vertices:
    vertex.co=center+orientation@((vertex.co-old_center)*torch_scale)
torch.matrix_world=Matrix.Identity(4)
torch.vertex_groups.clear()
group=torch.vertex_groups.new(name='item.R')
group.add(list(range(len(torch.data.vertices))),1,'REPLACE')
for modifier in list(torch.modifiers):
    if modifier.type=='ARMATURE':torch.modifiers.remove(modifier)
modifier=torch.modifiers.new('Right hand item socket skin','ARMATURE');modifier.object=rig
torch.parent=rig

bpy.ops.object.select_all(action='DESELECT');rig.select_set(True)
bpy.context.view_layer.objects.active=rig
bpy.ops.object.mode_set(mode='EDIT')
item=rig.data.edit_bones.new('item.R');item.head=center;item.tail=center+torch_forward*.16*torch_scale
item.parent=rig.data.edit_bones['hand.R']
bpy.ops.object.mode_set(mode='OBJECT')

grip={}
for finger in ['index','middle','ring','pinky','thumb']:
    angles={'index':(.38,.92,.68),'middle':(.45,1.02,.80),'ring':(.50,1.05,.85),'pinky':(.55,1.0,.85),'thumb':(.25,.50,.35)}[finger]
    for j,angle in enumerate(angles,1):
        name=finger+str(j)+'.R'
        rest=rig.data.bones[name].matrix_local.to_quaternion()
        q=rest.inverted()@Quaternion(across,angle)@rest
        rig.pose.bones[name].rotation_mode='QUATERNION'
        rig.pose.bones[name].rotation_quaternion=q

def fit_tip(finger,target,iterations):
    chain=[rig.pose.bones[finger+str(j)+'.R'] for j in range(1,4)]
    for _ in range(iterations):
        for p in reversed(chain):
            bpy.context.view_layer.update()
            pivot=p.head.copy();tip=chain[-1].tail.copy()
            a=tip-pivot;b=target-pivot
            if a.length<.0001 or b.length<.0001:continue
            q=a.normalized().rotation_difference(b.normalized())
            if q.angle>.14:q=Quaternion(q.axis,.14)
            p.matrix=Matrix.Translation(pivot)@q.to_matrix().to_4x4()@Matrix.Translation(-pivot)@p.matrix
    bpy.context.view_layer.update()

for finger in ['index','middle','ring','pinky']:
    along=(head(finger+'1.R')-center).dot(torch_forward)
    target=center+torch_forward*along+palm_normal*.029-up*.012
    fit_tip(finger,target,7)
fit_tip('thumb',center+torch_forward*.015*torch_scale+up*.035*torch_scale,10)
for finger in ['index','middle','ring','pinky','thumb']:
    for j in range(1,4):
        name=finger+str(j)+'.R';q=rig.pose.bones[name].rotation_quaternion.normalized()
        if q.w<0:q.negate()
        limit=([.8,1.2,1.0] if finger=='thumb' else [1.2,1.6,1.25])[j-1]
        if q.angle>limit:q=Quaternion(q.axis,limit)
        grip[name]=[q.x,q.y,q.z,q.w]
for p in rig.pose.bones:p.rotation_quaternion=Quaternion()

profile={
    'model':'male mannequin','body_mesh':'MaleMannequinBody',
    'beam_position':godot(center+torch_forward*.155*torch_scale),
    'beam_forward':godot(torch_forward),'beam_up':godot(up),
    'hand_forward':godot(torch_forward),'hand_up':godot(up),
    'hand_drop':.18,'neck_aim_weight':0.0,
    'grip_rotations':grip,
    'item_center':godot(center),'wrist_rest':godot(wrist),
    'ankle_heights':{s:rig.data.bones['foot.'+s].head_local.z for s in ['R','L']}
}
with open(os.path.join(OUT,'player_profile.json'),'w') as f:json.dump(profile,f,indent=2)

def rotate_world(name,angles):
    p=rig.pose.bones[name];rest=p.bone.matrix_local.to_quaternion()
    p.rotation_mode='QUATERNION'
    p.rotation_quaternion=rest.inverted()@Euler(angles,'XYZ').to_quaternion()@rest

def action(name,frames,mode):
    rig.animation_data_create();rig.animation_data.action=None
    for f in range(frames+1):
        phase=math.tau*f/frames
        for p in rig.pose.bones:
            p.rotation_mode='QUATERNION';p.rotation_quaternion=Quaternion();p.location=(0,0,0)
        for s,side in [(1,'R'),(-1,'L')]:
            rotate_world('upper_arm.'+side,(0,s*.60,0))
            rotate_world('forearm.'+side,(0,s*.08,0))
        rotate_world('chest',(.007*math.sin(phase),0,.006*math.sin(phase)))
        if mode in ['walk','run','back','left','right']:
            amplitude=.43 if mode!='run' else .72
            for s,side in [(1,'R'),(-1,'L')]:
                swing=math.sin(phase+(0 if s==1 else math.pi))
                if mode in ['left','right']:
                    rotate_world('thigh.'+side,(.04,amplitude*swing*(1 if mode=='left' else -1),0))
                else:
                    rotate_world('thigh.'+side,(amplitude*swing*(-1 if mode=='back' else 1),0,0))
                rotate_world('shin.'+side,(-max(0,-swing)*(.9 if mode=='run' else .6),0,0))
                rotate_world('foot.'+side,(max(0,-swing)*.32-amplitude*swing*.4,0,0))
                rotate_world('upper_arm.'+side,(-amplitude*swing*.35,s*.60,0))
            rig.pose.bones['pelvis'].location=rig.data.bones['pelvis'].matrix_local.to_quaternion().inverted()@Vector((0,0,abs(math.sin(phase))*.012))
            rotate_world('chest',(.03 if mode=='run' else .01,0,.02*math.sin(phase)))
        if mode in ['crouch_idle','crouch_walk']:
            rig.pose.bones['pelvis'].location=rig.data.bones['pelvis'].matrix_local.to_quaternion().inverted()@Vector((0,0,-.38))
            for side in ['R','L']:
                swing=math.sin(phase+(0 if side=='R' else math.pi))*.12 if mode=='crouch_walk' else 0
                rotate_world('thigh.'+side,(1.0+swing,0,0))
                rotate_world('shin.'+side,(-2.0,0,0))
                rotate_world('foot.'+side,(1.0,0,0))
            rotate_world('spine',(-.30,0,0));rotate_world('spine_mid',(-.24,0,0));rotate_world('chest',(-.25,0,0))
        if mode=='air':
            for side in ['R','L']:
                rotate_world('thigh.'+side,(.30,0,0));rotate_world('shin.'+side,(-.60,0,0))
        for p in rig.pose.bones:
            p.keyframe_insert('rotation_quaternion',frame=f+1,group=p.name)
            if p.name=='pelvis':p.keyframe_insert('location',frame=f+1,group=p.name)
    clip=rig.animation_data.action;clip.name=name
    track=rig.animation_data.nla_tracks.new();track.name=name
    strip=track.strips.new(name,1,clip);strip.action_frame_start=1;strip.action_frame_end=frames+1
    track.mute=True

for name,frames,mode in [('Idle',90,'idle'),('Walk',32,'walk'),('Run',22,'run'),('WalkBack',36,'back'),('StrafeLeft',34,'left'),('StrafeRight',34,'right'),('CrouchIdle',90,'crouch_idle'),('CrouchWalk',48,'crouch_walk'),('Airborne',30,'air')]:
    action(name,frames,mode)
rig.animation_data.action=None
for p in rig.pose.bones:p.rotation_quaternion=Quaternion();p.location=(0,0,0)
bpy.context.scene.frame_set(1)
bpy.ops.file.pack_all()
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(SOURCE,'mannequin_player.blend'))
for modifier in list(body.modifiers):
    if modifier.type=='SUBSURF':
        modifier.levels=1;bpy.context.view_layer.objects.active=body
        bpy.ops.object.modifier_apply(modifier=modifier.name)
for v in body.data.vertices:
    chosen=sorted(((g.group,g.weight) for g in v.groups),key=lambda x:x[1],reverse=True)[:4]
    keep={i for i,_ in chosen}
    for g in list(v.groups):
        if g.group not in keep:body.vertex_groups[g.group].remove([v.index])
    total=sum(w for _,w in chosen)
    for i,w in chosen:body.vertex_groups[i].add([v.index],w/total,'REPLACE')
for track in rig.animation_data.nla_tracks:track.mute=False
bpy.ops.export_scene.gltf(filepath=os.path.join(OUT,'mannequin_player.glb'),export_format='GLB',export_yup=True,export_animations=True,export_animation_mode='NLA_TRACKS',export_nla_strips=True,export_skins=True,export_force_sampling=True)
print('MANNEQUIN_PLAYER_EXPORTED',len(rig.data.bones),'bones; continuous body, fitted torch and nine locomotion clips')

# Finish with independent props and authored grip resources. The player export
# must never bake a particular held item back into the character geometry.
import sys
sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))
from build_hand_grips import build as build_held_items
build_held_items()
