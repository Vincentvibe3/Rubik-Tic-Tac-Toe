extends PanelContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameState.inputBlocker = self


func block_input():
	self.visible = true

func allow_input():
	self.visible = false