extends AudioStreamPlayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameState.bgm = self
	finished.connect(_restart_bgm)
	tree_exiting.connect(_on_exit)

func _on_exit():
	GameState.bgm = null
	stop()

func _restart_bgm():
	play()

func _process(_delta: float) -> void:
	if GameState.muted:
		self.volume_db = linear_to_db(0.0)
	else:
		self.volume_db = linear_to_db(0.3)
