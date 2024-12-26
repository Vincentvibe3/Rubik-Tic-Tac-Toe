extends Node3D

class_name RotateControls

func set_active_axis(axis:String):
	for child in self.get_children():
		if child.get_meta("axis") == axis:
			child.visible = true
		else:
			child.visible = false
