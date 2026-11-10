"""Build Ashfall's editable, full-body review character with Blender 4.5.

Run: blender --background --python tools/build_scavenger.py
Ashfall clothing and rig, using CC0 MakeHuman facial topology and core textures.
Blender uses metres, Z up, +Y forward; glTF exports Y up, -Z forward.
"""
import bpy
import json
import math
import os
import tempfile
import numpy as np
from mathutils import Vector, Quaternion
from mathutils.geometry import intersect_point_line
from mathutils.kdtree import KDTree

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'assets', 'characters', 'scavenger')
SOURCE = os.path.join(OUT, 'source')
os.makedirs(SOURCE, exist_ok=True)
tempfile.tempdir = os.path.join(ROOT, '.godot', 'character-export')
os.makedirs(tempfile.tempdir, exist_ok=True)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
for data in list(bpy.data.actions):
    bpy.data.actions.remove(data)
V = Vector
TAU = math.tau
bones = {}
parts = {}
rng = np.random.default_rng(4717)


def material(name, color, roughness=.75, metal=0, surface=None):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    p = m.node_tree.nodes.get('Principled BSDF')
    p.inputs['Base Color'].default_value = (*color, 1)
    p.inputs['Roughness'].default_value = roughness
    p.inputs['Metallic'].default_value = metal
    if surface:
        n = 1024
        y, x = np.mgrid[0:n, 0:n]
        noise = rng.normal(0, .025, (n, n))
        variation = .075*np.sin(x*.025)*np.cos(y*.019)+noise
        if surface == 'canvas':
            height = .05*np.sin(x*2.1)+.05*np.sin(y*2.1)+noise*.3
        elif surface == 'skin':
            height = noise*.32+.015*np.sin(x*.27)*np.sin(y*.3)
        else:
            height = noise+.03*np.sin(x*.13+np.sin(y*.19)*2)
        for kind in ['albedo', 'normal', 'roughness']:
            pixels = np.ones((n, n, 4), dtype=np.float32)
            if kind == 'albedo':
                pixels[:, :, :3] = np.array(color)[None, None, :]*(1+variation[:, :, None])
            elif kind == 'roughness':
                pixels[:, :, :3] = np.clip(roughness+variation[:, :, None]*.5, .15, .98)
            else:
                gy, gx = np.gradient(height)
                normals = np.stack([-gx, -gy, np.ones_like(gx)], axis=-1)
                normals /= np.linalg.norm(normals, axis=-1, keepdims=True)
                pixels[:, :, :3] = normals*.5+.5
            im = bpy.data.images.new(name+'_'+kind, n, n)
            if kind != 'albedo':
                im.colorspace_settings.name = 'Non-Color'
            im.pixels.foreach_set(pixels.ravel())
            im.filepath_raw = os.path.join(OUT, name+'_'+kind+'.png')
            im.file_format = 'PNG'
            im.save()
            node = m.node_tree.nodes.new('ShaderNodeTexImage')
            node.image = im
            if kind == 'normal':
                bump = m.node_tree.nodes.new('ShaderNodeNormalMap')
                bump.inputs['Strength'].default_value = .6
                m.node_tree.links.new(node.outputs['Color'], bump.inputs['Color'])
                m.node_tree.links.new(bump.outputs['Normal'], p.inputs['Normal'])
            else:
                m.node_tree.links.new(node.outputs['Color'], p.inputs['Base Color' if kind == 'albedo' else 'Roughness'])
    return m


cloth = material('Field_canvas', (.16, .18, .12), .9, surface='canvas')
seam_mat = material('Canvas_binding', (.095, .105, .068), .92)
thread = material('Faded_thread', (.16, .16, .12), .9)
pants = material('Charcoal_twill', (.075, .084, .074), .92, surface='canvas')
knit = material('Wool_underlayer', (.085, .077, .065), .96)
leather = material('Brown_leather', (.105, .071, .045), .72, surface='leather')
rubber = material('Boot_rubber', (.022, .025, .022), .91)
bagmat = material('Khaki_satchel', (.205, .177, .115), .92, surface='canvas')
metal = material('Aged_steel', (.17, .185, .16), .43, .8)
steel = material('Torch_anodized', (.031, .038, .034), .48, .68)
glass = material('Torch_glass', (.31, .36, .31), .18, .45)


def bone(name, head, tail, parent=None):
    bones[name] = (V(head), V(tail), parent)


