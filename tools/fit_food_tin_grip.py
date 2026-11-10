"""Fit the second item on the verified anatomical palm, keeping it upright."""
import bpy,json,re,sys
from pathlib import Path
from mathutils import Matrix,Vector,Quaternion
ROOT=Path(__file__).resolve().parent.parent
sys.path.insert(0,str(ROOT/'tools'))
from hand_grip_fitter import fit_grip
from build_hand_grips import vector,bvector,ttext,vtext,qtext,C
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'assets/characters/hand_authoring/source/hand_authoring.blend'))
if bpy.context.object and bpy.context.object.mode!='OBJECT':bpy.ops.object.mode_set(mode='OBJECT')
rig=bpy.data.objects['MannequinRig'];body=bpy.data.objects['MaleMannequinBody']
rig.animation_data.action=None
for track in rig.animation_data.nla_tracks:track.mute=True
for p in rig.pose.bones:p.rotation_quaternion=Quaternion();p.location=(0,0,0)
profile=json.loads((ROOT/'assets/characters/mannequin_player/player_profile.json').read_text(encoding='utf-8-sig'))
normal=bvector(profile['anatomical_palm_normal']).normalized()
text=(ROOT/'assets/grips/flashlight.tres').read_text(encoding='utf-8-sig')
def field(name):return bvector(list(map(float,re.search(name+r' = Vector3\(([^)]+)',text).group(1).split(','))))
forward=field('aim_forward').normalized();up=field('aim_up').normalized()
wrist=rig.data.bones['hand.R'].head_local
knuckles=sum((rig.data.bones[n+'1.R'].head_local for n in ['index','middle','ring','pinky']),Vector())/4
distal=(knuckles-wrist).normalized()
axis=forward;back=-up
world=Matrix((axis.cross(back),axis,back)).transposed().to_4x4()
world.translation=knuckles-distal*.025+normal*.058+forward*.005
poses,targets,report=fit_grip(rig,world,.046,.059,normal,body=body,fingers=['index','middle','ring','pinky'])
tp,tt,tr=fit_grip(rig,world,.046,.059,-normal,body=body,fingers=['thumb'])
poses.update(tp);targets.update(tt);report.update(tr)
out='[gd_resource type="Resource" script_class="HandGripProfile" load_steps=3 format=3]\n'
out+='[ext_resource type="Script" path="res://scripts/runtime/hand_grip_profile.gd" id="1"]\n[ext_resource type="PackedScene" path="res://scenes/items/held_food_tin.tscn" id="2"]\n[resource]\nscript = ExtResource("1")\nitem_id = &"food_tin"\ndisplay_name = "Food tin"\nmodel_scene = ExtResource("2")\n'
out+='attachment_transform = '+ttext(rig.data.bones['hand.R'].matrix_local.inverted()@world@C.inverted())+'\n'
out+='finger_rotations = {\n'+',\n'.join('"'+n+'": '+qtext(q) for n,q in poses.items())+'\n}\n'
out+='contact_targets = {\n'+',\n'.join('"'+n+'": '+vtext(vector(v)) for n,v in targets.items())+'\n}\n'
out+='aim_forward = '+vtext(vector(-up))+'\naim_up = '+vtext(vector(forward))+'\nhand_offset = Vector3(0.17,-0.1,-0.39)\nelbow_offset = Vector3(0.46,-0.08,0.1)\n'
(ROOT/'assets/grips/food_tin_inward.tres').write_text(out)
(ROOT/'.godot/food-tin-fit.json').write_text(json.dumps(report,indent=2))
print(json.dumps(report))
