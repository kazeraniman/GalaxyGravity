@tool
extends GravityField

@onready var collision_shape_3d: CollisionShape3D = $Collider/CollisionShape3D
@onready var debug_visuals: MeshInstance3D = $DebugVisuals

@export var radius: float = 1: set = set_radius


func _ready():
	super._ready()

	debug_visuals.visible = Engine.is_editor_hint()

func get_gravity(target_position: Vector3) -> Vector3:
	return gravity * (global_position - target_position).normalized()

func set_radius(new_radius: float):
	radius = new_radius

	if not is_node_ready():
		await ready

	if Engine.is_editor_hint() and collision_shape_3d == null:
		collision_shape_3d = $Collider/CollisionShape3D
		debug_visuals = $DebugVisuals

	collision_shape_3d.shape.radius = new_radius
	debug_visuals.mesh.radius = new_radius
	debug_visuals.mesh.height = new_radius * 2

func toggle_debug():
	debug_visuals.visible = not debug_visuals.visible
