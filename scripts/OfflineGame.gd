extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameState.sliders.clear()
	GameState.is_multiplayer = false
