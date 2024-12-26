extends VBoxContainer


class_name RoomListing

var connectionRequest

signal connectToGame()

func _ready() -> void:
	connectToGame.connect(_on_connect)

func _on_connect():
	connectionRequest.emit(roomName, id, private)

var roomName = ""
var id = ""
var private = false

func display_info():
	%RoomName.text = roomName
	%RoomID.text = id
	if private:
		%Privacy.text = "Private"
	else:
		%Privacy.text = "Public"