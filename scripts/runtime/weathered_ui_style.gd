extends RefCounted
## Ashfall 2.3's coherent, non-digital survival visual language.
## Canvas, oxidized steel, paper, ink and faded paint. No neon, rounded
## sci-fi controls, glass panels, or texture downloads.
const CANVAS := Color("22241e")
const CANVAS_DARK := Color("151813")
const CANVAS_RAISED := Color("35372c")
const LEATHER := Color("393126")
const PAPER := Color("c8bea3")
const PAPER_LIGHT := Color("e4dcc7")
const PAPER_DARK := Color("aaa084")
const INK := Color("25281e")
const FADED_INK := Color("665f4d")
const THREAD := Color("77735e")
const RUST := Color("8f6850")
const OXIDE := Color("64705e")
const DANGER := Color("9d5c4b")


static func panel(fill: Color = CANVAS, seam: Color = THREAD, border: int = 2, inset: int = 12) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = fill
    style.border_color = seam
    style.set_border_width_all(border)
    style.set_corner_radius_all(1)
    style.set_content_margin_all(inset)
    style.anti_aliasing = true
    return style


static func control_button(button: Button, light: bool = false) -> void:
    var surface := PAPER_DARK if light else CANVAS_RAISED
    var text_ink := INK if light else PAPER_LIGHT
    var muted_ink := FADED_INK if light else PAPER_DARK
    var edge := RUST if light else THREAD
    var normal := panel(surface, edge, 2, 6)
    var hover := panel(PAPER if light else Color("4b4a39"), OXIDE if light else PAPER_DARK, 2, 6)
    var down := panel(Color("9c9279") if light else LEATHER, RUST, 2, 6)
    var focused := panel(Color(0, 0, 0, 0), PAPER_LIGHT if light else PAPER, 2, 5)
    var disabled := panel(Color("8d8875") if light else Color("2b2c25"), Color("746e5b"), 1, 6)
    button.add_theme_stylebox_override("normal", normal)
    button.add_theme_stylebox_override("hover", hover)
    button.add_theme_stylebox_override("pressed", down)
    button.add_theme_stylebox_override("focus", focused)
    button.add_theme_stylebox_override("disabled", disabled)
    button.add_theme_color_override("font_color", text_ink)
    button.add_theme_color_override("font_hover_color", text_ink)
    button.add_theme_color_override("font_pressed_color", text_ink)
    button.add_theme_color_override("font_focus_color", text_ink)
    button.add_theme_color_override("font_disabled_color", muted_ink)
    button.add_theme_font_size_override("font_size", 14)
    button.add_theme_constant_override("h_separation", 8)
    button.custom_minimum_size.y = maxf(40.0, button.custom_minimum_size.y)


static func ink_label(label: Label, big: bool = false, dim: bool = false) -> void:
    label.add_theme_color_override("font_color", FADED_INK if dim else INK)
    label.add_theme_font_size_override("font_size", 22 if big else 14)


static func dark_label(label: Label, big: bool = false, dim: bool = false) -> void:
    label.add_theme_color_override("font_color", PAPER_DARK if dim else PAPER_LIGHT)
    label.add_theme_font_size_override("font_size", 22 if big else 14)


static func paper_texture(parent: Control, paper: bool = true) -> Control:
    var skin := Control.new()
    skin.name = "Weathering"
    skin.set_script(load("res://scripts/runtime/weathered_ui_grain.gd"))
    skin.set("paper_mode", paper)
    skin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    skin.mouse_filter = Control.MOUSE_FILTER_IGNORE
    # Overlay stays behind content, drawn without bitmap assets.
    parent.add_child(skin)
    parent.move_child(skin, 0)
    return skin
