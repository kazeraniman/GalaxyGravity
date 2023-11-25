@tool
extends Area3D

@onready var collision_shape_3d = $CollisionShape3D

@export var size: Vector3 = Vector3.ONE: set = set_size


func _on_body_exited(body):
	if not body.is_in_group("player"):
		return

	get_tree().reload_current_scene()

func set_size(new_size: Vector3):
	size = new_size

	if not is_node_ready():
		await ready

	collision_shape_3d.shape.size = new_size
