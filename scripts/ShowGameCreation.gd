extends Button

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pressed.connect(_on_press)

func _on_press() -> void:
	%GameBrowser.visible = false
	%RoomCreation.visible = false
	%PrivateGameEntry.visible = false
	%ServerEntry.visible = false
	get_node(get_meta("menu")).visible = true