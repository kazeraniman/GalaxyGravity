@tool
extends GravityField

@onready var collision_shape_3d: CollisionShape3D = $Collider/CollisionShape3D
@onready var debug_visuals: MeshInstance3D = $DebugVisuals

@export var size: Vector3 = Vector3.ONE: set = set_size

func _ready():
	super._ready()

	debug_visuals.visible = Engine.is_editor_hint()

func get_gravity(_target_position: Vector3) -> Vector3:
	return gravity * (-global_transform.basis.y).normalized()

func set_size(new_size: Vector3):
	size = new_size

	if not is_node_ready():
		await ready

	if Engine.is_editor_hint() and collision_shape_3d == null:
		collision_shape_3d = $Collider/CollisionShape3D
		debug_visuals = $DebugVisuals

	collision_shape_3d.shape.size = new_size
	debug_visuals.mesh.size = new_size
	debug_visuals.mesh.material.set_shader_parameter("height", new_size.y)

func toggle_debug():
	debug_visuals.visible = not debug_visuals.visible
