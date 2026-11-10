"""Export saved Blender edits without rebuilding weights, rig, or poses.

Run in a separate Blender background process. Never overwrites the .blend.
"""
import bpy,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parent.parent
OUT=ROOT/'assets/characters/hand_authoring'
source=OUT/'source/hand_authoring.blend'
if '--source' in sys.argv:source=Path(sys.argv[sys.argv.index('--source')+1]).resolve()
output=OUT/'hand_authoring.glb'
if '--output' in sys.argv:output=Path(sys.argv[sys.argv.index('--output')+1]).resolve()
bpy.ops.wm.open_mainfile(filepath=str(source))
if bpy.context.object and bpy.context.object.mode!='OBJECT':bpy.ops.object.mode_set(mode='OBJECT')
rig=bpy.data.objects['MannequinRig'];body=bpy.data.objects['MaleMannequinBody']
rig.animation_data.action=None
for track in rig.animation_data.nla_tracks:track.mute=True
for pose in rig.pose.bones:
    pose.rotation_mode='QUATERNION';pose.rotation_quaternion=(1,0,0,0);pose.location=(0,0,0)
bpy.context.view_layer.update()
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
bpy.ops.export_scene.gltf(filepath=str(output),export_format='GLB',use_selection=True,export_animations=True,export_animation_mode='NLA_TRACKS',export_nla_strips=True,export_skins=True)
print('AUTHORED_HAND_EXPORTED_FROM_SAVED_SOURCE',source)
