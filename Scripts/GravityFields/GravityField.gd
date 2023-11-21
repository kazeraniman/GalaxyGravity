@tool
extends Node3D
class_name GravityField

@export var gravity: float = 9.8


func _ready():
	if Engine.is_editor_hint():
		return

	for child in get_children():
		if child is Area3D:
			child.body_entered.connect(_on_collider_body_entered)
			child.body_exited.connect(_on_collider_body_exited)
			return

	printerr("Area3D is required for all GravityField objects.")
	queue_free()

func get_gravity(_target_position: Vector3) -> Vector3:
	return gravity * Vector3.DOWN

func _on_collider_body_entered(body):
	if not body.has_method("add_gravity_field"):
		return

	body.add_gravity_field(self)

func _on_collider_body_exited(body):
	if not body.has_method("remove_gravity_field"):
		return

	body.remove_gravity_field(self)
