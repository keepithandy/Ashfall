"""Isolated opposite-palm grip diagnostic; does not overwrite the player."""
import bpy,sys,json
from pathlib import Path
from mathutils import Vector,Matrix,Quaternion
ROOT=Path(__file__).resolve().parent.parent
sys.path.insert(0,str(ROOT/'tools'))
from hand_grip_fitter import fit_grip
from build_hand_grips import ttext,vtext,qtext,vector,C
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'assets/characters/mannequin_player/source/mannequin_player.blend'))
rig=bpy.data.objects['MannequinRig'];body=bpy.data.objects['MaleMannequinBody']
for track in rig.animation_data.nla_tracks:track.mute=True
rig.animation_data.action=None
for p in rig.pose.bones:p.rotation_quaternion=Quaternion();p.location=(0,0,0)
wrist=rig.data.bones['hand.R'].head_local
k=[rig.data.bones[n+'1.R'].head_local for n in ['index','middle','ring','pinky']]
distal=(sum(k,Vector())/4-wrist).normalized();across=(k[0]-k[3]).normalized()
normal=across.cross(distal).normalized()
if normal.y>0:normal=-normal
normal=-normal
forward=(across*.95+distal*.30).normalized()
center=sum(k,Vector())/4-distal*.025+normal*.039+forward*.040
thumb=rig.data.bones['thumb1.R'].head_local-center
up=(thumb-forward*thumb.dot(forward)).normalized()
world=Matrix((forward.cross(up),forward,up)).transposed().to_4x4();world.translation=center
pose,targets,report=fit_grip(rig,world,.029*.84,.075*.84,normal,body=body,fingers=['index','middle','ring','pinky'])
# Thumb opposition has the opposite hinge direction from the four fingers.
tp,tt,tr=fit_grip(rig,world,.029*.84,.075*.84,-normal,body=body,fingers=['thumb'],target_overrides={'thumb':(0,.047,.0298)})
pose.update(tp);targets.update(tt);report.update(tr)
text='[gd_resource type="Resource" script_class="HandGripProfile" load_steps=3 format=3]\n'
text+='[ext_resource type="Script" path="res://scripts/runtime/hand_grip_profile.gd" id="1"]\n[ext_resource type="PackedScene" path="res://scenes/items/handheld_flashlight.tscn" id="2"]\n[resource]\nscript = ExtResource("1")\nitem_id = &"flashlight"\ndisplay_name = "Inward grip diagnostic"\nmodel_scene = ExtResource("2")\n'
text+='attachment_transform = '+ttext(rig.data.bones['hand.R'].matrix_local.inverted()@world@C.inverted())+'\n'
text+='pose_animation = &"Hand_flashlight"\n'
text+='finger_rotations = {\n'+',\n'.join('"'+n+'": '+qtext(q) for n,q in pose.items())+'\n}\n'
text+='contact_targets = {\n'+',\n'.join('"'+n+'": '+vtext(vector(v)) for n,v in targets.items())+'\n}\n'
text+='aim_forward = '+vtext(vector(forward))+'\naim_up = '+vtext(vector(up))+'\nhand_offset = Vector3(0.17,-0.1,-0.39)\nelbow_offset = Vector3(0.46,-0.08,0.1)\nemits_light = true\nbeam_transform = Transform3D(1,0,0,0,1,0,0,0,1,0,0,-0.1302)\n'
(ROOT/'assets/grips/flashlight_inward.tres').write_text(text)
(ROOT/'.godot/inward-anatomy.json').write_text(json.dumps({'palm_normal':vector(normal),'fit':report},indent=2))
print(json.dumps(report))
