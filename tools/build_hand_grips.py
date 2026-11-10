"""Separate held props from the player and author reusable Godot grip resources."""
import bpy
import os
import sys
import json
from mathutils import Vector, Matrix, Quaternion

HERE=os.path.dirname(os.path.abspath(__file__))
ROOT=os.path.dirname(HERE)
sys.path.insert(0,HERE)
from hand_grip_fitter import fit_grip, cylinder_distance
BASE=os.path.join(ROOT,'assets','characters','mannequin_player')
ITEMS=os.path.join(ROOT,'assets','items')
GRIPS=os.path.join(ROOT,'assets','grips')
C=Matrix(((1,0,0,0),(0,0,1,0),(0,-1,0,0),(0,0,0,1)))

def vector(v):return [v.x,v.z,-v.y]
def bvector(v):return Vector((v[0],-v[2],v[1]))
def num(value):return f'{float(value):.9g}'
def vtext(v):return 'Vector3('+', '.join(num(x) for x in v)+')'
def qtext(q):return 'Quaternion('+', '.join(num(x) for x in [q.x,q.y,q.z,q.w])+')'
def ttext(m):
    # Godot text Transform3D literals serialize basis rows, not column vectors.
    values=[m[row][column] for row in range(3) for column in range(3)]+list(m.translation)
    return 'Transform3D('+', '.join(num(x) for x in values)+')'

