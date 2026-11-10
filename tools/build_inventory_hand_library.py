"""Create additional editable pose assets in a separate Blender source."""
import bpy,sys,re,runpy
from pathlib import Path
from mathutils import Quaternion
ROOT=Path(__file__).resolve().parent.parent
folder=ROOT/'assets/characters/inventory_hands'
folder.mkdir(parents=True,exist_ok=True)
source=folder/'source/inventory_hand_poses.blend'
if source.exists() and '--rebuild' not in sys.argv:
    raise RuntimeError('Pose source exists. Export saved edits instead of rebuilding it.')
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'assets/characters/hand_authoring/source/hand_authoring.blend'))
if bpy.context.object and bpy.context.object.mode!='OBJECT':bpy.ops.object.mode_set(mode='OBJECT')
rig=bpy.data.objects['MannequinRig']
for track in rig.animation_data.nla_tracks:track.mute=True
rig.animation_data.action=None
for p in rig.pose.bones:p.rotation_quaternion=Quaternion();p.location=(0,0,0)
for item in ['bandage','batteries','water_bottle','antiseptic','detector','field_radio']:
    rig.animation_data.action=None
    text=(ROOT/f'assets/grips/{item}.tres').read_text(encoding='utf-8-sig')
    count=0
    for name,values in re.findall(r'"([a-z]+[123]\.R)": Quaternion\(([^)]+)\)',text):
        x,y,z,w=map(float,values.split(','));p=rig.pose.bones[name];p.rotation_quaternion=Quaternion((w,x,y,z))
        for frame in [1,2]:p.keyframe_insert('rotation_quaternion',frame=frame,group=name)
        count+=1
    assert count==15
    action=rig.animation_data.action;action.name='Hand_'+item
    action.asset_mark();action.asset_data.description='Editable held-item pose for '+item
    track=rig.animation_data.nla_tracks.new();track.name=action.name
    strip=track.strips.new(action.name,1,action);strip.action_frame_start=1;strip.action_frame_end=2;track.mute=True
rig.animation_data.action=None
for p in rig.pose.bones:p.rotation_quaternion=Quaternion();p.location=(0,0,0)
bpy.ops.wm.save_as_mainfile(filepath=str(source))
sys.argv=['export_authored_hand.py','--source',str(source),'--output',str(folder/'inventory_hand_poses.glb')]
runpy.run_path(str(ROOT/'tools/export_authored_hand.py'),run_name='__main__')
