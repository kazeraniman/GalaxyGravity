@tool
extends GravityField

@export var size: Vector3 = Vector3.ONE: set = set_size


func get_gravity(_target_position: Vector3) -> Vector3:
	return gravity * (Vector3.DOWN * quaternion).normalized()

func set_size(new_size: Vector3):
	size = new_size
	$Collider/CollisionShape3D.shape.size = new_size
