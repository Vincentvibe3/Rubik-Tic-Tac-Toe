extends Node

@export var errorText = ""

func _ready() -> void:
	set_text()

func set_text():
	%ErrorMessage.text = errorText

