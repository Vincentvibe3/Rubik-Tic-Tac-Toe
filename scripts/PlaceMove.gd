extends Button


func _ready() -> void:
	pressed.connect(_on_press)

func _on_press() -> void:
	GameState.mark_selection()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if GameState.is_multiplayer:
		if GameState.is_host:
			text = "Place O"
		else:
			text = "Place X"
	else:
		if GameState.currentPlayer == 0:
			text = "Place O"
		else:
			text = "Place X"

