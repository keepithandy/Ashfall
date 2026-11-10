"""Generate Godot 4 scene files from the source modular-kit dimensions.
No installed Godot editor is required for generation; runtime validation is separate.
"""
from pathlib import Path
R=Path(__file__).resolve().parents[1]
SC=R/'scenes'; SC.mkdir(exist_ok=True)
G='res://assets/crossroads_v03/geometry/'
S='res://assets/crossroads_v03/scenes/'

# Mesh scene + explicit, reviewable collision parts in module-local coordinates.
MODULES = {
 'wall_solid_4m': ('wall_solid_4m_v03.glb', [((4,3.2,.24),(0,1.6,0))]),
 'wall_window_4m': ('wall_window_4m_v03.glb', [((1.2,3.2,.24),(-1.4,1.6,0)),((1.2,3.2,.24),(1.4,1.6,0)),((1.6,.9,.24),(0,.45,0)),((1.6,.95,.24),(0,2.725,0))]),
 'wall_doorway_4m': ('wall_doorway_4m_v03.glb', [((1.3,3.2,.24),(-1.35,1.6,0)),((1.3,3.2,.24),(1.35,1.6,0)),((1.4,.7,.24),(0,2.85,0))]),
 'wall_garage_4m': ('wall_garage_4m_v03.glb', [((4,3.2,.24),(0,1.6,0))]),
 'floor_slab_4m': ('floor_slab_4m_v03.glb', [((3.98,.22,3.98),(0,-.11,0))]),
 'roof_panel_4m': ('roof_panel_4m_v03.glb', [((4,.32,4),(0,0,0))]),
 'industrial_workbench': ('industrial_workbench_v03.glb', [((2.18,.97,.76),(0,.485,0))]),
 'electrical_cabinet': ('electrical_cabinet_v03.glb', [((.75,1.88,.38),(0,.94,0))]),
}
def vec(p):return 'Vector3('+', '.join(str(float(v)) if isinstance(v,float) else str(v) for v in p)+')'
for basename,(glb,parts) in MODULES.items():
    lines=['[gd_scene load_steps=%d format=3]'%(2+len(parts)),'',f'[ext_resource type="PackedScene" path="{G}{glb}" id="1_mesh"]','']
    for i,(size,center) in enumerate(parts):
        lines+= [f'[sub_resource type="BoxShape3D" id="Collider{i}"]',f'size = {vec(size)}','']
    lines+= [f'[node name="{basename}" type="Node3D"]','','[node name="Visual" parent="." instance=ExtResource("1_mesh")]','', '[node name="Solid" type="StaticBody3D" parent="."]','']
    for i, (size,center) in enumerate(parts):
        lines += [f'[node name="Collision{i}" type="CollisionShape3D" parent="Solid"]',f'position = {vec(center)}',f'shape = SubResource("Collider{i}")','']
    (SC/(basename+'.tscn')).write_text('\n'.join(lines))

# Build a genuine 12m x 8m maintenance building with complete collision and roof.
# Every section is an instance of a reusable 4m module.
scene=[f'[gd_scene load_steps=12 format=3]','']
for idx,name in enumerate(MODULES,1):
    scene+=[f'[ext_resource type="PackedScene" path="{S}{name}.tscn" id="{idx}_{name}"]']
scene += ['[ext_resource type="PackedScene" path="res://assets/crossroads_v02/scenes/steel_door_v02.tscn" id="9_door"]', '[ext_resource type="PackedScene" path="res://assets/crossroads_v02/scenes/damaged_wall_v02.tscn" id="10_damaged"]','', '[node name="MaintenanceStation" type="Node3D"]','', '[node name="Foundation" type="Node3D" parent="."]','']

def instance(node,parent,res,position,rotation=None):
    scene.extend([f'[node name="{node}" parent="{parent}" instance=ExtResource("{res}")]'])
    scene.append(f'position = {vec(position)}')
    if rotation is not None: scene.append(f'rotation = {vec(rotation)}')
    scene.append('')
for i,x in enumerate((-4,0,4)):
    for j,z in enumerate((-2,2)):
        instance(f'Floor_{i}{j}','Foundation','5_floor_slab_4m',(x,0,z))
scene+= ['[node name="ExteriorWalls" type="Node3D" parent="."]','']
# Facing exterior +Z: front x=-4 window, x=0 sealed garage, x=4 person-door.
for x,name in [(-4,'wall_window_4m'),(0,'wall_garage_4m'),(4,'wall_doorway_4m')]:
    idx=['wall_solid_4m','wall_window_4m','wall_doorway_4m','wall_garage_4m'].index(name)+1
    instance(f'Front_{int(x)+4}','ExteriorWalls',f'{idx}_{name}',(x,0,4))
