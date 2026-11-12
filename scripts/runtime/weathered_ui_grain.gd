extends Control
## Fixed-seed, resolution-aware grime and material wear for 2D surfaces.
## Paint only when Godot requests a redraw: no frame-by-frame particle cost.
@export var paper_mode: bool = true
@export_range(20, 300, 10) var marks: int = 130


func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    resized.connect(queue_redraw)


func _draw() -> void:
    var w := size.x
    var h := size.y
    if w < 16.0 or h < 16.0:
        return
    var rng := RandomNumberGenerator.new()
    rng.seed = 23711 if paper_mode else 23713
    var scratch := Color(0.27, 0.22, 0.16, 0.10) if paper_mode else Color(0.75, 0.69, 0.54, 0.055)
    var faded := Color(0.15, 0.14, 0.10, 0.045) if paper_mode else Color(0.85, 0.82, 0.67, 0.025)
    var line_color := Color(0.28, 0.26, 0.21, 0.16) if paper_mode else Color(0.75, 0.71, 0.58, 0.12)
    # Quiet irregular flecks; subtle enough that text remains crisp.
    for i in range(marks):
        var x := rng.randf_range(6.0, w - 6.0)
        var y := rng.randf_range(6.0, h - 6.0)
        var length := rng.randf_range(1.0, 6.0)
        draw_rect(Rect2(x, y, length, rng.randf_range(0.5, 1.7)), scratch if i % 3 == 0 else faded)
    # Stained edges, not a repeating digital pattern.
    for side in range(3):
        var padding := float(4 + side * 4)
        var opacity := 0.07 / float(side + 1)
        var tint := Color(0.14, 0.12, 0.09, opacity) if paper_mode else Color(0.75, 0.64, 0.49, opacity * 0.6)
        draw_rect(Rect2(padding, padding, w - padding * 2.0, h - padding * 2.0), tint, false, 1.0)
    # Two corner wear marks and an uneven old binding edge.
    draw_line(Vector2(12.0, h - 13.0), Vector2(29.0, h - 13.0), line_color, 1.0)
    draw_line(Vector2(w - 32.0, 13.0), Vector2(w - 12.0, 13.0), line_color, 1.0)
    if paper_mode:
        var binding_x := minf(24.0, w * 0.06)
        draw_line(Vector2(binding_x, 11.0), Vector2(binding_x, h - 11.0), line_color, 1.0)
        for i in range(4):
            var hole_y := (float(i) + 0.5) * h / 4.0
            draw_circle(Vector2(binding_x - 8.0, hole_y), 3.1, Color(0.19, 0.17, 0.13, 0.33))
            draw_circle(Vector2(binding_x - 8.0, hole_y), 1.6, Color(0.11, 0.10, 0.07, 0.22))
