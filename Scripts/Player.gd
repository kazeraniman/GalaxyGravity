extends CharacterBody3D

@export var speed: float = 5
@export var jump_impulse: float = 5
@export var default_gravity_vector: Vector3 = Vector3(0, -9.8, 0)
@export var rotation_lerp: float = 0.25
@export var mouse_cam_x_damp: float = 0.005
@export var mouse_cam_y_damp: float = 0.005
@export var joystick_cam_x_damp: float = 0.05
@export var joystick_cam_y_damp: float = 0.05

var gravity_vector: Vector3 = Vector3.DOWN
var gravity_fields: Array = []
var current_gravity_field: GravityField = null

var cam_rotation_x = 0
var cam_rotation_y = 0


func _input(event):
	if event.is_action_released("restart"):
		get_tree().reload_current_scene()
		return

	if event is InputEventMouseMotion && Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		rotate_camera(-event.relative.x * mouse_cam_x_damp, -event.relative.y * mouse_cam_y_damp)

func _physics_process(delta):
	# Determine gravity and normal
	var old_gravity_vector: Vector3 = gravity_vector
	gravity_vector =  current_gravity_field.get_gravity(position) if current_gravity_field != null else default_gravity_vector
	var gravity_normal_vector: Vector3 = -(gravity_vector.normalized())
	up_direction = gravity_normal_vector

	# Rotate camera
	var joystick_value: Vector2 = Vector2.ZERO
	joystick_value.y += Input.get_action_strength("camera_move_up")
	joystick_value.y -= Input.get_action_strength("camera_move_down")
	joystick_value.x -= Input.get_action_strength("camera_move_right")
	joystick_value.x += Input.get_action_strength("camera_move_left")
	rotate_camera(joystick_value.x * joystick_cam_x_damp, joystick_value.y * joystick_cam_y_damp)

	# Determine the "ground" movement direction
	var direction: Vector3 = Vector3.ZERO
	direction.z -= Input.get_action_strength("move_forward")
	direction.z += Input.get_action_strength("move_backward")
	direction.x -= Input.get_action_strength("move_left")
	direction.x += Input.get_action_strength("move_right")

	# Maintain a version of the direction prior to any transformations
	var original_direction = direction

	# Determine the normal to use based on the floor or the gravity
	var rotation_normal: Vector3 = get_floor_normal() if is_on_floor() else gravity_normal_vector

	# Odd solution since I was getting -0 sometimes and that would break the gravity rotation later on
	if is_equal_approx(rotation_normal.x, 0):
		rotation_normal.x = 0
	if is_equal_approx(rotation_normal.y, 0):
		rotation_normal.y = 0
	if is_equal_approx(rotation_normal.z, 0):
		rotation_normal.z = 0

	# Rotate the direction with respect to the camera
	if direction != Vector3.ZERO:
		direction = direction.rotated(Vector3.UP, cam_rotation_x).normalized()

	# Rotate direction with respect to gravity or the ground if possible
	var gravity_rotation_axis: Vector3 = (Vector3.UP.cross(rotation_normal)).normalized()
	var rotation_angle: float = Vector3.UP.signed_angle_to(rotation_normal, Vector3.UP)
	if (gravity_rotation_axis != Vector3.ZERO):
		direction = direction.rotated(gravity_rotation_axis, rotation_angle).normalized()

	# Rotate the model to match the gravity and the movement direction
	var new_model_container_basis = $ModelContainer.transform.basis
	new_model_container_basis.y = rotation_normal

	if direction != Vector3.ZERO:
		new_model_container_basis.z = -direction

	new_model_container_basis.x = rotation_normal.cross(new_model_container_basis.z)
	new_model_container_basis = new_model_container_basis.orthonormalized()

	var old_model_quat = Quaternion($ModelContainer.transform.basis)
	var new_model_quat = Quaternion(new_model_container_basis)
	var new_model_lerp_quat = old_model_quat.slerp(new_model_quat, rotation_lerp)
	$ModelContainer.transform.basis = Basis(new_model_lerp_quat)

	# Determine the scaled, ground velocity
	var new_velocity: Vector3 = direction * speed

	# Retain gravity's influence
	new_velocity += velocity.project(old_gravity_vector)

	# Jumping
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		new_velocity += jump_impulse * gravity_normal_vector

	# Gravity
	new_velocity += delta * gravity_vector

	# Play animations
	if not is_on_floor():
		$ModelContainer/Character/AnimationPlayer.play("falling")
	elif original_direction != Vector3.ZERO:
		$ModelContainer/Character/AnimationPlayer.play("walk")
	else:
		$ModelContainer/Character/AnimationPlayer.play("idle")

	# Move and perform collisions
	velocity = new_velocity
	move_and_slide()

func add_gravity_field(added_gravity_field):
	gravity_fields.append(added_gravity_field)
	determine_current_gravity_field()

func remove_gravity_field(removed_gravity_field):
	gravity_fields.erase(removed_gravity_field)
	determine_current_gravity_field()

# Ideally would use a max heap / priority queue but since it's small this should be sufficient
func determine_current_gravity_field():
	if len(gravity_fields) == 0:
		current_gravity_field = null
		return

	current_gravity_field = gravity_fields[0]
	for gravity_field in gravity_fields:
		if gravity_field.priority > current_gravity_field.priority:
			current_gravity_field = gravity_field

func rotate_camera(rotation_x: float, rotation_y: float):
	cam_rotation_x += rotation_x
	cam_rotation_y += rotation_y

	$CameraPivot.transform.basis = Basis()
	$CameraPivot.rotate_object_local(Vector3.UP, cam_rotation_x)
	$CameraPivot.rotate_object_local(Vector3.RIGHT, cam_rotation_y)
