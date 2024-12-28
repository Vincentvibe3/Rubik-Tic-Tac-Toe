extends Node

var currentPlayer = 0

var textNode
var gameCube
var cubes = []
var boards = []
var winScreen
var gameScene
var gameStarted = false
var sliders = []
var is_multiplayer = false
var is_host = false
var room_id
var room_name
var room_password
var wshandler
var inputBlocker
var roundEnded = false
var peerTutorialDone = false
var lastClickedCube = null
var showMultiplayerLoadingScreen = true
var serverAddress = "rubikt3.vincentvibe3.com"
var isInsecure = false

var actionqueue = []

var highlightColor = Color8(197, 220, 222)
var selectionColor = Color8(255, 216, 99)
var lastMoveColor = Color8(149, 211, 157)
var highlightMaterial = StandardMaterial3D.new()
var selectionMaterial = StandardMaterial3D.new()
var lastMoveMaterial = StandardMaterial3D.new()

var audio
var bgm
var muted = false

# normal vector, layer index, layer axis
var faces = [
	[Vector3.LEFT, 0, 0],
	[Vector3.BACK, 2, 1],
	[Vector3.RIGHT, 2, 0],
	[Vector3.FORWARD, 0, 1],
	[Vector3.UP, 2, 2],
	[Vector3.DOWN, 0, 2],
]

func _ready() -> void:
	highlightMaterial.albedo_color = highlightColor
	highlightMaterial.blend_mode = BaseMaterial3D.BLEND_MODE_MUL
	selectionMaterial.albedo_color = selectionColor
	selectionMaterial.blend_mode = BaseMaterial3D.BLEND_MODE_MUL
	lastMoveMaterial.albedo_color = lastMoveColor
	lastMoveMaterial.blend_mode = BaseMaterial3D.BLEND_MODE_MUL

func toggle_mute():
	muted = !muted

func close_ws():
	if is_multiplayer:
		if wshandler.active:
			wshandler.close()
			return true
	return false

func is_client_turn():
	return (is_host && currentPlayer == 0) || (!is_host && currentPlayer == 1)

func go_to_menu():
	is_multiplayer = false
	is_host = false
	gameStarted = false
	roundEnded = false
	lastClickedCube = null
	peerTutorialDone = false
	showMultiplayerLoadingScreen = true
	sliders.clear()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	

func _process(_delta: float) -> void:
	if gameStarted:
		if actionqueue:
			var action = actionqueue.pop_front()
			action[0].callv(action[1], action[2])

func queue_action(obj, method, args):
	actionqueue.append([obj, method, args])

func mark_selection():
	mark_face(gameCube.current_selection.cube_position, gameCube.current_selection.selectedFace, true)

func mark_face(coord, face_normal, force=false):
	for cube in cubes:
		if cube.cube_position[0] == coord[0] && cube.cube_position[1] == coord[1] && cube.cube_position[2] == coord[2]:
			if force:
				cube.mark_face(face_normal)
			else:
				queue_action(cube, "mark_face", [face_normal])
			break

func rotate_layer(cube, axis, direction):
	gameCube._on_select(cube)
	gameCube._on_set_rotation_axis(axis)
	gameCube._on_rotate_request(direction)

func rotate_cube(axis, coord, direction):
	for cube in cubes:
		if cube.cube_position[0] == coord[0] && cube.cube_position[1] == coord[1] && cube.cube_position[2] == coord[2]:
			queue_action(self, "rotate_layer", [cube, axis, direction])		
			break

func highlight_last_clicked():
	var coord = lastClickedCube
	if lastClickedCube != null:
		for cube in cubes:
			if cube.cube_position[0] == coord[0] && cube.cube_position[1] == coord[1] && cube.cube_position[2] == coord[2]:
				cube.highlight(lastMoveMaterial)

func reset_last_clicked():
	var coord = lastClickedCube
	if lastClickedCube != null:
		for cube in cubes:
			if cube.cube_position[0] == coord[0] && cube.cube_position[1] == coord[1] && cube.cube_position[2] == coord[2]:
				cube.reset_color()
	lastClickedCube = null

func on_mark(local_normal, coord):
	if audio != null:
		audio.play_marker()
	gameCube.resetLayer()
	gameCube.resetSelection()
	gameCube.hide3DControls()
	reset_last_clicked()
	lastClickedCube = coord
	highlight_last_clicked()
	if gameStarted:
		if is_multiplayer:
			if is_client_turn():
				wshandler.send_mark(coord, local_normal)
		GameState.changeTurn()

func _on_rotate_start():
	if audio != null:
		audio.play_wood()

func on_rotate(axis, coord, direction):
	gameCube.hide3DControls()
	gameCube.resetLayer()
	reset_last_clicked()
	if gameStarted:
		if is_multiplayer:
			if is_client_turn():
				wshandler.send_rotate(axis, coord, direction)
		GameState.changeTurn()

