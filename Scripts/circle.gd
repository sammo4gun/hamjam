extends CharacterBody2D

#export vars
@export var SPEED = 300.0
@export var ACCELERATION : float = 1200
@export var DECELERATION : float = 1200

var interactible = []

var has_drink = false

func _physics_process(delta: float) -> void:
	handle_movement(delta)
	handle_rotation(delta)

func handle_movement(delta: float) -> void:
	var direction = Vector2.ZERO
	var new_velocity = Vector2.ZERO
	
	# Input for movement: Arrow keys or WASD
	if Input.is_action_pressed("move_right"):
		direction.x += 1
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
	if Input.is_action_pressed("move_down"):
		direction.y += 1
	if Input.is_action_pressed("move_up"):
		direction.y -= 1

	# Normalize the direction to ensure consistent movement speed in all directions
	if direction != Vector2.ZERO:
		direction = direction.normalized()

	# Apply acceleration
	if direction != Vector2.ZERO:
		new_velocity = velocity.move_toward(direction * SPEED
		*
		(0.8 + (0.2 * (get_global_mouse_position() - global_position).normalized().dot(direction.normalized()))), ACCELERATION * delta)
	# Apply deceleration when there's no input
	else:
		new_velocity = velocity.move_toward(Vector2.ZERO, DECELERATION * delta)
	velocity = new_velocity
	
	#move_and_collide(velocity * delta)
	move_and_slide()

func handle_rotation(delta) -> void:
	# Get the mouse position and calculate the angle to face it
	var mouse_position = get_global_mouse_position()
	var angle_to_mouse = (mouse_position - global_position).angle()
	
	rotation = rotate_toward(rotation, angle_to_mouse, 10 * delta)
