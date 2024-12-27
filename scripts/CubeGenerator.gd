extends Node3D

class_name CubeGenerator

signal rotateRequest(direction)
signal rotateDone()
signal setCubeRotation(value: float, axis: String)
signal selection(coord)
signal setRotationAxis(axis: String)
signal gameCubeRotationDone()

var rotatingLayer = false
var rotationGroup = RotationGroup.new()
var targetCubeTransform
var tween
var current_selection
var cubes = []
var cubeSize
var currentRotationAxis = "x"
var auto = false
var isDragging = false

var lastRotationDirection = "L"

var x_rotation = 0
var y_rotation = 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_child(rotationGroup)
	preload("res://scenes/Cube.tscn")
	preload("res://scenes/Arrow.tscn")
	rotateRequest.connect(_on_rotate_request)
	rotateDone.connect(_on_rotate_done)
	setCubeRotation.connect(_on_rotate_cube)
	selection.connect(_on_select)
	setRotationAxis.connect(_on_set_rotation_axis)
	for i in range(3):
		for j in range(3):
			for k in range(3):
					
				if i == 1 and j == 1 and k == 1:
					continue
				var drawableCube = load("res://scenes/Cube.tscn").instantiate()
				drawableCube.cube_position = [k, j, i]
				drawableCube.cube_owner = self
				var size = drawableCube.getSize()
				cubeSize = size
				self.add_child(drawableCube)
				drawableCube.reset_position()
				cubes.append(drawableCube)
	GameState.setActiveGameCube(self)

func reset():
	resetLayer()
	for cube in cubes:
		cube.reset()

func resetSelection():
	if current_selection != null:
		current_selection.reset_selection()

func _on_select(cube):
	resetSelection()
	resetLayer()
	GameState.highlight_last_clicked()
	current_selection = cube
	cube.drawSelect()
	highlightLayer()
	render3DControls()

func resetLayer():
	if current_selection == null:
		return
	var selection_indices = current_selection.cube_position
	if currentRotationAxis == "y":
		var index = selection_indices[2]
		for child in cubes:
			var coord = child.cube_position;
			if coord[2] == index:
				child.reset_color()

	elif currentRotationAxis == "z":
		var index = selection_indices[1]
		for child in cubes:
			var coord = child.cube_position;
			if coord[1] == index:
				child.reset_color()

	elif currentRotationAxis == "x":
		var index = selection_indices[0]
		for child in cubes:
			var coord = child.cube_position;
			if coord[0] == index:
				child.reset_color()

func highlightLayer():
	var selection_indices = current_selection.cube_position
	if currentRotationAxis == "y":
		var index = selection_indices[2]
		for child in cubes:
			var coord = child.cube_position;
			if coord == selection_indices:
				child.highlight(GameState.selectionMaterial)
			elif coord[2] == index:
				child.highlight(GameState.highlightMaterial)

	elif currentRotationAxis == "z":
		var index = selection_indices[1]
		for child in cubes:
			var coord = child.cube_position;
			if coord == selection_indices:
				child.highlight(GameState.selectionMaterial)
			elif coord[1] == index:
				child.highlight(GameState.highlightMaterial)

	elif currentRotationAxis == "x":
		var index = selection_indices[0]
		for child in cubes:
			var coord = child.cube_position;
			if coord == selection_indices:
				child.highlight(GameState.selectionMaterial)
			elif coord[0] == index:
				child.highlight(GameState.highlightMaterial)

func render3DControls():
	if !auto:
		%RotateControls.set_active_axis(currentRotationAxis)
		%ControlGroup.visible = true
		%RotateControlsHint.visible = false

func hide3DControls():
	if !auto:
		%ControlGroup.visible = false
		%RotateControlsHint.visible = true

func _on_set_rotation_axis(axis: String):
	if current_selection != null:
		resetLayer()
	currentRotationAxis = axis
	GameState.highlight_last_clicked()
	highlightLayer()
	render3DControls()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_MIDDLE:
		isDragging = true
	if event is InputEventMouseMotion:
		if isDragging:
			_rotate_drag(event.velocity.x, event.velocity.y)
			
	if event is InputEventMouseButton and event.is_released() and event.button_index == MOUSE_BUTTON_MIDDLE:
		isDragging = false

