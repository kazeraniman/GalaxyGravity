extends GravityField


func get_gravity(target_position: Vector3) -> Vector3:
	return gravity * (position - target_position).normalized()
