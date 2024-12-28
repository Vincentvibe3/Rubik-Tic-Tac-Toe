extends Node

class_name GameConnection

var socket = WebSocketPeer.new()
var is_host = false
var roomName = ""
var roomPassword
var id
var active = true
var actions = []

var timer = Timer.new()
var lastKeepAlive
var lastPlayerMoveTime

var keepAliveTimeout = 2
var idleTimeout = 5


static func createHost(rName, password):
	return GameConnection.new(rName, password, null, true)

static func createPlayer(password, rId):
	return GameConnection.new(null, password, rId, false)

func send(message):
	actions.append(message)

func _init(rName, password, rId, host) -> void:
	roomName = rName
	is_host = host
	roomPassword = password
	id = rId

func _ready():
	GameState.wshandler = self
	add_child(timer)
	timer.timeout.connect(_queue_keep_alive)
	lastKeepAlive = null
	lastPlayerMoveTime = null
	# Initiate connection to the given URL.
	var ws_url
	if GameState.isInsecure:
		ws_url = "ws://"+GameState.serverAddress+"/connect"
	else:
		ws_url = "wss://"+GameState.serverAddress+"/connect"
	var err = socket.connect_to_url(ws_url)
	if err != OK:
		print("Unable to connect")
		set_process(false)
		get_tree().change_scene_to_file("res://scenes/RoomBrowser.tscn")
	else:
		if !is_host:
			send_room_connect()
		else:
			send_room_creation()
	
func close():
	socket.close(3005, "disconnect")

func send_room_creation():
	var payload = {
		"name":roomName,
	}
	if roomPassword != null:
		payload["password"] = roomPassword
	send({"id":0, "payload":payload})

func send_room_connect():
	var payload = {
		"room_id":id,
	}
	if roomPassword != null:
		payload["password"] = roomPassword
	send({"id":1, "payload":payload})

func _queue_keep_alive():
	send({"id":5, "payload":{}})

func send_mark(coord, local_normal):
	lastPlayerMoveTime = Time.get_ticks_msec()
	send({"id":2, "payload":{"coord":coord, "normal":[local_normal.x, local_normal.y, local_normal.z]}})

func send_rotate(axis, coord, direction):
	lastPlayerMoveTime = Time.get_ticks_msec()
	send({"id":3, "payload":{"axis":axis, "coord":coord, "direction":direction}})

func send_reset():
	lastPlayerMoveTime = Time.get_ticks_msec()
	send({"id":4,"payload":{}})