bone('root', (0, 0, 0), (0, 0, .13))
bone('pelvis', (0, 0, .94), (0, 0, 1.06), 'root')
bone('spine', (0, 0, 1.06), (0, 0, 1.23), 'pelvis')
bone('chest', (0, 0, 1.23), (0, 0, 1.45), 'spine')
bone('neck', (0, 0, 1.45), (0, 0, 1.59), 'chest')
bone('head', (0, 0, 1.59), (0, 0, 1.79), 'neck')
bone('jaw', (0, .03, 1.66), (0, .08, 1.60), 'head')
for s, side in [(1, 'R'), (-1, 'L')]:
    bone('clavicle.'+side, (s*.035, 0, 1.44), (s*.205, 0, 1.44), 'chest')
    bone('upper_arm.'+side, (s*.205, 0, 1.44), (s*.34, .012, 1.205), 'clavicle.'+side)
    bone('forearm.'+side, (s*.34, .012, 1.205), (s*.405, .035, .985), 'upper_arm.'+side)
    bone('hand.'+side, (s*.405, .035, .985), (s*.435, .045, .895), 'forearm.'+side)
    bone('thigh.'+side, (s*.095, 0, .94), (s*.105, .025, .53), 'pelvis')
    bone('shin.'+side, (s*.105, .025, .53), (s*.115, 0, .13), 'thigh.'+side)
    bone('foot.'+side, (s*.115, 0, .13), (s*.115, .15, .065), 'shin.'+side)
    bone('toe.'+side, (s*.115, .15, .065), (s*.115, .245, .055), 'foot.'+side)
    bone('eye.'+side, (s*.031, .073, 1.704), (s*.031, .098, 1.704), 'head')
bone('satchel', (-.245, -.025, 1.0), (-.245, -.025, .80), 'pelvis')


def weight(obj, candidates):
    if isinstance(candidates, str):
        g = obj.vertex_groups.new(name=candidates)
        g.add(list(range(len(obj.data.vertices))), 1, 'REPLACE')
    else:
        groups = {n: obj.vertex_groups.new(name=n) for n in candidates}
        for v in obj.data.vertices:
            p = obj.matrix_world @ v.co
            distances = []
            for n in candidates:
                a, b, _ = bones[n]
                _, t = intersect_point_line(p, a, b)
                q = a.lerp(b, max(0, min(1, t)))
                distances.append(((p-q).length, n))
            distances.sort()
            chosen = distances[:2]
            values = [1/max(.012, d)**5 for d, _ in chosen]
            total = sum(values)
            for value, (_, n) in zip(values, chosen):
                groups[n].add([v.index], value/total, 'REPLACE')


def finish(obj, mat, group, candidates):
    obj.data.materials.append(mat)
    for poly in obj.data.polygons:
        poly.use_smooth = True
    weight(obj, candidates)
    parts.setdefault(group, []).append(obj)
    return obj


