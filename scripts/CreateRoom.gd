extends Button

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pressed.connect(_on_press)

func _on_press() -> void:
	GameState.is_multiplayer = true
	GameState.is_host = true
	GameState.room_name = %GameName.text

	var password = %GamePassword.text
	if !password.is_empty():
		GameState.room_password = %GamePassword.text
	get_tree().change_scene_to_file("res://scenes/GameOnline.tscn")
