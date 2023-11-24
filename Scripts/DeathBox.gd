@tool
extends Area3D

@export var size: Vector3 = Vector3.ONE: set = set_size


func _on_body_exited(body):
	if not body.is_in_group("player"):
		return

	get_tree().reload_current_scene()

func set_size(new_size: Vector3):
	size = new_size
	$CollisionShape3D.shape.size = new_size
