@tool
extends GravityField

@onready var collision_shape_3d = $Collider/CollisionShape3D

@export var radius: float = 1: set = set_radius


func get_gravity(target_position: Vector3) -> Vector3:
	return gravity * (global_position - target_position).normalized()

func set_radius(new_radius: float):
	radius = new_radius
	if Engine.is_editor_hint() and collision_shape_3d == null:
		collision_shape_3d = $Collider/CollisionShape3D

	if not (is_node_ready() or Engine.is_editor_hint()):
		await ready

	collision_shape_3d.shape.radius = new_radius