def build():
    if os.path.exists(os.path.join(ROOT,'assets','characters','hand_authoring','source','hand_authoring.blend')) and '--legacy-rebuild' not in sys.argv:
        raise RuntimeError('Current hand poses are authored in Blender. Use export_authored_hand.py; --legacy-rebuild explicitly regenerates the old grip assets.')
    os.makedirs(ITEMS,exist_ok=True);os.makedirs(GRIPS,exist_ok=True)
    bpy.ops.wm.open_mainfile(filepath=os.path.join(BASE,'source','mannequin_player.blend'))
    rig=bpy.data.objects['MannequinRig'];body=bpy.data.objects['MaleMannequinBody']
    rig.hide_set(False)
    for track in rig.animation_data.nla_tracks:track.mute=True
    rig.animation_data.action=None
    for p in rig.pose.bones:p.rotation_mode='QUATERNION';p.rotation_quaternion=Quaternion();p.location=(0,0,0)
    # A dedicated lower-forearm twist avoids collapsing the wrist when the
    # palm is turned around a held prop. Preserve all original bone rest poses.
    if 'forearm_twist.R' not in rig.data.bones:
        bpy.ops.object.select_all(action='DESELECT');rig.select_set(True)
        bpy.context.view_layer.objects.active=rig
        bpy.ops.object.mode_set(mode='EDIT')
        forearm=rig.data.edit_bones['forearm.R'];hand=rig.data.edit_bones['hand.R']
        twist=rig.data.edit_bones.new('forearm_twist.R')
        twist.head=forearm.head.lerp(forearm.tail,.45)
        twist.tail=forearm.tail.copy();twist.roll=forearm.roll
        twist.parent=forearm;hand.parent=twist
        bpy.ops.object.mode_set(mode='OBJECT')
    forearm=rig.data.bones['forearm.R'];wrist=rig.data.bones['hand.R'].head_local
    axis=(wrist-forearm.head_local).normalized();length=(wrist-forearm.head_local).length
    twist_group=body.vertex_groups.get('forearm_twist.R') or body.vertex_groups.new(name='forearm_twist.R')
    for vertex in body.data.vertices:
        offset=vertex.co-forearm.head_local
        t=offset.dot(axis)/length
        radial=(offset-axis*offset.dot(axis)).length
        if not (.12<t<1.035 and radial<.075):continue
        # The opposed thumb can sit alongside the wrist. Never repaint any
        # digit merely because it projects into the forearm's spatial tube.
        if any(body.vertex_groups[g.group].name.startswith(('thumb','index','middle','ring','pinky')) and g.weight>.10 for g in vertex.groups):
            continue
        influence=max(0,min(1,(t-.12)/.78));influence=influence*influence*(3-2*influence)
        palm=max(0,min(1,(t-.94)/.095))
        weights={'forearm.R':(1-influence)*(1-palm),'forearm_twist.R':influence*(1-palm),'hand.R':palm}
        for group in list(vertex.groups):body.vertex_groups[group.group].remove([vertex.index])
        for name,value in weights.items():
            if value>.00001:body.vertex_groups[name].add([vertex.index],value,'REPLACE')
    # The original nearest-finger weighting has hard seams around the thumb
    # web. Smooth through mesh neighbors (never across the air between digits)
    # once per source build so the palm stays continuous under opposition.
    if not body.get('grip_web_weights_v1',False):
        adjacency=[[] for _ in body.data.vertices]
        for edge in body.data.edges:
            a,b=edge.vertices;adjacency[a].append(b);adjacency[b].append(a)
        selected=[v.index for v in body.data.vertices if (v.co-wrist).length<.225]
        for _ in range(3):
            old=[{g.group:g.weight for g in v.groups} for v in body.data.vertices]
            for i in selected:
                neighbors=adjacency[i]
                if not neighbors:continue
                weights={g:w*.55 for g,w in old[i].items()}
                for other in neighbors:
                    for group,weight in old[other].items():
                        weights[group]=weights.get(group,0)+weight*.45/len(neighbors)
                strongest=sorted(weights.items(),key=lambda pair:pair[1],reverse=True)[:4]
                total=sum(w for _,w in strongest)
                for group in list(body.data.vertices[i].groups):body.vertex_groups[group.group].remove([i])
                for group,weight in strongest:
                    if weight>.00001:body.vertex_groups[group].add([i],weight/total,'REPLACE')
        body['grip_web_weights_v1']=True
    with open(os.path.join(BASE,'player_profile.json')) as f:avatar=json.load(f)
    reference_path=os.path.join(GRIPS,'authoring_reference.json')
    if 'item_center' in avatar:
        reference={n:avatar[n] for n in ['hand_forward','hand_up','item_center']}
        with open(reference_path,'w') as f:json.dump(reference,f,indent=2)
    else:
        with open(reference_path) as f:reference=json.load(f)
    forward=bvector(reference['hand_forward']).normalized()
    up=bvector(reference['hand_up']).normalized()
    center=bvector(reference['item_center'])
    right=forward.cross(up).normalized()
    item_world=Matrix((right,forward,up)).transposed().to_4x4();item_world.translation=center
    reference_item_world=item_world.copy()
    item_world.translation+=forward*.022
    wrist=rig.data.bones['hand.R'].head_local.copy()
    index=rig.data.bones['index1.R'].head_local
    pinky=rig.data.bones['pinky1.R'].head_local
    distal=(sum((rig.data.bones[n+'1.R'].head_local for n in ['index','middle','ring','pinky']),Vector())/4-wrist).normalized()
    across=(index-pinky).normalized();palm_normal=across.cross(distal).normalized()
    if palm_normal.y>0:palm_normal=-palm_normal
    # The previous normal selected the dorsal side: all four fingers curled
    # backwards. Keep the verified palmar side, with separate thumb opposition.
    palm_normal=-palm_normal

    # Forward utility grip from the selected MecArmy side-switch reference:
    # the shaft crosses the palm, thumb reaches forward, fingers curl below.
    utility_forward=(across*.95+distal*.30).normalized()
    knuckles=sum((rig.data.bones[n+'1.R'].head_local for n in ['index','middle','ring','pinky']),Vector())/4
    utility_center=knuckles-distal*.025+palm_normal*.039+utility_forward*.040
    thumb_side=rig.data.bones['thumb1.R'].head_local-utility_center
    utility_up=(thumb_side-utility_forward*thumb_side.dot(utility_forward)).normalized()
    utility_right=utility_forward.cross(utility_up).normalized()
    utility_world=Matrix((utility_right,utility_forward,utility_up)).transposed().to_4x4()
    utility_world.translation=utility_center

    # The item file has no skeleton or skin: it is an independent reusable prop.
    torch=bpy.data.objects.get('Flashlight')
    if torch is None:raise RuntimeError('The authoring source must retain its flashlight reference')
    static=torch.copy();static.data=torch.data.copy();static.name='FlashlightModel'
    static.parent=None;static.matrix_world=Matrix.Identity(4);static.vertex_groups.clear()
    for modifier in list(static.modifiers):static.modifiers.remove(modifier)
    for vertex in static.data.vertices:vertex.co=reference_item_world.inverted()@vertex.co
    # Put the side switch near the front of the grip, within an extended
    # thumb's reach as in the photo. Move its disconnected mesh island only.
    neighbors=[[] for _ in static.data.vertices]
    for edge in static.data.edges:
        a,b=edge.vertices;neighbors[a].append(b);neighbors[b].append(a)
    pending=set(range(len(static.data.vertices)));islands=[]
    while pending:
        island=[];stack=[pending.pop()]
        while stack:
            i=stack.pop();island.append(i)
            for other in neighbors[i]:
                if other in pending:pending.remove(other);stack.append(other)
        islands.append(island)
    source_switch=Vector((0,.015*.84,.029*.84))
    switch=min(islands,key=lambda ids:(sum((static.data.vertices[i].co for i in ids),Vector())/len(ids)-source_switch).length)
    for i in switch:static.data.vertices[i].co.y+=.047-.015*.84
    bpy.context.scene.collection.objects.link(static)
    bpy.ops.object.select_all(action='DESELECT');static.select_set(True)
    bpy.ops.export_scene.gltf(filepath=os.path.join(ITEMS,'handheld_flashlight.glb'),export_format='GLB',use_selection=True,export_animations=False)
    bpy.data.objects.remove(static,do_unlink=True)

    wrist_rest=rig.data.bones['hand.R'].matrix_local
    debug={n:[list(row) for row in rig.data.bones[n].matrix_local] for n in ['hand.R','index1.R','index3.R']}
    with open(os.path.join(ROOT,'.godot','grip-source-bone-rest.json'),'w') as f:json.dump(debug,f,indent=2)
    results={}
    # Fit and audit the same subdivision level as the exported game mesh.
    # This copy preserves the edit cage and its non-destructive modifiers.
    fit_body=body.copy();fit_body.data=body.data.copy()
    bpy.context.scene.collection.objects.link(fit_body)
    bpy.context.view_layer.objects.active=fit_body
    for modifier in list(fit_body.modifiers):
        if modifier.type!='SUBSURF':fit_body.modifiers.remove(modifier)
        else:
            modifier.levels=1
            bpy.ops.object.modifier_apply(modifier=modifier.name)
    # Match glTF's four normalized influences per vertex in the fitting mesh.
    for vertex in fit_body.data.vertices:
        strongest=sorted([(g.group,g.weight) for g in vertex.groups],key=lambda pair:pair[1],reverse=True)[:4]
        keep={group for group,_ in strongest};total=sum(weight for _,weight in strongest)
        for group in list(vertex.groups):
            if group.group not in keep:fit_body.vertex_groups[group.group].remove([vertex.index])
        for group,weight in strongest:fit_body.vertex_groups[group].add([vertex.index],weight/total,'REPLACE')
    definitions=[('flashlight',utility_world,.029*.84,.075*.84,'res://scenes/items/handheld_flashlight.tscn',True)]
    # Upright food tin, using the existing loot prop. Its canonical axis is +Y
    # in Blender / -Z in the item scene, then placed upright in the held pose.
    tin_axis=up
    tin_up=-forward
    tin_right=tin_axis.cross(tin_up).normalized()
    tin_world=Matrix((tin_right,tin_axis,tin_up)).transposed().to_4x4()
    tin_world.translation=center+palm_normal*.019
    definitions.append(('food_tin',tin_world,.046,.059,'res://scenes/items/held_food_tin.tscn',False))
    for item_id,world,radius,half_length,scene,emits in definitions:
        # Place the internal thumb-tip guide above the relocated switch pad.
        targets_override={'thumb':(0,.047,.0298)} if emits else {}
        poses,targets,report=fit_grip(rig,world,radius,half_length,palm_normal,body=fit_body,fingers=['index','middle','ring','pinky'])
        tp,tt,tr=fit_grip(rig,world,radius,half_length,-palm_normal,target_overrides=targets_override,body=fit_body,fingers=['thumb'])
        poses.update(tp);targets.update(tt);report.update(tr)
        # Audit the subdivided export skin as well as joint targets.
        for name,q in poses.items():rig.pose.bones[name].rotation_quaternion=q
        bpy.context.view_layer.update()
        deform={n:rig.pose.bones[n].matrix@rig.data.bones[n].matrix_local.inverted() for n in rig.data.bones.keys()}
        distances={n:[] for n in ['thumb','index','middle','ring','pinky']}
        palm_distances=[];switch_distances=[]
        inverse=world.inverted()
        for vertex in fit_body.data.vertices:
            strengths={n:sum(g.weight for g in vertex.groups if fit_body.vertex_groups[g.group].name.startswith(n) and fit_body.vertex_groups[g.group].name.endswith('.R')) for n in distances}
            finger=max(strengths,key=strengths.get)
            is_palm=any(fit_body.vertex_groups[g.group].name=='hand.R' and g.weight>.55 for g in vertex.groups)
            if strengths[finger]<.55 and not is_palm:continue
            point=sum((deform[fit_body.vertex_groups[g.group].name]@vertex.co*g.weight for g in vertex.groups),Vector())
            point=inverse@point
            distance=cylinder_distance(point,radius,half_length)
            if emits:distance=min(distance,cylinder_distance(point-Vector((0,.100,0)),.0395,.025))
            if is_palm:palm_distances.append(distance)
            else:distances[finger].append(distance)
            if emits and finger=='thumb' and strengths[finger]>.55:
                switch_distances.append((point-Vector((0,.047,.033*.84))).length)
        for finger,values in distances.items():
            report[finger]['skin_min_clearance_mm']=round(min(values)*1000,2) if values else None
        report['_surface_checks']={'palm_min_clearance_mm':round(min(palm_distances)*1000,2)}
        if emits:
            report['_surface_checks']['thumb_to_switch_mm']=round(min(switch_distances)*1000,2)
            assert min(palm_distances)>-.001,'Flashlight penetrates the palm'
            assert min(switch_distances)<.004,'Thumb pad does not reach the side switch'
        for pose in rig.pose.bones:pose.rotation_quaternion=Quaternion()
        attachment=wrist_rest.inverted()@world@C.inverted()
        rotations='{\n'+',\n'.join('"'+n+'": '+qtext(q) for n,q in poses.items())+'\n}'
        contacts='{\n'+',\n'.join('"'+n+'": '+vtext(vector(p)) for n,p in targets.items())+'\n}'
        text='[gd_resource type="Resource" script_class="HandGripProfile" load_steps=3 format=3]\n\n'
        text+='[ext_resource type="Script" path="res://scripts/runtime/hand_grip_profile.gd" id="1"]\n'
        text+='[ext_resource type="PackedScene" path="'+scene+'" id="2"]\n\n[resource]\nscript = ExtResource("1")\n'
        text+='item_id = &"'+item_id+'"\ndisplay_name = "'+('Flashlight' if emits else 'Food tin')+'"\nmodel_scene = ExtResource("2")\n'
        text+='pose_animation = &"Hand_'+item_id+'"\n'
        text+='attachment_transform = '+ttext(attachment)+'\n'
        text+='finger_rotations = '+rotations+'\ncontact_targets = '+contacts+'\n'
        text+='aim_forward = '+vtext(vector(world.col[1].xyz))+'\naim_up = '+vtext(vector(world.col[2].xyz))+'\n'
        if emits:
            text+='hand_offset = Vector3(0.17, -0.10, -0.39)\n'
            text+='elbow_offset = Vector3(0.46, -0.08, 0.10)\n'
            text+='emits_light = true\nbeam_transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, '+num(-.155*.84)+')\n'
        with open(os.path.join(GRIPS,item_id+'.tres'),'w') as f:f.write(text)
        results[item_id]=report
        print('GRIP_FIT',item_id,json.dumps(report),flush=True)
    with open(os.path.join(GRIPS,'fit_report.json'),'w') as f:json.dump(results,f,indent=2)
    bpy.data.objects.remove(fit_body,do_unlink=True)
    group_counts={name:sum(1 for vertex in body.data.vertices if any(body.vertex_groups[g.group].name==name and g.weight>.5 for g in vertex.groups)) for name in ['thumb1.R','thumb2.R','thumb3.R','index3.R','pinky3.R']}
    print('HAND_DEFORM_GROUPS',json.dumps(group_counts))
    assert group_counts['thumb3.R']>3,'Forearm painting removed the thumb skin weights'
    avatar['rig_id']='mannequin_humanoid_v1'
    avatar['anatomical_palm_normal']=vector(palm_normal)
    avatar['fingertip_lengths']={n:rig.data.bones[n+'3.R'].length for n in ['thumb','index','middle','ring','pinky']}
    for old in ['grip_rotations','beam_position','beam_forward','beam_up','item_center','hand_forward','hand_up']:
        avatar.pop(old,None)
    with open(os.path.join(BASE,'player_profile.json'),'w') as f:json.dump(avatar,f,indent=2)
    # Preserve the authoring reference but exclude every prop from the body GLB.
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(BASE,'source','mannequin_player.blend'))
    bpy.ops.object.select_all(action='DESELECT')
    for ob in bpy.context.scene.objects:
        if ob==rig or ob.name=='MaleMannequinBody' or ob.name.startswith('MannequinEye'):
            ob.select_set(True)
    bpy.context.view_layer.objects.active=body
    for modifier in list(body.modifiers):
        if modifier.type=='SUBSURF':
            modifier.levels=1;bpy.ops.object.modifier_apply(modifier=modifier.name)
    for track in rig.animation_data.nla_tracks:track.mute=False
    bpy.ops.export_scene.gltf(filepath=os.path.join(BASE,'mannequin_player.glb'),export_format='GLB',use_selection=True,export_animations=True,export_animation_mode='NLA_TRACKS',export_nla_strips=True,export_skins=True)
    print('HAND_GRIP_ASSETS_EXPORTED: independent flashlight, two grip resources, prop-free player')

if __name__=='__main__':build()
