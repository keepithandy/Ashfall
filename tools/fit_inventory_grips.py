"""Author initial item-specific grips on the verified palmar side.

Only new inventory profiles are written. Approved flashlight/tin poses stay intact.
"""
import bpy,json,re,sys
from pathlib import Path
from mathutils import Matrix,Vector,Quaternion
ROOT=Path(__file__).resolve().parent.parent
sys.path.insert(0,str(ROOT/'tools'))
from hand_grip_fitter import fit_grip
from build_hand_grips import bvector,vector,ttext,vtext,qtext,C
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'assets/characters/hand_authoring/source/hand_authoring.blend'))
if bpy.context.object and bpy.context.object.mode!='OBJECT':bpy.ops.object.mode_set(mode='OBJECT')
rig=bpy.data.objects['MannequinRig'];body=bpy.data.objects['MaleMannequinBody']
rig.animation_data.action=None
for track in rig.animation_data.nla_tracks:track.mute=True
for p in rig.pose.bones:p.rotation_quaternion=Quaternion();p.location=(0,0,0)
metadata=json.loads((ROOT/'assets/characters/mannequin_player/player_profile.json').read_text(encoding='utf-8-sig'))
normal=bvector(metadata['anatomical_palm_normal']).normalized()
flash=(ROOT/'assets/grips/flashlight.tres').read_text(encoding='utf-8-sig')
def field(name):return bvector(list(map(float,re.search(name+r' = Vector3\(([^)]+)',flash).group(1).split(','))))
forward=field('aim_forward').normalized();up=field('aim_up').normalized()
wrist=rig.data.bones['hand.R'].head_local
knuckles=sum((rig.data.bones[n+'1.R'].head_local for n in ['index','middle','ring','pinky']),Vector())/4
distal=(knuckles-wrist).normalized()
definitions=[('bandage','Cotton bandage',.045,.067),('batteries','Spare batteries',.039,.043),('water_bottle','Water flask',.032,.086),('antiseptic','Antiseptic bottle',.024,.060),('detector','Anomaly meter',.033,.074),('field_radio','Field receiver',.036,.065)]
report_path=ROOT/'assets/grips/inventory_fit_report.json'
report=json.loads(report_path.read_text()) if report_path.exists() else {}
for item_id,name,radius,half in definitions:
    if '--item' in sys.argv and item_id!=sys.argv[sys.argv.index('--item')+1]:continue
    world=Matrix((forward.cross(-up),forward,-up)).transposed().to_4x4()
    world.translation=knuckles-distal*.025+normal*(radius+.014)+forward*.005
    if item_id=='batteries':world.translation+=forward*.009
    pose,targets,fit=fit_grip(rig,world,radius,half,normal,body=body,fingers=['index','middle','ring','pinky'])
    tp,tt,tr=fit_grip(rig,world,radius,half,-normal,body=body,fingers=['thumb'])
    pose.update(tp);targets.update(tt);fit.update(tr)
    out='[gd_resource type="Resource" script_class="HandGripProfile" load_steps=3 format=3]\n'
    out+='[ext_resource type="Script" path="res://scripts/runtime/hand_grip_profile.gd" id="1"]\n[ext_resource type="PackedScene" path="res://scenes/items/held_'+item_id+'.tscn" id="2"]\n[resource]\nscript = ExtResource("1")\nitem_id = &"'+item_id+'"\ndisplay_name = "'+name+'"\npose_animation = &"Hand_'+item_id+'"\nmodel_scene = ExtResource("2")\n'
    out+='attachment_transform = '+ttext(rig.data.bones['hand.R'].matrix_local.inverted()@world@C.inverted())+'\n'
    out+='finger_rotations = {\n'+',\n'.join('"'+n+'": '+qtext(q) for n,q in pose.items())+'\n}\n'
    out+='contact_targets = {\n'+',\n'.join('"'+n+'": '+vtext(vector(v)) for n,v in targets.items())+'\n}\n'
    out+='aim_forward = '+vtext(vector(-up))+'\naim_up = '+vtext(vector(forward))+'\nhand_offset = Vector3(0.17,-0.1,-0.39)\nelbow_offset = Vector3(0.46,-0.08,0.1)\n'
    (ROOT/f'assets/grips/{item_id}.tres').write_text(out)
    report[item_id]=fit
    print('NEW_ITEM_GRIP',item_id,{n:v['target_error_mm'] for n,v in fit.items()},flush=True)
(ROOT/'assets/grips/inventory_fit_report.json').write_text(json.dumps(report,indent=2))
