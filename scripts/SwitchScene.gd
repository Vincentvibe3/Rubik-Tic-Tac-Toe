extends Button


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pressed.connect(_on_press)

func _on_press() -> void:
	get_tree().change_scene_to_file("res://scenes/Game.tscn")