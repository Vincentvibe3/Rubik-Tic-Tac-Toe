extends AudioStreamPlayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	preload("res://sounds/marker_sound.ogg")
	preload("res://sounds/explosion.mp3")
	preload("res://sounds/wood.ogg")
	GameState.audio = self
	tree_exiting.connect(_on_exit)

func _on_exit():
	GameState.audio = null
	stop()

func _process(_delta: float) -> void:
	if GameState.muted:
		self.volume_db = linear_to_db(0.0)
	else:
		self.volume_db = linear_to_db(1.0)

func play_wood():
	self.stream = load("res://sounds/wood.ogg")
	play()

func play_explosion():
	self.stream = load("res://sounds/explosion.mp3")
	play()

func play_marker():
	self.stream = load("res://sounds/marker_sound.ogg")
	play()
