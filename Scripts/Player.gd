extends CharacterBody3D

@export var speed = 5
@export var jump_impulse = 5
@export var gravity = 9.8


func _physics_process(delta):
	# Check directional inputs
	var forwardStrength = Input.get_action_strength("move_forward")
	var backwardStrength = Input.get_action_strength("move_backward")
	var leftStrength = Input.get_action_strength("move_left")
	var rightStrength = Input.get_action_strength("move_right")
	
	# Determine the "ground" movement direction
	var direction = Vector3.ZERO
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
	
	# Determine the scaled, ground velocity
	var new_velocity = direction * speed
	
	# Retain gravity's influence
	new_velocity.y = velocity.y
	
	# Jumping
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		new_velocity.y = jump_impulse
	
	# Gravity
	new_velocity.y -= gravity * delta
	
	# Move and perform collisions
	velocity = new_velocity
	move_and_slide()
