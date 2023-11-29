@tool
extends GravityField

@onready var collision_shape_3d: CollisionShape3D = $Collider/CollisionShape3D

@export var size: Vector3 = Vector3.ONE: set = set_size


func get_gravity(_target_position: Vector3) -> Vector3:
	return gravity * (-global_transform.basis.y).normalized()

func set_size(new_size: Vector3):
	size = new_size

	if not is_node_ready():
		await ready

	if Engine.is_editor_hint() and collision_shape_3d == null:
		collision_shape_3d = $Collider/CollisionShape3D

	collision_shape_3d.shape.size = new_size
