"""Adapt MakeHuman CC0 facial topology, UVs, adult morph, hair and eyes.

Only graphical data is used. No MakeHuman application/add-on code is imported.
"""
import os
import math
import bpy
import bmesh
from mathutils import Vector
from mathutils.bvhtree import BVHTree


def obj_data(path):
    vertices, uvs, faces = [], [], []
    group = 'default'
    with open(path, encoding='utf-8') as handle:
        for line in handle:
            a = line.split()
            if not a:
                continue
            if a[0] == 'v':
                vertices.append(Vector(tuple(map(float, a[1:4]))))
            elif a[0] == 'vt':
                uvs.append(tuple(map(float, a[1:3])))
            elif a[0] == 'g':
                group = a[1]
            elif a[0] == 'f':
                refs = [token.split('/') for token in a[1:]]
                faces.append(([int(r[0])-1 for r in refs], [int(r[1])-1 if len(r)>1 and r[1] else 0 for r in refs], group))
    return vertices, uvs, faces


def build_head(source, finish, cord):
    base_dir = os.path.join(source, 'makehuman')
    vertices, uvs, faces = obj_data(os.path.join(base_dir, 'base.obj'))
    deltas = [Vector((0,0,0)) for _ in vertices]
    with open(os.path.join(base_dir, 'adult-male.target')) as handle:
        for line in handle:
            a = line.split()
            if len(a)==4 and not line.startswith('#'):
                deltas[int(a[0])] = Vector(tuple(map(float,a[1:])))
    deformed = [v+d for v,d in zip(vertices,deltas)]
    eye_groups = {}
    for side, name in [('R','joint-l-eye'),('L','joint-r-eye')]:
        ids = {i for ids, _, group in faces if group==name for i in ids}
        eye_groups[side] = sum((deformed[i] for i in ids),Vector())/len(ids)
    body_ids = {i for ids, _, group in faces if group=='body' for i in ids}
    max_y = max(deformed[i].y for i in body_ids)
    eye_y = (eye_groups['R'].y+eye_groups['L'].y)*.5
    scale = .106 / (max_y-eye_y)
    offset = 1.704-scale*eye_y
    depth_offset = -.035

    def convert(v):
        return Vector((v.x*scale,v.z*scale+depth_offset,v.y*scale+offset))

    def texture_material(name, path, rough=.7, alpha=False):
        material=bpy.data.materials.new(name);material.use_nodes=True
        p=material.node_tree.nodes.get('Principled BSDF')
        p.inputs['Roughness'].default_value=rough
        p.inputs['Base Color'].default_value=(.4,.26,.18,1)
        if os.path.isfile(path):
            im=bpy.data.images.load(path,check_existing=True)
            tex=material.node_tree.nodes.new('ShaderNodeTexImage');tex.image=im
            material.node_tree.links.new(tex.outputs['Color'],p.inputs['Base Color'])
            if alpha:
                material.node_tree.links.new(tex.outputs['Alpha'],p.inputs['Alpha'])
                material.surface_render_method='DITHERED'
                material.use_backface_culling=False
        return material

    skin_path=os.path.join(base_dir,'skins','middleage_caucasian_male','middleage_lightskinned_male_diffuse.png')
    assert os.path.isfile(skin_path), 'Download the CC0 anatomical skin texture before building'
    skin=texture_material('MakeHuman_adult_skin_CC0',skin_path,.68)
    selected=[face for face in faces if face[2]=='body' and min(convert(deformed[i]).z for i in face[0])>1.44 and max(abs(convert(deformed[i]).x) for i in face[0])<.10]

    def mesh_from_faces(name, coords, texcoords, selected_faces, mat, group, weights):
        used=sorted({i for ids,_,_ in selected_faces for i in ids})
        mapping={old:new for new,old in enumerate(used)}
        me=bpy.data.meshes.new(name)
        me.from_pydata([convert(coords[i]) for i in used],[],[tuple(mapping[i] for i in ids) for ids,_,_ in selected_faces]);me.update()
        uv=me.uv_layers.new(name='UVMap')
        for poly,(_,ui,_) in zip(me.polygons,selected_faces):
            for li,ti in zip(poly.loop_indices,ui):
                uv.data[li].uv=texcoords[ti] if texcoords else (0,0)
        ob=bpy.data.objects.new(name,me);bpy.context.collection.objects.link(ob)
        finish(ob,mat,group,weights)
        return ob

    head=mesh_from_faces('Anatomical adult head',deformed,uvs,selected,skin,'Head',['neck','head'])
    # Trim a level neckline under the shirt; avoid a sawtooth cut across face loops.
    bm=bmesh.new();bm.from_mesh(head.data)
    bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),dist=.00001,plane_co=(0,0,1.48),plane_no=(0,0,1),clear_inner=True,clear_outer=False)
    bm.to_mesh(head.data);bm.free();head.data.update()
    for v in head.data.vertices:
        blend=max(0,min(1,(1.58-v.co.z)/.065))
        radius=math.sqrt((v.co.x/.055)**2+((v.co.y+.012)/.055)**2)
        if radius>1:
            factor=1+(1/radius-1)*blend
            v.co.x*=factor;v.co.y=-.012+(v.co.y+.012)*factor
    # One Catmull-Clark pass retains facial edge loops for future sculpting.
    bpy.context.view_layer.objects.active=head
    sub=head.modifiers.new('Facial subdivision','SUBSURF');sub.levels=1
    bpy.ops.object.modifier_apply(modifier=sub.name)
    # Fine brow hairs sit on the actual facial surface, rather than floating bars.
    bm=bmesh.new();bm.from_mesh(head.data);surface=BVHTree.FromBMesh(bm)
    browmat=bpy.data.materials.new('Dark_brow_hair');browmat.diffuse_color=(.035,.027,.020,1)
    for s in [-1,1]:
        for i in range(68):
            t=i/67;x=s*(.013+t*.038);z=1.724+.004*math.sin(t*math.pi)-.004*t
            hit,normal,_,_=surface.ray_cast(Vector((x,.3,z)),Vector((0,-1,0)))
            if hit is not None:
                a=hit+normal*.0007
                b=a+Vector((s*.0015,.0001,.0030*(1-.5*t)))
                cord('Anatomical brow hair',[a,b],.0005,browmat,'Head','head',5,1)
    bm.free()

    def fitted_asset(obj_file, clo_file):
        coords, texcoords, asset_faces=obj_data(obj_file)
        mapping=[];reading=False;axis_scales=[1.0,1.0,1.0]
        with open(clo_file,encoding='utf-8') as handle:
            for line in handle:
                a=line.split()
                if not a or line.startswith('#'):continue
                if a[0] in ['x_scale','y_scale','z_scale']:
                    axis={'x_scale':0,'y_scale':1,'z_scale':2}[a[0]]
                    axis_scales[axis]=abs(deformed[int(a[1])][axis]-deformed[int(a[2])][axis])/float(a[3])
                if a[0]=='verts':reading=True;continue
                if reading:
                    if not a[0].lstrip('-').isdigit():break
                    mapping.append(a)
        assert len(mapping)==len(coords),(obj_file,len(mapping),len(coords))
        for i,record in enumerate(mapping):
            if len(record)==1:coords[i]=deformed[int(record[0])].copy()
            else:
                coords[i]=sum((deformed[int(record[j])]*float(record[j+3]) for j in range(3)),Vector())
                coords[i]+=Vector(tuple(float(record[j+6])*axis_scales[j] for j in range(3)))
        return coords,texcoords,asset_faces

    hair_dir=os.path.join(base_dir,'hair','short02')
    hv,hu,hf=fitted_asset(os.path.join(hair_dir,'short02.obj'),os.path.join(hair_dir,'short02.mhclo'))
    hairmat=texture_material('MakeHuman_short_hair_CC0',os.path.join(hair_dir,'short02_diffuse.png'),.88,True)
    hair=mesh_from_faces('Short textured hair',hv,hu,hf,hairmat,'Hair','head')
    normal_path=os.path.join(hair_dir,'short02_normal.png')
    if os.path.isfile(normal_path):
        image=bpy.data.images.load(normal_path,check_existing=True);image.colorspace_settings.name='Non-Color'
        tex=hairmat.node_tree.nodes.new('ShaderNodeTexImage');tex.image=image
        normal=hairmat.node_tree.nodes.new('ShaderNodeNormalMap');normal.inputs['Strength'].default_value=.7
        hairmat.node_tree.links.new(tex.outputs['Color'],normal.inputs['Color'])
        hairmat.node_tree.links.new(normal.outputs['Normal'],hairmat.node_tree.nodes.get('Principled BSDF').inputs['Normal'])

    eye_dir=os.path.join(base_dir,'eyes','low-poly')
    ev,eu,ef=fitted_asset(os.path.join(eye_dir,'low-poly.obj'),os.path.join(eye_dir,'low-poly.mhclo'))
    candidates=[]
    for folder,_,files in os.walk(os.path.join(base_dir,'eyes')):
        for file in files:
            if file.endswith('.png') and ('green' in file or 'brown' in file):candidates.append(os.path.join(folder,file))
    assert candidates,'Core eye texture is missing'
    eyemat=texture_material('MakeHuman_eyes_CC0',next(p for p in candidates if p.endswith('brown_eye.png')),.25)
    eyes=mesh_from_faces('Anatomical eyes',ev,eu,ef,eyemat,'Eyes',['eye.R','eye.L'])
    print('ANATOMICAL_HEAD',len(head.data.vertices),'vertices','scale',scale,'eyes',[list(convert(p)) for p in eye_groups.values()])
    return eye_groups,scale,offset
