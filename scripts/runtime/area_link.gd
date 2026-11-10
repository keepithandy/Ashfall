extends StaticBody3D
## Editable, reusable connection between expedition areas.
@export var destination := "relay"
@export var arrival := Vector3.ZERO
@export var heading := 0.0
@export var requires_diagnostic := false

func _ready() -> void:
	set_meta("interaction", "area_link")
