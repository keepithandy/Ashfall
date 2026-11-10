"""Set up the editable pose workspace once; keep these helpers out of export."""
import bpy,re,math
from pathlib import Path
from mathutils import Matrix,Euler
ROOT=Path(__file__).resolve().parent.parent
source=ROOT/'assets/characters/hand_authoring/source/hand_authoring.blend'
bpy.ops.wm.open_mainfile(filepath=str(source))
if bpy.context.object and bpy.context.object.mode!='OBJECT':bpy.ops.object.mode_set(mode='OBJECT')
rig=bpy.data.objects['MannequinRig']
for track in rig.animation_data.nla_tracks:track.mute=True
rig.animation_data.action=bpy.data.actions['Hand_flashlight']
bpy.context.scene.frame_set(1)
text=(ROOT/'assets/grips/flashlight.tres').read_text()
values=list(map(float,re.search(r'attachment_transform = Transform3D\(([^)]+)',text).group(1).split(',')))
attachment=Matrix((values[0:3]+[0],values[3:6]+[0],values[6:9]+[0],[0,0,0,1]))
attachment.translation=values[9:12]
C=Matrix(((1,0,0,0),(0,0,1,0),(0,-1,0,0),(0,0,0,1)))
world=rig.data.bones['hand.R'].matrix_local@attachment@C
old=set(bpy.data.objects)
bpy.ops.import_scene.gltf(filepath=str(ROOT/'assets/items/handheld_flashlight.glb'))
new=set(bpy.data.objects)-old
holder=bpy.data.objects.new('PREVIEW_ONLY_HeldFlashlight',None)
bpy.context.scene.collection.objects.link(holder)
for ob in new:
    if ob.parent is None:ob.parent=holder
holder.matrix_world=world
constraint=holder.constraints.new('CHILD_OF')
constraint.target=rig;constraint.subtarget='hand.R'
constraint.inverse_matrix=rig.data.bones['hand.R'].matrix_local.inverted()
rig.hide_set(False);rig.show_in_front=False
for bone in rig.data.bones:
    bone.hide=not (bone.name.endswith('.R') and bone.name.startswith(('hand','thumb','index','middle','ring','pinky')))
bpy.ops.object.select_all(action='DESELECT');rig.select_set(True)
bpy.context.view_layer.objects.active=rig
bpy.ops.object.mode_set(mode='POSE')
for window in bpy.context.window_manager.windows:
    for area in window.screen.areas:
        if area.type=='VIEW_3D':
            area.spaces.active.region_3d.view_location=world.translation
            area.spaces.active.region_3d.view_distance=.45
            area.spaces.active.region_3d.view_rotation=Euler((math.radians(65),0,math.radians(125))).to_quaternion()
        if area.type=='DOPESHEET_EDITOR':
            area.spaces.active.mode='ACTION'
bpy.ops.wm.save_as_mainfile(filepath=str(source))
print('HAND_WORKSPACE_READY',source)
