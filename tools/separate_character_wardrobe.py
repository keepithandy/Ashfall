"""Separate existing dressed parts into reusable, independently editable assets.

The saved dressed source is read, never overwritten. Each part retains its
original skeleton, materials and fitting; anatomy refitting is a later step.
"""
import bpy
import os
import json

ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SOURCE=os.path.join(ROOT,'assets','characters','scavenger','source','ashfall_scavenger.blend')
OUT=os.path.join(ROOT,'assets','characters','wardrobe')
os.makedirs(os.path.join(OUT,'source'),exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=SOURCE)
rig=bpy.data.objects['ScavengerRig']
items={
    'field_jacket':'Jacket','collar_and_underlayer':'Neckwear',
    'cargo_trousers':'Trousers','boots':'Boots','gloves':'Gloves',
    'belt_and_strap':'Equipment','shoulder_bag':'Satchel','flashlight':'Flashlight'
}
for filename,name in items.items():
    obj=bpy.data.objects[name]
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True);rig.select_set(True)
    bpy.context.view_layer.objects.active=rig
    asset_scene=bpy.data.scenes.new(filename)
    asset_scene.collection.objects.link(rig)
    asset_scene.collection.objects.link(obj)
    bpy.data.libraries.write(os.path.join(OUT,'source',filename+'.blend'),{asset_scene},path_remap='RELATIVE',fake_user=True,compress=True)
    bpy.data.scenes.remove(asset_scene)
    bpy.ops.export_scene.gltf(filepath=os.path.join(OUT,filename+'.glb'),export_format='GLB',use_selection=True,export_animations=False,export_skins=True,export_yup=True)
    scene_dir=os.path.join(ROOT,'scenes','characters','wardrobe')
    os.makedirs(scene_dir,exist_ok=True)
    scene_text='[gd_scene load_steps=2 format=3]\n\n[ext_resource type="PackedScene" path="res://assets/characters/wardrobe/'+filename+'.glb" id="1"]\n\n[node name="'+name+'Asset" type="Node3D"]\n\n[node name="'+name+'" parent="." instance=ExtResource("1")]\n'
    with open(os.path.join(scene_dir,filename+'.tscn'),'w') as handle:handle.write(scene_text)
with open(os.path.join(OUT,'manifest.json'),'w') as f:
    json.dump({'parts':items,'fitting':'Original dressed rig. Not yet refitted to the separate mannequin.','source_preserved':True},f,indent=2)
print('WARDROBE_SEPARATED',len(items))
