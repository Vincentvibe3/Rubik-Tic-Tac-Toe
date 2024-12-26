extends Node3D

class_name AutoCubeController

var cube

var axes = ["x", "y", "z"]
var directions = ["R", "L"]
var gameCubeAxes = ["x","y"]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	randomize()
	cube = CubeGenerator.new()
	cube.auto = true
	add_child(cube)
	_on_rotate_done()
	_on_game_cube_rotate_done()
	cube.rotateDone.connect(_on_rotate_done)
	cube.gameCubeRotationDone.connect(_on_game_cube_rotate_done)

func _on_game_cube_rotate_done():
	cube._on_rotate_cube(randi()%360, gameCubeAxes[randi()%2])

func _on_rotate_done():
	cube._on_select(cube.cubes[randi()%(len(cube.cubes))])
	cube._on_set_rotation_axis(axes[randi()%3])
	cube._on_rotate_request(directions[randi()%2])
