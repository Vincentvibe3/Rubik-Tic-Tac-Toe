extends Node3D

class_name RotationGroup

var target_transform = self.transform
var initial_transform = self.transform
var is_rotating = false
var t = 0


func set_target_transform(t_transform):
	if !is_rotating:
		create_tween().tween_property(self, "transform", t_transform, 1).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT).connect("finished", _on_rotation_done)
		is_rotating = true


func _on_rotation_done():
	is_rotating = false
	var parent = get_parent()
	for child in get_children():
		var old_transform = child.global_transform*Transform3D.IDENTITY
		self.remove_child(child)
		parent.add_child(child)
		child.global_transform = old_transform
	parent.emit_signal("rotateDone")
