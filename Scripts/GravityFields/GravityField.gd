extends Node3D
class_name GravityField

@export var gravity: float = 9.8


func get_gravity(_target_position: Vector3) -> Vector3:
	return gravity * Vector3.DOWN
