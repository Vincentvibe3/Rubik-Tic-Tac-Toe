extends VBoxContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	%GameBrowserHTTP.load_list()
