extends Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var connection 
	if GameState.is_host:
		connection = GameConnection.createHost(GameState.room_name, GameState.room_password)
	else:
		connection = GameConnection.createPlayer(GameState.room_password, GameState.room_id)
	add_child(connection)
