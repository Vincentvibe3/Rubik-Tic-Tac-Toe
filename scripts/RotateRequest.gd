extends StaticBody3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	mouse_entered.connect(_mouse_enter)
	mouse_exited.connect(_mouse_exit)

func _mouse_enter() -> void:
	get_parent().find_child("Outline").visible = true

func _mouse_exit() -> void:
	get_parent().find_child("Outline").visible = false

func _input_event(_camera: Camera3D, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		get_node("/root/Main/CubeGen").emit_signal("rotateRequest", get_parent().get_meta("dir"))
