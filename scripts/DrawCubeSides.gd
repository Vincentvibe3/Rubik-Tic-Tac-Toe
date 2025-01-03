extends RigidBody3D

class_name DrawableCube

signal selected(normal: Vector3)

var cube_position
var played={}
var cube_owner

var selectedFace
var selectedDecal

var t = 0

func _input_event(_camera: Camera3D, event: InputEvent, _event_position: Vector3, normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		if GameState.is_multiplayer and GameState.gameStarted:
			if !GameState.is_client_turn():
				return
		self.emit_signal("selected", normal)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	disableGravity()
	selected.connect(_on_selected)

func reset_position():
	var size = getSize()
	var i = cube_position[2]
	var j = cube_position[1]
	var k = cube_position[0]
	var newPosition = Vector3(-size + k * size, -size + i * size, -size + j * size)
	self.transform = Transform3D.IDENTITY.translated(newPosition)


func enableGravity():
	gravity_scale = 1
	freeze = false

func disableGravity():
	set_deferred("linear_velocity", Vector3.ZERO)
	set_deferred("angular_velocity", Vector3.ZERO)
	set_deferred("gravity_scale", 0)
	freeze = true
	freeze_mode = FreezeMode.FREEZE_MODE_STATIC
	

func reset():
	for child in self.get_children():
		if child is Decal:
			self.remove_child(child)
	selectedDecal = null
	selectedFace = null
	played.clear()
	disableGravity()
	call_deferred("reset_position")

func getSize():
	return $CubeMesh.mesh.get_aabb().get_longest_axis_size()

func checkSide(normal:Vector3):
	var local_normal = self.to_local(normal)-self.to_local(Vector3.ZERO)
	for side in played:
		if side.is_equal_approx(local_normal):
			return played[side]
	return null

func highlight_color(color:Color):
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_MUL
	$CubeMesh.material_overlay = mat

func highlight(material:StandardMaterial3D):
	$CubeMesh.material_overlay = material

func _on_selected(normal: Vector3) -> void:
	var local_normal = self.to_local(normal)-self.to_local(Vector3.ZERO)
	selectedFace = local_normal
	cube_owner.emit_signal("selection", self)

func reset_color():
	$CubeMesh.material_overlay = null

func reset_selection():
	if selectedDecal != null:
		remove_child(selectedDecal)
		selectedDecal = null

func get_face(local_normal):
	var size = $CubeMesh.get_aabb().get_longest_axis_size()
	var faces = [
		[Vector3.RIGHT, Vector3(size/2, 0, 0)],
		[Vector3.LEFT, Vector3(-size/2, 0, 0)],
		[Vector3.UP, Vector3(0, size/2, 0)],
		[Vector3.DOWN, Vector3(0, -size/2, 0)],
		[Vector3.BACK, Vector3(0, 0, size/2)],
		[Vector3.FORWARD, Vector3(0, 0, -size/2)],
	]
	var face_data 
	for face in faces:
		if local_normal.is_equal_approx(face[0]):
			face_data = face
			break
	return face_data

func drawDecal(face_data, local_normal, decal):
	var size = $CubeMesh.get_aabb().get_longest_axis_size()
	var rotation_axes = [
		Vector3.LEFT,
		Vector3.UP,
		Vector3.FORWARD
	]
	var in_plane
	for axis in rotation_axes:
		var parallel_candidate = local_normal.rotated(axis, PI/2)
		if !parallel_candidate.is_equal_approx(local_normal):
			in_plane = parallel_candidate
			break

	# decal.modulate = Color(0, 0, 0)
	decal.lower_fade = 0
	decal.upper_fade = 1
	decal.emission_energy = 0
	decal.size = Vector3(size, 0.1, size)
	self.add_child(decal)
	decal.position = face_data[1]
	decal.basis.x = in_plane
	decal.basis.y = -local_normal
	decal.basis.z = local_normal.cross(in_plane)

func drawSelect():
	if selectedFace != null:
		var face_data = get_face(selectedFace)
		var decal:Decal = Decal.new()	
		selectedDecal = decal
		decal.texture_albedo = load("res://Textures/Selection.png")
		drawDecal(face_data, selectedFace, decal)

func mark_face(local_normal):
	var face_data = get_face(local_normal)
	if played.has(face_data[0]):
		return
	var decal:Decal = Decal.new()
	if GameState.currentPlayer == 0:
		decal.texture_albedo = load("res://Textures/Circle_alpha.png")
	else:
		decal.texture_albedo = load("res://Textures/Cross_alpha.png")
	played[face_data[0]] = GameState.currentPlayer
	drawDecal(face_data, local_normal, decal)
	GameState.on_mark(local_normal, cube_position)

func _on_face_clicked(normal: Vector3) -> void:
	var local_normal = self.to_local(normal)-self.to_local(Vector3.ZERO)
	mark_face(local_normal)