func _process(_delta):
	# Call this in _process or _physics_process. Data transfer and state updates
	# will only happen when calling this function.
	socket.poll()

	# get_ready_state() tells you what state the socket is in.
	var state = socket.get_ready_state()

	# WebSocketPeer.STATE_OPEN means the socket is connected and ready
	# to send and receive data.
	if state == WebSocketPeer.STATE_OPEN:
		if lastKeepAlive != null:
			if Time.get_ticks_msec()-lastKeepAlive > keepAliveTimeout*60000:
				socket.close(3007, "inactive client detected")
		if lastPlayerMoveTime != null:
			if Time.get_ticks_msec()-lastPlayerMoveTime > idleTimeout*60000:
				socket.close(3008, "Inactive user detected")
		while socket.get_available_packet_count():
			var data = socket.get_packet().get_string_from_utf8()
			var json = JSON.parse_string(data)
			if "id" not in json or "payload" not in json:
				socket.close(3006, "client received invalid data")
				continue
			var packetId = json["id"]
			var payload = json["payload"]
			if packetId == 0:
				lastKeepAlive = Time.get_ticks_msec()
				lastPlayerMoveTime = Time.get_ticks_msec()
				timer.start(60)
				GameState.showMultiplayerLoadingScreen = false
			elif packetId == 1:
				if "id" not in payload:
					socket.close(3006, "client received invalid data")
					continue
				GameState.room_id = payload["id"]
			elif packetId == 2:
				if "coord" not in payload || "normal" not in payload:
					socket.close(3006, "client received invalid data")
					continue
				var normal = payload["normal"]
				lastPlayerMoveTime = Time.get_ticks_msec()
				GameState.mark_face(payload["coord"], Vector3(normal[0], normal[1], normal[2]))
			elif packetId == 3:
				if "axis" not in payload || "coord" not in payload || "direction" not in payload:
					socket.close(3006, "client received invalid data")
					continue
				lastPlayerMoveTime = Time.get_ticks_msec()
				GameState.rotate_cube(payload["axis"], payload["coord"], payload["direction"])
			elif packetId == 4:
				if "id" not in json or "payload" not in json:
					socket.close(3006, "client received invalid data")
					continue
				GameState.roundEnded = false
				GameState.reset()
			elif packetId == 5:
				lastKeepAlive = Time.get_ticks_msec()
			else:
				socket.close(3006, "client received invalid data")
		while actions:
			socket.send_text(JSON.stringify(actions.pop_front()))

	# WebSocketPeer.STATE_CLOSING means the socket is closing.
	# It is important to keep polling for a clean close.
	elif state == WebSocketPeer.STATE_CLOSING:
		pass

	# WebSocketPeer.STATE_CLOSED means the connection has fully closed.
	# It is now safe to stop polling.
	elif state == WebSocketPeer.STATE_CLOSED:
		# The code will be -1 if the disconnection was not properly notified by the remote peer.
		var code = socket.get_close_code()
		var reason = socket.get_close_reason()
		active = false
		if code == 3001:
			var errorScreen = load("res://scenes/ErrorScreen.tscn").instantiate()
			errorScreen.errorText = "Server received invalid data"
			var oldScene = get_tree().current_scene
			var tree = get_tree()
			tree.root.remove_child(oldScene)
			tree.root.add_child(errorScreen)
			tree.current_scene = errorScreen
		elif code == 3002:
			var errorScreen = load("res://scenes/ErrorScreen.tscn").instantiate()
			errorScreen.errorText = "Wrong Password"
			var oldScene = get_tree().current_scene
			var tree = get_tree()
			tree.root.remove_child(oldScene)
			tree.root.add_child(errorScreen)
			tree.current_scene = errorScreen

		elif code == 3003:
			var errorScreen = load("res://scenes/ErrorScreen.tscn").instantiate()
			errorScreen.errorText = "Game does not exist"
			var oldScene = get_tree().current_scene
			var tree = get_tree()
			tree.root.remove_child(oldScene)
			tree.root.add_child(errorScreen)
			tree.current_scene = errorScreen
		elif code == 3004:
			var errorScreen = load("res://scenes/ErrorScreen.tscn").instantiate()
			errorScreen.errorText = "Game was closed"
			var oldScene = get_tree().current_scene
			var tree = get_tree()
			tree.root.remove_child(oldScene)
			tree.root.add_child(errorScreen)
			tree.current_scene = errorScreen
		elif code == 3005:
			GameState.go_to_menu()
		elif code == 3006:
			var errorScreen = load("res://scenes/ErrorScreen.tscn").instantiate()
			errorScreen.errorText = "Game received invalid data"
			var oldScene = get_tree().current_scene
			var tree = get_tree()
			tree.root.remove_child(oldScene)
			tree.root.add_child(errorScreen)
			tree.current_scene = errorScreen
		elif code == 3007:
			var errorScreen = load("res://scenes/ErrorScreen.tscn").instantiate()
			errorScreen.errorText = "Lost connection to opponent game"
			var oldScene = get_tree().current_scene
			var tree = get_tree()
			tree.root.remove_child(oldScene)
			tree.root.add_child(errorScreen)
			tree.current_scene = errorScreen
		elif code == 3008:
			var errorScreen = load("res://scenes/ErrorScreen.tscn").instantiate()
			errorScreen.errorText = "Game closed due to inactivity"
			var oldScene = get_tree().current_scene
			var tree = get_tree()
			tree.root.remove_child(oldScene)
			tree.root.add_child(errorScreen)
			tree.current_scene = errorScreen
		else:
			var errorScreen = load("res://scenes/ErrorScreen.tscn").instantiate()
			errorScreen.errorText = "An error occurred"
			var oldScene = get_tree().current_scene
			var tree = get_tree()
			tree.root.remove_child(oldScene)
			tree.root.add_child(errorScreen)
			tree.current_scene = errorScreen
		print("WebSocket closed with code: %d. Clean: %s. Reason: %s" % [code, code != -1, reason])
		set_process(false) # Stop processing.
