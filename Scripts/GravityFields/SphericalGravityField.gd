@tool
extends GravityField

@onready var collision_shape_3d: CollisionShape3D = $Collider/CollisionShape3D
@onready var cpu_particles_3d: CPUParticles3D = $CPUParticles3D

@export var radius: float = 1: set = set_radius


func _ready():
	super._ready()

	cpu_particles_3d.emitting = Engine.is_editor_hint()

func get_gravity(target_position: Vector3) -> Vector3:
	return gravity * (global_position - target_position).normalized()

func set_radius(new_radius: float):
	radius = new_radius

	if not is_node_ready():
		await ready

	if Engine.is_editor_hint() and collision_shape_3d == null:
		collision_shape_3d = $Collider/CollisionShape3D
		cpu_particles_3d = $CPUParticles3D

	collision_shape_3d.shape.radius = new_radius
	cpu_particles_3d.mesh.radius = new_radius
	cpu_particles_3d.mesh.height = new_radius * 2

func toggle_debug():
	cpu_particles_3d.emitting = not cpu_particles_3d.emitting
