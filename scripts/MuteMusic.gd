extends Button

func _ready() -> void:
	pressed.connect(_on_press)

func _on_press() -> void:
	GameState.toggle_mute()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if GameState.muted:
		text = "Unmute"
	else:
		text = "Mute"