def uv_strip(me, sides, rings):
    uv = me.uv_layers.new(name='UVMap')
    for poly in me.polygons:
        indices = [me.loops[i].vertex_index % sides for i in poly.loop_indices]
        wraps = max(indices)-min(indices) > sides/2
        for li in poly.loop_indices:
            vi = me.loops[li].vertex_index
            u = (vi % sides)/sides
            if wraps and u < .5:
                u += 1
            uv.data[li].uv = (u, (vi//sides)/max(1, rings-1))


def loft(name, points, radii, mat, group, candidates, sides=40, steps=5, folds=0):
    pts = list(map(V, points))
    centers, sizes = [], []
    for i in range(len(pts)-1):
        for j in range(steps):
            t = j/steps
            centers.append(pts[i].lerp(pts[i+1], t))
            sizes.append(tuple(radii[i][k]*(1-t)+radii[i+1][k]*t for k in range(2)))
    centers.append(pts[-1])
    sizes.append(radii[-1])
    vertices, faces = [], []
    for i, p in enumerate(centers):
        tangent = (centers[min(i+1, len(centers)-1)]-centers[max(i-1, 0)]).normalized()
        b = V((0, 1, 0))
        b = (b-tangent*tangent.dot(b)).normalized()
        a = b.cross(tangent).normalized()
        for j in range(sides):
            theta = j*TAU/sides
            wrinkles = 1+folds*(.6*math.sin(i*.93+theta*3)+.4*math.sin(i*1.71-theta*2))
            vertices.append(p+(a*math.cos(theta)*sizes[i][0]+b*math.sin(theta)*sizes[i][1])*wrinkles)
    for i in range(len(centers)-1):
        for j in range(sides):
            k = (j+1) % sides
            faces.append((i*sides+j, i*sides+k, (i+1)*sides+k, (i+1)*sides+j))
    faces.extend([tuple(reversed(range(sides))), tuple((len(centers)-1)*sides+j for j in range(sides))])
    me = bpy.data.meshes.new(name)
    me.from_pydata(vertices, [], faces)
    me.update()
    uv_strip(me, sides, len(centers))
    obj = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(obj)
    return finish(obj, mat, group, candidates)


def cord(name, points, radius, mat, group, candidates, sides=8, steps=3):
    return loft(name, points, [(radius, radius)]*len(points), mat, group, candidates, sides, steps)


def ellipsoid(name, center, scale, mat, group, candidates, segments=40, rings=24):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings, location=center)
    o = bpy.context.object
    o.name = name
    o.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return finish(o, mat, group, candidates)


def box(name, center, size, mat, group, candidates, bevel=.006, rotation=None):
    bpy.ops.mesh.primitive_cube_add(size=1, location=center)
    o = bpy.context.object
    o.name = name
    o.dimensions = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel:
        mod = o.modifiers.new('Rounded constructed edges', 'BEVEL')
        mod.width = bevel
        mod.segments = 3
        bpy.ops.object.modifier_apply(modifier=mod.name)
    if rotation:
        o.rotation_euler = rotation
    return finish(o, mat, group, candidates)


def patch(name, coords, mat, group, candidates, thickness=.004):
    me = bpy.data.meshes.new(name)
    me.from_pydata(coords, [], [tuple(range(len(coords)))])
    me.update()
    o = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(o)
    solid = o.modifiers.new('Fabric thickness', 'SOLIDIFY')
    solid.thickness = thickness
    bevel = o.modifiers.new('Bound edges', 'BEVEL')
    bevel.width = .002
    bevel.segments = 3
    bpy.context.view_layer.objects.active = o
    bpy.ops.object.modifier_apply(modifier=solid.name)
    bpy.ops.object.modifier_apply(modifier=bevel.name)
    return finish(o, mat, group, candidates)


# Continuous clothed torso. Circumferential loops stay editable in Blender.
shell_parts=[]
shell_parts.append(loft('Field jacket shell', [(0, 0, z) for z in [.875, .91, 1.0, 1.1, 1.22, 1.34, 1.43, 1.475]],
     [(.195,.13),(.203,.137),(.188,.126),(.183,.127),(.213,.141),(.231,.132),(.226,.106),(.09,.081)],
     cloth, 'Jacket', ['pelvis','spine','chest'], 64, 6, .018))
loft('Wool collar', [(0,0,1.39),(0,0,1.47),(0,0,1.51)], [(.09,.084),(.075,.074),(.068,.069)], knit, 'Neckwear', ['chest','neck'], 48, 4)
loft('Jacket waist hem', [(0,0,.875),(0,0,.894)], [(.199,.134),(.201,.135)], seam_mat, 'Jacket', ['pelvis','spine'], 64, 2)
for s, side in [(1,'R'),(-1,'L')]:
    armchain = ['clavicle.'+side, 'upper_arm.'+side, 'forearm.'+side, 'hand.'+side]
    armpts = [(s*.176,0,1.425),(s*.243,0,1.392),(s*.30,.006,1.30),(s*.34,.012,1.205),(s*.367,.022,1.12),(s*.403,.034,.999)]
    shell_parts.append(loft('Articulated sleeve '+side, armpts, [(.077,.082),(.082,.082),(.076,.076),(.071,.069),(.062,.062),(.044,.043)], cloth,'Jacket',armchain[:-1],48,7,.04))
    cord('Sleeve outer seam '+side, [(p[0]+s*r,p[1],p[2]) for p,r in zip(armpts,[.087,.087,.078,.072,.065,.046])], .0012, thread,'Jacket',armchain[:-1])
    loft('Cuff '+side, [(s*.399,.034,1.016),(s*.408,.037,.985)], [(.047,.046),(.042,.041)], seam_mat,'Jacket',['forearm.'+side,'hand.'+side],40,4)
    box('Cuff tab '+side, (s*.405,.077,1.007),(.045,.008,.028),cloth,'Jacket','forearm.'+side,.003)
    ellipsoid('Cuff stud '+side,(s*.405,.083,1.008),(.005,.002,.005),metal,'Jacket','forearm.'+side,20,12)
    # Jacket chest pockets, flaps and double stitched seams.
    for z, x, w, h in [(1.285,s*.112,.137,.113),(1.005,s*.113,.132,.117)]:
        y = .141 if z>1.2 else .132
        box('Bellows jacket pocket', (x,y,z),(w,.020,h),cloth,'Jacket','chest' if z>1.2 else 'pelvis',.009)
        patch('Pocket flap',[(x-w*.52,y+.018,z+h*.45),(x+w*.52,y+.018,z+h*.45),(x+w*.48,y+.025,z+h*.12),(x,y+.03,z+h*.02),(x-w*.48,y+.025,z+h*.12)],seam_mat,'Jacket','chest' if z>1.2 else 'pelvis')
        ellipsoid('Pocket snap',(x,y+.032,z+h*.19),(.004,.002,.004),metal,'Jacket','chest' if z>1.2 else 'pelvis',16,10)
        cord('Pocket side seam',[(x-w*.44,y+.023,z+h*.32),(x-w*.44,y+.025,z-h*.42),(x+w*.44,y+.025,z-h*.42),(x+w*.44,y+.023,z+h*.32)],.0008,thread,'Jacket','chest' if z>1.2 else 'pelvis')
    patch('Folded collar '+side,[(s*.025,.083,1.488),(s*.10,.078,1.48),(s*.162,.104,1.397),(s*.092,.159,1.382),(s*.035,.139,1.44)],cloth,'Neckwear','chest',.007)
    cord('Collar topstitch '+side,[(s*.035,.088,1.48),(s*.10,.084,1.472),(s*.15,.11,1.40),(s*.094,.164,1.392)],.0008,thread,'Neckwear','chest')
# Zipper and storm placket deliberately follow the changing chest depth.
cord('Storm placket',[(0,.138,.89),(0,.14,1.01),(0,.14,1.12),(0,.15,1.28),(0,.12,1.43)],.007,seam_mat,'Jacket',['pelvis','spine','chest'],12,8)
for z in np.arange(.90,1.43,.009):
    y=.15 if z>1.15 and z<1.37 else .14
    box('Zipper teeth',(0,y,z),(.008,.003,.002),metal,'Jacket',['pelvis','spine','chest'],.0005)
box('Zipper pull',(0,.153,1.36),(.011,.004,.027),metal,'Jacket','chest',.002)

# Full trousers, articulated knees, crotch gusset, cargo pockets, belt and boots.
loft('Trouser seat',[(0,0,.87),(0,0,.95),(0,0,1.005)],[(.177,.105),(.174,.113),(.163,.111)],pants,'Trousers','pelvis',56,5,.014)
for s, side in [(1,'R'),(-1,'L')]:
    chain=['pelvis','thigh.'+side,'shin.'+side,'foot.'+side]
    points=[(s*.092,0,.94),(s*.105,.005,.82),(s*.108,.015,.68),(s*.105,.025,.54),(s*.11,.017,.44),(s*.115,.003,.30),(s*.115,-.002,.21),(s*.115,0,.185)]
    loft('Cargo trouser leg '+side,points,[(.091,.105),(.092,.105),(.086,.094),(.078,.088),(.078,.084),(.074,.078),(.07,.074),(.057,.059)],pants,'Trousers',chain[:-1],48,8,.045)
    cord('Outseam '+side,[(p[0]+s*r,p[1],p[2]) for p,r in zip(points,[.091,.092,.086,.078,.078,.074,.070,.057])],.0011,seam_mat,'Trousers',chain[:-1])
    box('Cargo bellows pocket '+side,(s*.187,.013,.75),(.043,.135,.167),pants,'Trousers','thigh.'+side,.009)
    box('Cargo pocket flap '+side,(s*.193,.014,.817),(.047,.142,.041),seam_mat,'Trousers','thigh.'+side,.005)
    for y in [-.035,.055]:
        ellipsoid('Cargo flap stud',(s*.219,y,.812),(.002,.004,.004),metal,'Trousers','thigh.'+side,16,10)
    # Boot upper has a curved instep and ankle, the sole has a separate welt and tread.
    foot='foot.'+side
    loft('Boot shaft '+side,[(s*.115,-.008,.07),(s*.115,-.008,.14),(s*.115,-.008,.225)],[(.064,.084),(.062,.067),(.059,.058)],leather,'Boots',[foot,'shin.'+side],48,7,.012)
    ellipsoid('Boot vamp '+side,(s*.115,.105,.071),(.073,.163,.062),leather,'Boots',foot,48,24)
    box('Lugged sole '+side,(s*.115,.071,.022),(.154,.304,.038),rubber,'Boots',foot,.022)
    box('Leather welt '+side,(s*.115,.073,.043),(.151,.301,.015),seam_mat,'Boots',foot,.020)
    box('Toe cap '+side,(s*.115,.189,.061),(.143,.081,.049),leather,'Boots','toe.'+side,.017)
    for y in np.arange(-.05,.205,.034):
        for x in [-.049,.049]:
            box('Outsole lug',(s*.115+x,y,.005),(.046,.022,.009),rubber,'Boots',foot,.003)
    box('Boot tongue',(s*.115,.06,.158),(.061,.016,.105),leather,'Boots',foot,.01,(-.43,0,0))
    for i,z in enumerate(np.linspace(.105,.211,7)):
        y=.094-(z-.105)*.62
        for x in [-.026,.026]:
            ellipsoid('Lace eyelet',(s*.115+x,y,z),(.004,.003,.004),metal,'Boots',foot,16,8)
        cord('Crossed bootlace',[(s*.115-.026,y+.004,z),(s*.115+.026,y-.006,z+.012)],.0016,thread,'Boots',foot)
        cord('Crossed bootlace',[(s*.115+.026,y+.004,z),(s*.115-.026,y-.006,z+.012)],.0016,thread,'Boots',foot)
loft('Leather belt',[(0,0,.982),(0,0,1.014)],[(.178,.12),(.175,.12)],leather,'Equipment','pelvis',64,2)
box('Belt buckle',(0,.13,1.0),(.052,.012,.034),metal,'Equipment','pelvis',.004)
box('Buckle inset',(0,.138,1.0),(.035,.004,.019),leather,'Equipment','pelvis',.002)

# Full anatomically laid-out hands. Fingers are individually weighted, not fused props.
for s,side in [(1,'R'),(-1,'L')]:
    wrist=V((s*.405,.035,.985))
    axis=V((s*.030,.010,-.09)).normalized()
    across=V((s*.949,0,.316)).normalized()
    palm=wrist+axis*.049
    glove=ellipsoid('Glove palm '+side,palm,(.038,.024,.059),leather,'Gloves','hand.'+side)
    glove.rotation_euler.y=-s*.30
    loft('Glove wrist '+side,[wrist-axis*.009,wrist+axis*.035],[(.034,.031),(.037,.030)],leather,'Gloves',['forearm.'+side,'hand.'+side],32,4)
    for k,name in enumerate(['index','middle','ring','pinky']):
        base=wrist+axis*(.078 if k<2 else .073)+across*((1.5-k)*.018)
        length=[.076,.083,.077,.062][k]
        joints=[base,base+axis*length*.43+V((0,.004,0)),base+axis*length*.77+V((0,.013,0)),base+axis*length+V((0,.025,0))]
        for j in range(3):
            n=name+str(j+1)+'.'+side
            bone(n,joints[j],joints[j+1],'hand.'+side if j==0 else name+str(j)+'.'+side)
        names=[name+str(j+1)+'.'+side for j in range(3)]
        loft('Gloved '+name+' '+side,joints,[(.010,.010),(.010,.010),(.0085,.0085),(.005,.005)],leather,'Gloves',names,20,5,.025)
        for j in [1,2]:
            p=joints[j]-V((0,.008,0))
            cord('Finger crease',[p-across*.007,p+across*.007],.0008,seam_mat,'Gloves',names[j-1])
    base=wrist+axis*.025+across*.033
    joints=[base,base+across*.020+axis*.018,base+across*.019+axis*.042+V((0,.017,0)),base+across*.008+axis*.063+V((0,.028,0))]
    for j in range(3):
        bone('thumb'+str(j+1)+'.'+side,joints[j],joints[j+1],'hand.'+side if j==0 else 'thumb'+str(j)+'.'+side)
    loft('Gloved thumb '+side,joints,[(.014,.013),(.013,.013),(.011,.011),(.006,.006)],leather,'Gloves',['thumb'+str(j+1)+'.'+side for j in range(3)],24,5)
    # Reinforcement on the back of the hand, with bound construction seam.
    p=palm+V((0,-.022,0))
    pad=ellipsoid('Glove dorsal reinforcement',p,(.030,.004,.037),seam_mat,'Gloves','hand.'+side,32,16)
    pad.rotation_euler.y=-s*.3

# Anatomical face, eyes and textured hair use the CC0 MakeHuman core assets.
# Clothing, equipment, skeleton and animations remain authored for Ashfall.
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from scavenger_head import build_head
head_eyes,head_scale,head_offset=build_head(SOURCE, finish, cord)
for side,p in head_eyes.items():
    eye=V((p.x*head_scale,p.z*head_scale-.035,p.y*head_scale+head_offset))
    bone('eye.'+side,eye,eye+V((0,.025,0)),'head')

# Shoulder bag follows the approved civilian concept. Strap runs over both sides.
box('Canvas satchel',(-.247,-.015,.902),(.115,.228,.236),bagmat,'Satchel','satchel',.026)
box('Satchel flap',(-.309,-.005,.978),(.021,.231,.100),bagmat,'Satchel','satchel',.014)
for y in [-.069,.066]:
    box('Leather satchel fastening',(-.324,y,.946),(.008,.024,.092),leather,'Satchel','satchel',.004)
    box('Bag clasp',(-.331,y,.928),(.008,.031,.024),metal,'Satchel','satchel',.003)
    cord('Satchel piping',[(-.31,y,.807),(-.31,y,.977)],.0014,thread,'Satchel','satchel')
for front in [1,-1]:
    coords=[]
    centers=[(.153,front*.092,1.463),(.10,front*.143,1.36),(-.012,front*.15,1.21),(-.13,front*.14,1.055),(-.235,front*.095,.97)]
    for x,y,z in centers:coords.extend([(x-.021,y,z-.011),(x+.021,y,z+.011)])
    me=bpy.data.meshes.new('Shoulder webbing');me.from_pydata(coords,[],[(i*2,i*2+1,i*2+3,i*2+2) for i in range(len(centers)-1)]);me.update()
    ob=bpy.data.objects.new('Crossbody strap',me);bpy.context.collection.objects.link(ob)
    solid=ob.modifiers.new('Webbing thickness','SOLIDIFY');solid.thickness=.004
    bpy.context.view_layer.objects.active=ob;bpy.ops.object.modifier_apply(modifier=solid.name)
    finish(ob,leather,'Equipment',['pelvis','spine','chest'])
box('Strap adjustment buckle',(.003,.164,1.232),(.048,.012,.054),metal,'Equipment','chest',.004, (0,.0,-.55))
box('Buckle webbing',(.003,.173,1.232),(.031,.005,.041),leather,'Equipment','chest',.002,(0,0,-.55))

# Torch is a separate item with its own bone/socket; shared skeleton, no floating viewmodel.
hand=bones['hand.R'];wrist=hand[0];axis=(hand[1]-wrist).normalized()
torch_center=wrist+axis*.065+V((0,.034,0))
bone('item.R',torch_center,torch_center+V((0,.18,0)),'hand.R')
def torch_lathe(name,profile,mat,segments=64,knurl=False):
    vertices=[];faces=[]
    for i,(y,r) in enumerate(profile):
        for j in range(segments):
            a=TAU*j/segments
            rr=r+(.00065*math.sin(j*math.pi*.5+i*math.pi*.5) if knurl else 0)
            vertices.append(torch_center+V((rr*math.cos(a),y,rr*math.sin(a))))
    for i in range(len(profile)-1):
        for j in range(segments):
            k=(j+1)%segments
            faces.append((i*segments+j,(i+1)*segments+j,(i+1)*segments+k,i*segments+k))
    me=bpy.data.meshes.new(name);me.from_pydata(vertices,[],faces);me.update();uv_strip(me,segments,len(profile))
    ob=bpy.data.objects.new(name,me);bpy.context.collection.objects.link(ob);finish(ob,mat,'Flashlight','item.R')
torch_lathe('Flashlight housing',[(-.095,0),(-.095,.025),(-.09,.028),(.067,.028),(.078,.035),(.095,.047),(.14,.047),(.148,.043),(.148,0)],steel,96)
torch_lathe('Knurled torch grip',[(-.077+i*.0027,.029) for i in range(52)],steel,96,True)
for y,r in [(-.088,.029),(-.078,.029),(.064,.030),(.098,.048),(.126,.048),(.141,.048)]:
    torch_lathe('Machined torch band',[(y-.002,r-.001),(y,r),(y+.002,r),(y+.003,r-.001)],metal)
torch_lathe('Torch lens',[(.149,0),(.149,.039),(.150,.039),(.150,0)],glass,96)
ellipsoid('Torch thumb switch',torch_center+V((0,.015,.029)),(.013,.022,.004),rubber,'Flashlight','item.R',32,16)

# Weld the jacket across the shoulder seams; no disconnected caps when posing.
bpy.ops.object.select_all(action='DESELECT')
for ob in shell_parts:ob.select_set(True)
bpy.context.view_layer.objects.active=shell_parts[0]
bpy.ops.object.join();shell=bpy.context.object
for ob in shell_parts[1:]:parts['Jacket'].remove(ob)
source_weights=[];tree=KDTree(len(shell.data.vertices))
group_names={g.index:g.name for g in shell.vertex_groups}
for v in shell.data.vertices:
    tree.insert(v.co,v.index)
    source_weights.append({group_names[g.group]:g.weight for g in v.groups})
tree.balance()
mod=shell.modifiers.new('Continuous shoulder construction','REMESH');mod.mode='VOXEL';mod.voxel_size=.0045;mod.use_smooth_shade=True
bpy.ops.object.modifier_apply(modifier=mod.name)
mod=shell.modifiers.new('Relax tailored cloth','SMOOTH');mod.factor=.6;mod.iterations=4
bpy.ops.object.modifier_apply(modifier=mod.name)
shell.vertex_groups.clear()
groups={n:shell.vertex_groups.new(name=n) for n in group_names.values()}
for v in shell.data.vertices:
    weights={}
    for co,i,distance in tree.find_n(v.co,3):
        factor=1/max(.0005,distance)**3
        for n,w in source_weights[i].items():weights[n]=weights.get(n,0)+factor*w
    chosen=sorted(weights.items(),key=lambda item:item[1],reverse=True)[:4]
    total=sum(w for n,w in chosen)
    for n,w in chosen:groups[n].add([v.index],w/total,'REPLACE')
bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.uv.smart_project(island_margin=.01);bpy.ops.object.mode_set(mode='OBJECT')

# Real deform skeleton. Each part keeps editable mesh topology, normalized weights.
arm=bpy.data.armatures.new('Ashfall humanoid skeleton')
rig=bpy.data.objects.new('ScavengerRig',arm);bpy.context.collection.objects.link(rig)
bpy.context.view_layer.objects.active=rig
bpy.ops.object.select_all(action='DESELECT');rig.select_set(True)
bpy.ops.object.mode_set(mode='EDIT')
for name,(a,b,parent) in bones.items():
    eb=arm.edit_bones.new(name);eb.head=a;eb.tail=b
    if parent:eb.parent=arm.edit_bones[parent]
bpy.ops.object.mode_set(mode='OBJECT')
rig.show_in_front=True
rig['character_height_m']=1.81
rig['forward_axis']='+Y (Blender), -Z (Godot)'
rig['notes']='Full civilian scavenger. CC0 MakeHuman head adapted to the Ashfall rig. Modeling draft, not a photogrammetry scan.'
for group,objects in parts.items():
    bpy.ops.object.select_all(action='DESELECT')
    for ob in objects:ob.select_set(True)
    bpy.context.view_layer.objects.active=objects[0]
    bpy.ops.object.join();ob=bpy.context.object;ob.name=group
    bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    # All detail surfaces receive UVs; smart unwrap only fills missing UV data.
    if not ob.data.uv_layers:
        bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.uv.smart_project(island_margin=.012);bpy.ops.object.mode_set(mode='OBJECT')
    modifier=ob.modifiers.new('Humanoid skin deformation','ARMATURE');modifier.object=rig
    ob.parent=rig
    for p in ob.data.polygons:p.use_smooth=True
    for v in ob.data.vertices:
        assert v.groups and abs(sum(g.weight for g in v.groups)-1)<.001,(group,v.index,'invalid weight')
    ob['component']=group
    # Exported vertex colors should be a multiplier only on the facial skin.
    if group=='Head':
        pass

# Pose clips are deliberately in-place. The CharacterBody remains authoritative.
scene=bpy.context.scene;scene.render.fps=30
def rotate_world(name,angles):
    p=rig.pose.bones[name]
    rest=p.bone.matrix_local.to_quaternion()
    from mathutils import Euler
    q=Euler(angles,'XYZ').to_quaternion()
    p.rotation_mode='QUATERNION';p.rotation_quaternion=rest.inverted()@q@rest

def action(name,frames,mode):
    rig.animation_data_create();rig.animation_data.action=None
    for f in range(frames+1):
        phase=TAU*f/frames
        for p in rig.pose.bones:
            p.rotation_mode='QUATERNION';p.rotation_quaternion=Quaternion();p.location=(0,0,0);p.scale=(1,1,1)
        if mode=='idle':
            rotate_world('chest',(.007*math.sin(phase),0,.006*math.sin(phase)))
        if mode in ['walk','run','back','left','right','crouch_walk']:
            amplitude=.40 if mode!='run' else .70
            if mode=='crouch_walk':amplitude=.24
            for s,side in [(1,'R'),(-1,'L')]:
                swing=math.sin(phase+(0 if s==1 else math.pi))
                if mode in ['left','right']:
                    rotate_world('thigh.'+side,(.04,amplitude*swing*(1 if mode=='left' else -1),0))
                else:
                    rotate_world('thigh.'+side,(amplitude*swing*(-1 if mode=='back' else 1),0,0))
                rotate_world('shin.'+side,(-max(0,-swing)*(.9 if mode=='run' else .60),0,0))
                rotate_world('foot.'+side,(max(0,-swing)*.32-amplitude*swing*.4,0,0))
                rotate_world('upper_arm.'+side,(-amplitude*swing*.32,0,-s*.07))
            rig.pose.bones['pelvis'].location=rig.data.bones['pelvis'].matrix_local.to_quaternion().inverted()@V((0,0,abs(math.sin(phase))*.016))
            rotate_world('chest',(.035 if mode=='run' else .012,0,.025*math.sin(phase)))
        if mode in ['crouch_idle','crouch_walk']:
            rig.pose.bones['pelvis'].location=rig.data.bones['pelvis'].matrix_local.to_quaternion().inverted()@V((0,0,-.37))
            for side in ['R','L']:
                rotate_world('thigh.'+side,(1.0+(math.sin(phase+(0 if side=='R' else math.pi))*.13 if mode=='crouch_walk' else 0),0,0))
                rotate_world('shin.'+side,(-2.0,0,0))
                rotate_world('foot.'+side,(1.0,0,0))
            rotate_world('spine',(-.48,0,0));rotate_world('chest',(-.36,0,0))
        if mode=='air':
            for side in ['R','L']:
                rotate_world('thigh.'+side,(.3,0,0));rotate_world('shin.'+side,(-.6,0,0))
        for p in rig.pose.bones:
            p.keyframe_insert('rotation_quaternion',frame=f+1,group=p.name)
            if p.name=='pelvis':p.keyframe_insert('location',frame=f+1,group=p.name)
    ac=rig.animation_data.action;ac.name=name
    track=rig.animation_data.nla_tracks.new();track.name=name
    strip=track.strips.new(name,1,ac);strip.action_frame_start=1;strip.action_frame_end=frames+1
    track.mute=True

for name,frames,mode in [('Idle',90,'idle'),('Walk',32,'walk'),('Run',22,'run'),('WalkBack',36,'back'),('StrafeLeft',34,'left'),('StrafeRight',34,'right'),('CrouchIdle',90,'crouch_idle'),('CrouchWalk',48,'crouch_walk'),('Airborne',30,'air')]:
    action(name,frames,mode)
rig.animation_data.action=None
for p in rig.pose.bones:p.rotation_quaternion=Quaternion();p.location=(0,0,0)
scene.frame_set(1)

# Hand-grip and eye socket positions stored in model space for the Godot adapter.
manifest={
    'height_m':1.81,'bone_count':len(bones),'components':list(parts),
    'triangles':sum(sum(len(p.vertices)-2 for p in ob.data.polygons) for ob in scene.objects if ob.type=='MESH'),
    'animations':['Idle','Walk','Run','WalkBack','StrafeLeft','StrafeRight','CrouchIdle','CrouchWalk','Airborne'],
    'torch_center_blender':list(torch_center),'torch_beam_blender':list(torch_center+V((0,.155,0))),
    'face_status':'CC0 MakeHuman anatomical base, adult morph and core skin, eyes and short hair. Further sculpting and texture refinement needed for photorealism.'
}
with open(os.path.join(OUT,'manifest.json'),'w') as f:json.dump(manifest,f,indent=2)
bpy.ops.file.pack_all()
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(SOURCE,'ashfall_scavenger.blend'))
for tr in rig.animation_data.nla_tracks:tr.mute=False
bpy.ops.export_scene.gltf(filepath=os.path.join(OUT,'ashfall_scavenger.glb'),export_format='GLB',export_animations=True,export_animation_mode='NLA_TRACKS',export_nla_strips=True,export_yup=True,export_apply=False,export_skins=True,export_all_influences=False,export_force_sampling=True)
print('FULL_BODY_EXPORTED',json.dumps(manifest))
