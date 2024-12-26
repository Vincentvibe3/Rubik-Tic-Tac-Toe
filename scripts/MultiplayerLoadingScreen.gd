extends PanelContainer

	
func _process(delta: float) -> void:
	if self.visible:
		if !GameState.showMultiplayerLoadingScreen:
			self.visible = false
	else:
		set_process(false)