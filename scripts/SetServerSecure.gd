extends CheckButton

var secure = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	secure = !GameState.isInsecure
	button_pressed = secure
	toggled.connect(_on_press)

func _on_press(toggle) -> void:
	secure = toggle
