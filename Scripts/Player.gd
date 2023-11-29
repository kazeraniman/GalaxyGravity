extends CharacterBody3D

@onready var model_container: Node3D = $ModelContainer
@onready var camera_pivot: Node3D = $CameraPivot
@onready var character_animation_player: AnimationPlayer = $ModelContainer/Character/AnimationPlayer
@onready var land_audio: AudioStreamPlayer3D = $LandAudio
@onready var jump_audio: AudioStreamPlayer3D = $JumpAudio

@export var speed: float = 5
@export var jump_impulse: float = 5
@export var default_gravity_vector: Vector3 = Vector3(0, -9.8, 0)
@export var rotation_lerp: float = 0.1
@export var mouse_cam_x_damp: float = 0.005
@export var mouse_cam_y_damp: float = 0.005
@export var joystick_cam_x_damp: float = 0.05
@export var joystick_cam_y_damp: float = 0.05

var gravity_vector: Vector3 = Vector3.DOWN
var gravity_fields: Array = []
var current_gravity_field: GravityField = null

var cam_rotation_x: float = 0
var cam_rotation_y: float = 0

var floor_check_circular_buffer = []
var floor_check_circular_buffer_current: int = 0
var floor_check_circular_buffer_current_size: int = 0
var floor_check_circular_buffer_max_size: int = 3

var this_frame_is_on_floor: bool = true
var last_frame_is_on_floor: bool = true


func _init():
	floor_check_circular_buffer.resize(floor_check_circular_buffer_max_size)

func _input(event: InputEvent):
	if event.is_action_released("restart"):
		get_tree().reload_current_scene()
		return

	if event.is_action_released("toggle_debug"):
		get_tree().call_group("debug", "toggle_debug")

	if event is InputEventMouseMotion && Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		rotate_camera(-event.relative.x * mouse_cam_x_damp, -event.relative.y * mouse_cam_y_damp)

func _physics_process(delta: float):
	# Determine gravity and normal
	var old_gravity_vector: Vector3 = gravity_vector
	gravity_vector =  current_gravity_field.get_gravity(global_position) if current_gravity_field != null else default_gravity_vector
	var gravity_normal_vector: Vector3 = -(gravity_vector.normalized())
	up_direction = gravity_normal_vector

	# Determine if we are on the floor
	add_is_on_floor_noiseless_element()
	last_frame_is_on_floor = this_frame_is_on_floor
	this_frame_is_on_floor = is_on_floor_noiseless()

	if not last_frame_is_on_floor and this_frame_is_on_floor:
		land_audio.play()

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
	var original_direction: Vector3 = direction

	# Normalize the direction if required to get rid of faster diagonals
	if direction.length() > 1:
		direction = direction.normalized()

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
		direction = direction.rotated(Vector3.UP, cam_rotation_x)

	# Rotate direction with respect to gravity or the ground if possible
	var gravity_rotation_axis: Vector3 = (Vector3.UP.cross(rotation_normal)).normalized()
	var rotation_angle: float = Vector3.UP.signed_angle_to(rotation_normal, Vector3.UP)
	if (gravity_rotation_axis != Vector3.ZERO):
		direction = direction.rotated(gravity_rotation_axis, rotation_angle)

	# Rotate the model to match the gravity and the movement direction
	var new_model_container_basis: Basis = model_container.transform.basis
	new_model_container_basis.y = rotation_normal

	if direction != Vector3.ZERO:
		new_model_container_basis.z = -direction

	new_model_container_basis.x = rotation_normal.cross(new_model_container_basis.z)
	new_model_container_basis = new_model_container_basis.orthonormalized()

	var old_model_quat: Quaternion = Quaternion(model_container.transform.basis)
	var new_model_quat: Quaternion = Quaternion(new_model_container_basis)
	var new_model_lerp_quat: Quaternion = old_model_quat.slerp(new_model_quat, rotation_lerp)
	model_container.transform.basis = Basis(new_model_lerp_quat)

	# Determine the scaled, ground velocity
	var new_velocity: Vector3 = direction * speed

	# Retain gravity's influence
	new_velocity += velocity.project(old_gravity_vector)

	# Jumping
	if this_frame_is_on_floor and Input.is_action_just_pressed("jump"):
		new_velocity += jump_impulse * gravity_normal_vector
		jump_audio.play()

	# Gravity
	new_velocity += delta * gravity_vector

	# Play animations
	if not this_frame_is_on_floor:
		character_animation_player.play("falling")
	elif original_direction != Vector3.ZERO:
		character_animation_player.play("walk", -1, clampf(direction.length(), 0, 1))
	else:
		character_animation_player.play("idle")

	# Move and perform collisions
	velocity = new_velocity
	move_and_slide()

func add_gravity_field(added_gravity_field: GravityField):
	gravity_fields.append(added_gravity_field)
	determine_current_gravity_field()

func remove_gravity_field(removed_gravity_field: GravityField):
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

	camera_pivot.transform.basis = Basis()
	camera_pivot.rotate_object_local(Vector3.UP, cam_rotation_x)
	camera_pivot.rotate_object_local(Vector3.RIGHT, cam_rotation_y)

func add_is_on_floor_noiseless_element():
	floor_check_circular_buffer[floor_check_circular_buffer_current] = is_on_floor()
	floor_check_circular_buffer_current = (floor_check_circular_buffer_current + 1) % floor_check_circular_buffer_max_size
	floor_check_circular_buffer_current_size = min(floor_check_circular_buffer_current_size + 1, floor_check_circular_buffer_max_size)

func is_on_floor_noiseless() -> bool:
	var check: bool = false
	for i in range(0, floor_check_circular_buffer_current_size):
		check = check or floor_check_circular_buffer[i]

	return check
