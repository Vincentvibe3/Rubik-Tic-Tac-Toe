extends LineEdit


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	text = GameState.serverAddress
