extends HTTPRequest

class_name RoomBrowser

signal connectionRequest(roomName, id, private)
signal startConnection(password)

var is_loading = false

var pending_room_name
var pending_id

func _on_start_connection(password):
	GameState.is_multiplayer = true
	GameState.is_host = false
	GameState.room_name = pending_room_name
	GameState.room_id = pending_id
	GameState.room_password = password
	get_tree().change_scene_to_file("res://scenes/GameOnline.tscn")

func _on_connection_request(roomName, id, private):
	pending_room_name = roomName
	pending_id = id
	if private:
		%GameBrowser.visible = false
		%RoomCreation.visible = false
		%PrivateGameEntry.visible = true
	else:
		_on_start_connection(null)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	preload("res://scenes/Room.tscn")
	request_completed.connect(_on_request_completed)
	connectionRequest.connect(_on_connection_request)
	startConnection.connect(_on_start_connection)

func load_list():
	if is_loading:
		self.cancel_request()

	for child in %GameList.get_children():
		if child is not Label:
			%GameList.remove_child(child)
	%LoadErrorMessage.text = "Loading..."
	%LoadErrorMessage.visible = true
	if GameState.isInsecure:
		request("http://"+GameState.serverAddress+"/rooms")
	else:
		request("https://"+GameState.serverAddress+"/rooms")
	is_loading = true

func _on_request_completed(result, response_code, _headers, body):
	if result == RESULT_SUCCESS:
		if response_code == 200:
			var json = JSON.parse_string(body.get_string_from_utf8())
			if json:
				for game in json:
					var room = load("res://scenes/Room.tscn").instantiate()
					room.roomName = game["name"]
					room.id = game["room_id"]
					room.private = game["is_password_protected"]
					room.display_info()
					room.connectionRequest = connectionRequest
					%GameList.add_child(room)
				%LoadErrorMessage.visible = false
			else:
				%LoadErrorMessage.text = "No games found" 
				%LoadErrorMessage.visible = true
		else:
			%LoadErrorMessage.text = "Failed to load games. Error:" + str(response_code)
			%LoadErrorMessage.visible = true
	else:
		%LoadErrorMessage.text = "Failed to connect to server"
		%LoadErrorMessage.visible = true
	is_loading = false
