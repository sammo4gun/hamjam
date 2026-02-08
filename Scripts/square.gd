extends CharacterBody2D

var TYPE = 'square'

#export vars
@export var SPEED = 300.0
@export var ACCELERATION : float = 1200
@export var DECELERATION : float = 1200

@export var MAX_HEALTH = 8
var health = MAX_HEALTH
@export var ATTACK_RANGE = 10

@export var is_player = false

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
var next_position = global_position
var target_entity = null

var ready_for_attack = false
var attacking = false
@onready var attack_sprite = $"AttackSprite"
@onready var attack_area = $"AttackArea"

var is_wanted = false

var target_handler

var dead = false

func _ready():
	# Optional tuning
	nav_agent.path_desired_distance = 4.0
	nav_agent.target_desired_distance = 4.0

func _physics_process(delta: float) -> void:
	if target_handler: # make sure this doesn't happen before we assign a target handler
		if is_player:
			player_handle_movement(delta)
			player_handle_rotation(delta)
			player_handle_attacks()
		else:
			nav_find_target() # what we could do at one point is ping for this every second,
			# and just follow the target for the time that we have. this could be better for processing
			# speed
			nav_handle_movement(delta)
			nav_handle_rotation(delta)
			if ready_for_attack and !attacking:
				attack()

# ============================================================
# ENEMY SCRIPTS
# ============================================================

func nav_find_target():
	if !is_wanted:
		target_entity = target_handler.get_nearest_wanted(self)
		if target_entity:
			nav_agent.target_position = target_entity.global_position
			if not target_entity in attack_area.get_overlapping_bodies():
				ready_for_attack = false
	if is_wanted:
		target_entity = target_handler.get_nearest_enemy(self)
		if target_entity:
			nav_agent.target_position = target_entity.global_position
			if not target_entity in attack_area.get_overlapping_bodies():
				ready_for_attack = false
	if !target_entity:
		ready_for_attack = false
		nav_agent.target_position = global_position

func nav_handle_movement(delta) -> void:
	if nav_agent.is_navigation_finished() or ready_for_attack or attacking:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	next_position = nav_agent.get_next_path_position()
	var direction = (next_position - global_position).normalized()
	var new_velocity = Vector2.ZERO
	
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
	
	move_and_slide()
	
func nav_handle_rotation(delta) -> void:
	if attacking: return
	# Get the mouse position and calculate the angle to face it
	var target_position = next_position
	var angle_to_mouse = (target_position - global_position).angle()
	
	rotation = rotate_toward(rotation, angle_to_mouse, 10 * delta)

# ============================================================
# PLAYER SCRIPTS
# ============================================================

func player_handle_movement(delta: float) -> void:
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

func player_handle_rotation(delta) -> void:
	# Get the mouse position and calculate the angle to face it
	var mouse_position = get_global_mouse_position()
	var angle_to_mouse = (mouse_position - global_position).angle()
	
	rotation = rotate_toward(rotation, angle_to_mouse, 10 * delta)

func player_handle_attacks() -> void:
	pass

func attack():
	attacking = true
	await get_tree().create_timer(0.3).timeout
	attack_sprite.visible = true
	attack_sprite.play()
	await attack_sprite.animation_finished
	damage()
	attack_sprite.visible = false
	await get_tree().create_timer(0.1).timeout
	attacking = false

func damage():
	for entity in attack_area.get_overlapping_bodies():
		# check which entities it can deal damage to
		if entity is CharacterBody2D:
			if entity.TYPE != TYPE:
				entity.apply_damage(1)

func apply_damage(amount):
	health -= amount
	if is_player:
		if health <= 0:
			# die as a player, do some cool stuff here
			die()
			pass
	else:
		if health <= 0:
			# entity dies, do some cool stuff here
			die()
			pass

func die():
	dead = true
	# death animation
	await get_tree().create_timer(0.4).timeout
	target_handler.die(self)

func _on_attack_detector_area_body_entered(body: Node2D) -> void:
	if body == target_entity:
		if !body.dead:
			ready_for_attack = true

func _on_attack_detector_area_body_exited(body: Node2D) -> void:
	if body == target_entity:
		ready_for_attack = false
