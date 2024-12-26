extends Button

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	toggled.connect(_on_press)

func _on_press(toggle) -> void:
	if !GameState.gameStarted:
		GameState.startGame()

	if toggle:
		%TutorialScreen.visible = true
		self.text = "Close tutorial [ESC]"
	else:
		%TutorialScreen.visible = false
		self.text = "Show tutorial [ESC]"
