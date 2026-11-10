extends Node3D
## Gallery-only names, platforms, and viewing controls. WorldAsset is the ordinary prop.
var selected_index: int = -1
var target := Vector3.ZERO
var distance := 2.0
var yaw := .45
var pitch := .38
var radius := 1.0
var dragging := false
var cells: Array[Node] = []
var heading: Label
var detail: Label
var help: Label
var button_row: HBoxContainer
var ui: CanvasLayer

func _ready() -> void:
 cells=$Displays.get_children()
 build_interface()
 show_overview()

func build_interface() -> void:
 ui=CanvasLayer.new();ui.name="GalleryInterface";add_child(ui)
 var top:=PanelContainer.new();top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE);top.offset_bottom=112
 var panel_style:=StyleBoxFlat.new();panel_style.bg_color=Color(0.055,.075,.09,.94);panel_style.content_margin_left=24;panel_style.content_margin_top=14;panel_style.content_margin_bottom=12
 top.add_theme_stylebox_override("panel",panel_style);ui.add_child(top)
 var v:=VBoxContainer.new();top.add_child(v)
 heading=Label.new();heading.add_theme_font_size_override("font_size",24);heading.modulate=Color("e6dfcd");v.add_child(heading)
 detail=Label.new();detail.add_theme_font_size_override("font_size",16);detail.modulate=Color("a7c4c4");v.add_child(detail)
 help=Label.new();help.text="1–7 inspect  •  Drag to orbit  •  Wheel to zoom  •  ← / → browse  •  H overview";help.add_theme_font_size_override("font_size",15);help.modulate=Color("899b9e");v.add_child(help)
 var bottom:=PanelContainer.new();bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE);bottom.offset_top=-74
 bottom.add_theme_stylebox_override("panel",panel_style.duplicate());ui.add_child(bottom)
 button_row=HBoxContainer.new();button_row.alignment=BoxContainer.ALIGNMENT_CENTER;button_row.add_theme_constant_override("separation",8);bottom.add_child(button_row)
 var home:=Button.new();home.text="Overview";home.focus_mode=Control.FOCUS_NONE;home.pressed.connect(show_overview);button_row.add_child(home)
 var short_names:=["Timber","Shovel","Steel","Firewood","Mushrooms","Grass","Stones"]
 for i in cells.size():
  var button:=Button.new();button.text="%02d  %s"%[i+1,short_names[i]];button.custom_minimum_size=Vector2(126,40);button.focus_mode=Control.FOCUS_NONE;button.pressed.connect(focus_asset.bind(i));button_row.add_child(button)

func asset_bounds(node: Node3D) -> AABB:
 var bounds:=AABB();var first:=true
 for item in node.find_children("*","MeshInstance3D",true,false):
  var mesh:=item as MeshInstance3D
  var bb: AABB=node.global_transform.affine_inverse()*mesh.global_transform*mesh.get_aabb()
  bounds=bb if first else bounds.merge(bb);first=false
 return bounds

func show_overview() -> void:
 selected_index=-1
 for cell in cells:
  cell.show();cell.get_node("DisplayPlinth").show();cell.get_node("GalleryName").show();cell.get_node("GallerySize").show()
 $Camera.projection=Camera3D.PROJECTION_ORTHOGONAL;$Camera.size=8.2
 $Camera.position=Vector3(0,10.6,12.8);$Camera.look_at(Vector3(0,0.05,0))
 heading.text="ASHFALL  /  FIELD DRESSING — 7 ASSETS"
 detail.text="Shown at world scale. Select a numbered prop for a close view."

func focus_asset(index: int) -> void:
 selected_index=posmod(index,cells.size())
 for i in cells.size():
  cells[i].visible=i==selected_index
  cells[i].get_node("DisplayPlinth").hide();cells[i].get_node("GalleryName").hide();cells[i].get_node("GallerySize").hide()
 var cell:Node3D=cells[selected_index]
 var asset:Node3D=cell.get_node("WorldAsset")
 var bb:=asset_bounds(asset)
 target=asset.global_transform*bb.get_center()
 radius=maxf(bb.size.length()*.5,.1)
 target.y+=radius*.18
 distance=radius*3.65;yaw=.42;pitch=.30
 $Camera.projection=Camera3D.PROJECTION_PERSPECTIVE;$Camera.fov=42;$Camera.near=.008
 update_camera()
 heading.text="%02d  /  %s"%[selected_index+1,cell.get_meta("title")]
 detail.text="World scene: res://scenes/extra_dressing/%s.tscn"%cell.get_meta("id")

func update_camera() -> void:
 var dir:=Vector3(sin(yaw)*cos(pitch),sin(pitch),cos(yaw)*cos(pitch))
 $Camera.global_position=target+dir*distance
 $Camera.look_at(target)

func _unhandled_input(event: InputEvent) -> void:
 if event is InputEventKey and event.pressed and not event.echo:
  if event.keycode>=KEY_1 and event.keycode<=KEY_7:focus_asset(event.keycode-KEY_1)
  elif event.keycode==KEY_H or event.keycode==KEY_HOME:show_overview()
  elif event.keycode==KEY_RIGHT:focus_asset(selected_index+1)
  elif event.keycode==KEY_LEFT:focus_asset(selected_index-1)
 elif event is InputEventMouseButton:
  if event.button_index==MOUSE_BUTTON_LEFT:dragging=event.pressed
  if selected_index>=0 and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
   distance=clampf(distance*(.88 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1.12),radius*.8,radius*12.0);update_camera()
 elif event is InputEventMouseMotion and dragging and selected_index>=0 and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
  yaw-=event.relative.x*.009;pitch=clampf(pitch+event.relative.y*.007,-.15,1.35);update_camera()


