@tool
extends GravityField

@onready var collision_shape_3d = $Collider/CollisionShape3D

@export var radius: float = 1: set = set_radius


func get_gravity(target_position: Vector3) -> Vector3:
	return gravity * (position - target_position).normalized()

func set_radius(new_radius: float):
	radius = new_radius

	if not is_node_ready():
		await ready

	collision_shape_3d.shape.radius = new_radius
