@tool
extends GravityField

@export var radius: float = 1: set = set_radius


func get_gravity(target_position: Vector3) -> Vector3:
	return gravity * (position - target_position).normalized()

func set_radius(new_radius: float):
	radius = new_radius
	$Collider/CollisionShape3D.shape.radius = new_radius
