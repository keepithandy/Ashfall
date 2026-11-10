"""Build an editable hand candidate from original CC0 topology weights.

Does not run the cylindrical fitter or overwrite the gameplay source. Pose
assets are editable Blender actions, seeded from the current approved hold.
"""
import bpy,json,re,os,sys,hashlib
from pathlib import Path
from mathutils import Quaternion,Vector
ROOT=Path(__file__).resolve().parent.parent
sys.path.insert(0,str(ROOT/'tools'))
from scavenger_head import obj_data
OUT=ROOT/'assets/characters/hand_authoring'
SOURCE=OUT/'source'
if (SOURCE/'hand_authoring.blend').exists() and '--rebuild-authoring' not in sys.argv:
    raise RuntimeError('Authoring source already exists. Use export_authored_hand.py to preserve edits; --rebuild-authoring explicitly recreates the source.')
UP=ROOT/'assets/characters/scavenger/source/makehuman'
SOURCE.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'assets/characters/mannequin_player/source/mannequin_player.blend'))
rig=bpy.data.objects['MannequinRig'];body=bpy.data.objects['MaleMannequinBody']
for track in rig.animation_data.nla_tracks:track.mute=True
rig.animation_data.action=None
for bone in rig.pose.bones:bone.rotation_mode='QUATERNION';bone.rotation_quaternion=Quaternion();bone.location=(0,0,0)
_,_,faces=obj_data(str(UP/'base.obj'))
ids=sorted({i for points,_,group in faces if group=='body' for i in points})
assert len(ids)==len(body.data.vertices),'Source topology differs; cannot transfer indexed weights'
weights_path=SOURCE/'default_weights.mhw'
weights=json.loads(weights_path.read_text())
assert weights['license']=='CC0'
source_map={old:new for new,old in enumerate(ids)}
vertex_weights={}
mapping={'wrist.R':'hand.R','lowerarm01.R':'forearm.R','lowerarm02.R':'forearm_twist.R'}
for i,finger in enumerate(['thumb','index','middle','ring','pinky'],1):
    for j in range(1,4):mapping[f'finger{i}-{j}.R']=f'{finger}{j}.R'
for i in range(1,5):mapping[f'metacarpal{i}.R']='hand.R'
for name,target in mapping.items():
    for original,weight in weights['weights'].get(name,[]):
        if original not in source_map:continue
        index=source_map[original]
        values=vertex_weights.setdefault(index,{})
        values[target]=values.get(target,0)+weight
wrist=rig.data.bones['hand.R'].head_local
changed=0
for index,values in vertex_weights.items():
    if '--transfer-source-weights' not in sys.argv:continue
    vertex=body.data.vertices[index]
    if (vertex.co-wrist).length>.225:continue
    # Keep the existing forearm transition; replace the hand and its webbing.
    hand_weight=sum(w for n,w in values.items() if n not in ['forearm.R','forearm_twist.R'])
    if hand_weight<.02:continue
    total=sum(values.values())
    for group in list(vertex.groups):body.vertex_groups[group.group].remove([index])
    for name,weight in values.items():
        if weight>0.00001:body.vertex_groups[name].add([index],weight/total,'REPLACE')
    changed+=1
if '--transfer-source-weights' in sys.argv:assert changed>300,'Unexpected source weight transfer coverage'

poses={}
for item in ['flashlight','food_tin']:
    text=(ROOT/f'assets/grips/{item}.tres').read_text()
    poses[item]={}
    for name,values in re.findall(r'"([a-z]+[123]\.R)": Quaternion\(([^)]+)\)',text):
        x,y,z,w=map(float,values.split(','));poses[item][name]=Quaternion((w,x,y,z))
poses['open']={n:Quaternion() for n in poses['flashlight']}
for item,pose in poses.items():
    rig.animation_data.action=None
    for name,q in pose.items():
        p=rig.pose.bones[name];p.rotation_quaternion=q
        for frame in [1,2]:p.keyframe_insert('rotation_quaternion',frame=frame,group=name)
    action=rig.animation_data.action;action.name='Hand_'+item
    action.asset_mark()
    action.asset_data.description='Editable right-hand pose. Only finger tracks; preserve the full-body rig.'
    track=rig.animation_data.nla_tracks.new();track.name=action.name
    strip=track.strips.new(action.name,1,action);strip.action_frame_start=1;strip.action_frame_end=2
    track.mute=True
rig.animation_data.action=None
for bone in rig.pose.bones:bone.rotation_quaternion=Quaternion();bone.location=(0,0,0)
rig.hide_set(False);rig.show_in_front=True
# The old skinned reference item is not part of the new authoring/export asset.
torch=bpy.data.objects.get('Flashlight')
if torch:torch.hide_set(True);torch.hide_render=True
body['hand_weights_source']='Experimental source transfer' if changed else 'Existing game weights preserved; source transfer experiment not promoted'
body['hand_pose_source']='Blender action assets; no grip optimizer run'
bpy.ops.object.select_all(action='DESELECT');rig.select_set(True)
bpy.context.view_layer.objects.active=rig
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE/'hand_authoring.blend'))

bpy.ops.object.select_all(action='DESELECT')
for ob in bpy.context.scene.objects:
    if ob==rig or ob==body or ob.name.startswith('MannequinEye'):ob.select_set(True)
bpy.context.view_layer.objects.active=body
for modifier in list(body.modifiers):
    if modifier.type=='SUBSURF':
        modifier.levels=1;bpy.ops.object.modifier_apply(modifier=modifier.name)
for vertex in body.data.vertices:
    keep=sorted([(g.group,g.weight) for g in vertex.groups],key=lambda pair:pair[1],reverse=True)[:4]
    allowed={i for i,_ in keep};total=sum(w for _,w in keep)
    for group in list(vertex.groups):
        if group.group not in allowed:body.vertex_groups[group.group].remove([vertex.index])
    for group,weight in keep:body.vertex_groups[group].add([vertex.index],weight/total,'REPLACE')
for track in rig.animation_data.nla_tracks:track.mute=False
bpy.ops.export_scene.gltf(filepath=str(OUT/'hand_authoring.glb'),export_format='GLB',use_selection=True,export_animations=True,export_animation_mode='NLA_TRACKS',export_nla_strips=True,export_skins=True)
report={'transferred_vertices':changed,'source_license':weights['license'],'source_sha256':hashlib.sha256(weights_path.read_bytes()).hexdigest(),'pose_assets':list(poses),'bones':len(rig.data.bones)}
(OUT/'authoring_report.json').write_text(json.dumps(report,indent=2))
print('HAND_AUTHORING',json.dumps(report))
