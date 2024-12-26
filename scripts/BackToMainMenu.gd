extends Button

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pressed.connect(_on_press)

func _on_press() -> void:
	if !GameState.close_ws():
		GameState.go_to_menu()
