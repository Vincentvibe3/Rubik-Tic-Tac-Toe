extends Slider


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameState.sliders.append(self)
	value_changed.connect(_on_value_change)

func _on_value_change(val:float):
	get_node("/root/Main/CubeGen").emit_signal("setCubeRotation", val, get_meta("axis"))