# Back + sides
for x,name in [(-4,'wall_solid_4m'),(0,'wall_window_4m'),(4,'damaged_wall')]:
    resource = '10_damaged' if name == 'damaged_wall' else str({'wall_solid_4m':1,'wall_window_4m':2}[name]) + '_' + name
    instance(f'Rear_{int(x)+4}','ExteriorWalls',resource,(x,0,-4),(0,3.14159265,0))
for z in (-2,2):
    instance(f'Left_{z}','ExteriorWalls','1_wall_solid_4m',(-6,0,z),(0,-1.570796327,0))
    instance(f'Right_{z}','ExteriorWalls','1_wall_solid_4m',(6,0,z),(0,1.570796327,0))
scene += ['[node name="Roof" type="Node3D" parent="."]','']
for i,x in enumerate((-4,0,4)):
    for j,z in enumerate((-2,2)):
        instance(f'Roof_{i}{j}','Roof','6_roof_panel_4m',(x,3.28,z))
scene += ['[node name="Equipment" type="Node3D" parent="."]','']
instance('WorkBench','Equipment','7_industrial_workbench',(-4.2,.01,-2.95))
instance('ElectricalCabinet','Equipment','8_electrical_cabinet',(4.3,.01,-3.68))
# Hinge-left at x=4-.61, centered within doorway, swing inward on +Y rotation.
instance('PersonnelDoor','Equipment','9_door',(3.39,.0,4.0))
# Override hinge config on inherited nested node; set swing positive into building.
scene+= ['[node name="DoorHinge" parent="Equipment/PersonnelDoor" index="0"]','swing_direction = 1.0','','[editable path="Equipment/PersonnelDoor"]','']
(SC/'maintenance_station_v03.tscn').write_text('\n'.join(scene))

# A realistic-inspection stage that does not modify playable-world logic.
preview='''[gd_scene load_steps=8 format=3]

[ext_resource type="PackedScene" path="res://assets/crossroads_v03/scenes/maintenance_station_v03.tscn" id="1_station"]
[ext_resource type="Script" path="res://assets/crossroads_v03/scripts/walkthrough_player.gd" id="2_walk"]
[ext_resource type="Script" path="res://assets/crossroads_v03/scripts/inspection_stage.gd" id="3_stage"]

[sub_resource type="BoxMesh" id="GroundMesh"]
size = Vector3(52, 0.20, 52)

[sub_resource type="BoxShape3D" id="GroundShape"]
size = Vector3(52, 0.20, 52)

[sub_resource type="CapsuleShape3D" id="PlayerShape"]
radius = 0.31
height = 1.75

[sub_resource type="Environment" id="SkyEnvironment"]
background_mode = 1
background_color = Color(0.34, 0.36, 0.34, 1)
ambient_light_source = 1
ambient_light_color = Color(0.65, 0.68, 0.69, 1)
ambient_light_energy = 0.65

[node name="CrossroadsMaintenanceInspection" type="Node3D"]
script = ExtResource("3_stage")

[node name="WorldEnvironment" type="WorldEnvironment" parent="."]
environment = SubResource("SkyEnvironment")

[node name="Daylight" type="DirectionalLight3D" parent="."]
rotation = Vector3(-0.9, -0.6, 0)
light_energy = 0.92
shadow_enabled = true

[node name="Ground" type="MeshInstance3D" parent="."]
position = Vector3(0, -0.20, 0)
mesh = SubResource("GroundMesh")

[node name="GroundCollision" type="StaticBody3D" parent="."]

[node name="CollisionShape3D" type="CollisionShape3D" parent="GroundCollision"]
position = Vector3(0, -0.20, 0)
shape = SubResource("GroundShape")

[node name="Station" parent="." instance=ExtResource("1_station")]

[node name="Player" type="CharacterBody3D" parent="."]
position = Vector3(3.95, 0.0, 9.0)
script = ExtResource("2_walk")

[node name="PlayerCollider" type="CollisionShape3D" parent="Player"]
position = Vector3(0, 0.88, 0)
shape = SubResource("PlayerShape")

[node name="Head" type="Node3D" parent="Player"]
position = Vector3(0, 1.58, 0)

[node name="Camera3D" type="Camera3D" parent="Player/Head"]
current = true
fov = 76.0

[node name="InteractRay" type="RayCast3D" parent="Player/Head/Camera3D"]
target_position = Vector3(0, 0, -2.8)
collision_mask = 1

[node name="UI" type="CanvasLayer" parent="."]

[node name="Instructions" type="Label" parent="UI"]
offset_left = 15.0
offset_top = 14.0
offset_right = 850.0
offset_bottom = 120.0
text = "ASHFALL | CROSSROADS v0.3\\nWASD move  •  Mouse look  •  E interact  •  R roof  •  ESC mouse"

[node name="TargetHint" type="Label" parent="UI"]
offset_left = 15.0
offset_top = 115.0
offset_right = 650.0
offset_bottom = 160.0
text = ""
'''
(SC/'walkthrough_v03.tscn').write_text(preview)
print('Exported',len(MODULES),'module scenes, station and walkthrough stage')
