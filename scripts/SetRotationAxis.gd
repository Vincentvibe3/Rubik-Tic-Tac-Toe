extends Button

var current_axis = 0
var axes = ["x", "y", "z"]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pressed.connect(_on_press)

func _on_press() -> void:
	current_axis=(current_axis+1)%3
	get_node("/root/Main/CubeGen").emit_signal("setRotationAxis", axes[current_axis])