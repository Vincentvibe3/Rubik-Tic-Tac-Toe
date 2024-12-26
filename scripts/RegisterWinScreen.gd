extends PanelContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameState.winScreen = self


func setWinText(text):
	%WinText.text = text