func _rotate_drag(x_delta:float, y_delta:float):
	var y_rotation_delta=y_delta*0.001
	var x_rotation_delta=x_delta*0.001
	# tween = get_tree().create_tween()
	targetCubeTransform = self.global_transform.rotated(Vector3(0, 1, 0).normalized(), x_rotation_delta)
	targetCubeTransform = targetCubeTransform.rotated(Vector3(-1, 0, 1).normalized(), y_rotation_delta)
	self.global_transform = targetCubeTransform.orthonormalized()
	# tween.tween_property(self, "global_transform", targetCubeTransform, 0.25).set_ease(Tween.EASE_OUT)
	# tween.connect("finished", func (): gameCubeRotationDone.emit())

func _on_rotate_cube(value: float, axis: String):
	if tween:
		tween.kill()
	if axis == "x":
		x_rotation = 2 * PI / 360 * value
	elif axis == "y":
		y_rotation = 2 * PI / 360 * value
	tween = get_tree().create_tween()
	targetCubeTransform = Transform3D.IDENTITY.rotated(Vector3(0, 1, 0).normalized(), x_rotation)
	targetCubeTransform = targetCubeTransform.rotated(Vector3(-1, 0, 1).normalized(), y_rotation)
	tween.tween_property(self, "global_transform", targetCubeTransform, 0.5).set_ease(Tween.EASE_OUT)
	tween.connect("finished", func (): gameCubeRotationDone.emit())
	
func rotate_indices(axis_1: int, axis_2: int, coord):
	if coord[axis_1] == 0 and coord[axis_2] == 0:
		coord[axis_1] = 2
		coord[axis_2] = 0
	elif coord[axis_1] == 1 and coord[axis_2] == 0:
		coord[axis_1] = 2
		coord[axis_2] = 1
	elif coord[axis_1] == 2 and coord[axis_2] == 0:
		coord[axis_1] = 2
		coord[axis_2] = 2
	elif coord[axis_1] == 0 and coord[axis_2] == 1:
		coord[axis_1] = 1
		coord[axis_2] = 0
	elif coord[axis_1] == 1 and coord[axis_2] == 1:
		coord[axis_1] = 1
		coord[axis_2] = 1
	elif coord[axis_1] == 2 and coord[axis_2] == 1:
		coord[axis_1] = 1
		coord[axis_2] = 2
	elif coord[axis_1] == 0 and coord[axis_2] == 2:
		coord[axis_1] = 0
		coord[axis_2] = 0
	elif coord[axis_1] == 1 and coord[axis_2] == 2:
		coord[axis_1] = 0
		coord[axis_2] = 1
	elif coord[axis_1] == 2 and coord[axis_2] == 2:
		coord[axis_1] = 0
		coord[axis_2] = 2

func _on_rotate_done():
	rotatingLayer = false
	resetLayer()
	if !auto:
		GameState.on_rotate(currentRotationAxis, current_selection.cube_position, lastRotationDirection)
	current_selection = null

func _on_rotate_request(direction) -> void:
	if !rotatingLayer and current_selection != null:
		lastRotationDirection = direction
		var selection_indices = current_selection.cube_position
		rotatingLayer = true
		var group = rotationGroup
		group.transform = Transform3D.IDENTITY
		var rotationaxis
		var index
		if currentRotationAxis == "y":
			index = selection_indices[2]
			rotationaxis = Vector3(0, 1, 0)
			for child in cubes:
				var coord = child.cube_position;
				if coord[2] == index:
					if direction == "R":
						rotate_indices(0, 1, coord)
					else:
						rotate_indices(1, 0, coord)
					child.cube_position = coord
					self.remove_child(child)
					group.add_child(child)
		elif currentRotationAxis == "z":
			index = selection_indices[1]
			rotationaxis = Vector3(0, 0, 1)
			for child in cubes:
				var coord = child.cube_position;
				if coord[1] == index:
					if direction == "R":
						rotate_indices(2, 0, coord)
					else:
						rotate_indices(0, 2, coord)
					child.cube_position = coord
					self.remove_child(child)
					group.add_child(child)
		elif currentRotationAxis == "x":
			index = selection_indices[0]
			rotationaxis = Vector3(1, 0, 0)
			for child in cubes:
				var coord = child.cube_position;
				if coord[0] == index:
					if direction == "R":
						rotate_indices(1, 2, coord)
					else:
						rotate_indices(2, 1, coord)
					child.cube_position = coord
					self.remove_child(child)
					group.add_child(child)		
		var initial = group.transform
		var new_transform = initial * Transform3D.IDENTITY
		var angle
		if direction == "R":
			angle = -PI / 2
		else:
			angle = PI / 2
		new_transform = new_transform.rotated(rotationaxis.normalized(), angle)
		group.set_target_transform(new_transform)
		resetSelection()
		GameState._on_rotate_start()
