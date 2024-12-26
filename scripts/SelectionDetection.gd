extends CollisionShape3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _input_event(_camera: Camera3D, event: InputEvent, _event_position: Vector3, normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		get_parent().emit_signal("face_clicked", normal)
	elif event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_RIGHT:
		get_parent().emit_signal("selected")
