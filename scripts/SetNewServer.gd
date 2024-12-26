extends Button


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pressed.connect(_on_press)

func _on_press() -> void:
	GameState.isInsecure = !%SecureButton.secure
	GameState.serverAddress = %ServerAddress.text
	%GameBrowser.visible = true
	%RoomCreation.visible = false
	%PrivateGameEntry.visible = false
	%ServerEntry.visible = false
	%GameBrowserHTTP.load_list()