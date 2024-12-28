extends PanelContainer

	
func _process(_delta: float) -> void:
	if self.visible:
		if !GameState.showMultiplayerLoadingScreen:
			self.visible = false
	else:
		set_process(false)