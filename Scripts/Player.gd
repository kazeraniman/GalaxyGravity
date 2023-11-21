extends CharacterBody3D

@export var speed: float = 5
@export var jump_impulse: float = 5

var gravity_vector: Vector3 = Vector3.DOWN
var gravity_field: GravityField = null

func _physics_process(delta):
	# Check directional inputs
	var forwardStrength: float = Input.get_action_strength("move_forward")
	var backwardStrength: float = Input.get_action_strength("move_backward")
	var leftStrength: float = Input.get_action_strength("move_left")
	var rightStrength: float = Input.get_action_strength("move_right")

	# Determine gravity and normal
	var old_gravity_vector: Vector3 = gravity_vector
	gravity_vector =  gravity_field.get_gravity(position) if gravity_field != null else old_gravity_vector
	var normal_vector: Vector3 = -(gravity_vector.normalized())
	up_direction = normal_vector

	# Determine the "ground" movement direction
	var direction: Vector3 = Vector3.ZERO
	if forwardStrength > 0:
		direction.z -= forwardStrength
	if backwardStrength > 0:
		direction.z += backwardStrength
	if leftStrength > 0:
		direction.x -= leftStrength
	if rightStrength > 0:
		direction.x += rightStrength

	# Normalize the movement to avoid super-speed diagonals
	if direction.length() > 1:
		direction = direction.normalized()

	# Rotate the player to face the direction of movement
	if direction != Vector3.ZERO:
		$ModelContainer.rotation.y = Vector3.FORWARD.signed_angle_to(direction, Vector3.UP)

	# Rotate with respect to gravity
	var rotation_axis: Vector3 = (Vector3.UP.cross(normal_vector)).normalized()
	var rotation_angle: float = Vector3.UP.angle_to(normal_vector)
	if (rotation_axis != Vector3.ZERO):
		direction = direction.rotated(rotation_axis, rotation_angle).normalized()
		transform.basis = Basis(rotation_axis, rotation_angle)

	# Determine the scaled, ground velocity
	var new_velocity: Vector3 = direction * speed

	# Retain gravity's influence
	new_velocity += velocity.project(old_gravity_vector)

	# Jumping
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		new_velocity += jump_impulse * normal_vector

	# Gravity
	new_velocity += delta * gravity_vector

	# Move and perform collisions
	velocity = new_velocity
	move_and_slide()

func add_gravity_field(added_gravity_field):
	gravity_field = added_gravity_field

func remove_gravity_field(removed_gravity_field):
	gravity_field = null
