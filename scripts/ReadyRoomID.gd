extends Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if GameState.room_id != null:
		self.text = GameState.room_id
		set_process(false)
	
func _process(_delta: float) -> void:
	if self.visible:
		if GameState.room_id != null:
			self.text = GameState.room_id
			set_process(false)
	else:
		set_process(false)