func startGame():
	gameStarted = true
	reset()

func setTextNode(node):
	textNode = node
	setPlayerText()

func setPlayerText():
	if !gameStarted:
		if textNode != null:
			textNode.text = "Tutorial"
			return
	var message
	var playerText = ""
	
	if is_multiplayer:
		var opponentText
		if is_host:
			playerText = "O"
			opponentText = "X"
		else:
			playerText = "X"
			opponentText = "O"
		if is_client_turn():
			message = "Your turn ("+playerText+")"
		else:
			message = "Opponent's turn ("+opponentText+")"
	else:
		if currentPlayer == 0:
			playerText = "O"
		else:
			playerText = "X"
		message = playerText+"'s turn"
	if textNode != null:
		textNode.text = message

func changeTurn():
	if gameStarted:
		checkBoard()
		currentPlayer = (currentPlayer+1)%2
		setPlayerText()
		

func setActiveGameCube(cube:CubeGenerator):
	gameCube = cube
	cubes = gameCube.cubes

func reset():
	if roundEnded && is_multiplayer:
		wshandler.send_reset()
		roundEnded = false
	reset_last_clicked()
	gameCube.reset()
	winScreen.visible = false
	currentPlayer = 1
	changeTurn()
	for slider in sliders:
		slider.value = 0

func explodeCube():
	if audio != null:
		audio.play_explosion()
	for cube in cubes:
		cube.enableGravity()
		cube.apply_central_impulse(Vector3(randi()%20, randi()%25, randi()%20))
	roundEnded = true

func checkBoard():
	for face in faces:
		face.append(generateBoard())

	for cube in cubes:
		var coord = cube.cube_position
		for face in faces:
			var normal = face[0]
			if coord[face[2]] == face[1]:
				var globalNormal = gameCube.to_global(normal)-gameCube.to_global(Vector3.ZERO)
				var move = cube.checkSide(globalNormal)
				var sideCoord
				if face[2] == 0:
					sideCoord = [coord[1], coord[2]]
				elif face[2] == 1:
					sideCoord = [coord[0], coord[2]]
				elif face[2] == 2:
					sideCoord = [coord[0], coord[1]]
				face[3][sideCoord[0]][sideCoord[1]] = move

	var xWins = 0
	var oWins = 0
	for face in faces:
		var wins = countBoardWins(face[3])
		face.pop_back()
		xWins+=wins[0]
		oWins+=wins[1]
	if xWins==0 && oWins==0:
		return

	var xName
	var oName
	if is_multiplayer:
		if is_host:
			oName = "You"
			xName = "Your opponent"
		else:
			oName = "Your opponent"
			xName = "You"
	else:
		xName = "X"
		oName = "O"
	if xWins > oWins:
		winScreen.setWinText(xName+" won!")
	elif oWins > xWins:
		winScreen.setWinText(oName+" won!")
	else:
		winScreen.setWinText("Tie")
	winScreen.visible = true
	explodeCube()



func generateBoard():
	var face = []
	for j in range(3):
		var row = []
		for k in range(3):
			row.append(null)
		face.append(row)
	return face


func countBoardWins(face):
	var xWins = 0
	var oWins = 0
	var xCount = 0
	var oCount = 0
	# check row
	for row in face:
		xCount = 0
		oCount = 0
		for move in row:
			if move == 1:
				xCount+=1
			elif move == 0:
				oCount+=1
		if xCount==3:
			xWins+=1
		elif oCount == 3:
			oWins+=1

	# check columns
	for colIdx in range(len(face[0])):
		xCount = 0
		oCount = 0
		for row in face:
			var move = row[colIdx]
			if move == 1:
				xCount+=1
			elif move == 0:
				oCount+=1
		if xCount==3:
			xWins+=1
		elif oCount == 3:
			oWins+=1

	# check diagonals
	xCount = 0
	oCount = 0
	for i in range(len(face)):
		var move = face[i][i]
		if move == 1:
			xCount+=1
		elif move == 0:
			oCount+=1
	if xCount==3:
		xWins+=1
	elif oCount == 3:
		oWins+=1
	
	xCount = 0
	oCount = 0
	for i in range(len(face)):
		var move = face[i][2-i]
		if move == 1:
			xCount+=1
		elif move == 0:
			oCount+=1
	if xCount==3:
		xWins+=1
	elif oCount == 3:
		oWins+=1


	return [xWins, oWins]

func getGameWinner():
	var xWins = 0
	var oWins = 0
	for face in boards:
		var wins = countBoardWins(face)
		xWins+=wins[0]
		oWins+=wins[1]
	if xWins==0 && oWins==0:
		return []
	elif xWins > oWins:
		return ["x"]
	elif oWins > xWins:
		return ["o"]
	else:
		return ["x", "o"]
