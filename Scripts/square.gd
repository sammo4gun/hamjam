extends CharacterBody2D

var TYPE = 'square'

#export vars
@export var SPEED = 150.0
@export var ACCELERATION : float = 1200
@export var DECELERATION : float = 1200

@export var MAX_HEALTH = 6
var health = MAX_HEALTH
@export var ATTACK_RANGE = 10

@export var SHYNESS = 150
@export var WANDER_TIMER = 4.0
var wander_time = 0.0
var wander_target = Vector2(0,0)

@export var is_player = false

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var entity_view = $EntityView
@onready var nav_map = get_world_2d().navigation_map
var next_position = global_position
var target_entity = null
var target_lookat = null

var ready_for_attack = false
var attacking = false
@onready var attack_sprite = $"AttackSprite"
@onready var attack_detection_area = $"AttackDetectorArea"
@onready var attack_area = $"AttackArea"
@onready var switch_finder = $"SwitchFinder"

var target_handler
var switch_handler
var behaviour_handler
var player_handler

var entities_seen = []
var behaviour = 'idle'

var dead = false

func _ready():
	# Optional tuning
	nav_agent.path_desired_distance = 4.0
	nav_agent.target_desired_distance = 4.0
	nav_agent.max_speed = SPEED * 0.9

func _physics_process(delta: float) -> void:
	if target_handler: # make sure this doesn't happen before we assign a target handler
		if is_player:
			player_handle_movement(delta)
			player_handle_rotation(delta)
			switch_handler.switch_available(self)
		else:
			entities_seen = behaviour_handler.get_visible_entities(entity_view)
			var new_behaviour = behaviour_handler.get_behaviour(self, entities_seen)
			if behaviour != new_behaviour:
				target_lookat = null
				behaviour = new_behaviour
			handle_behaviours(delta)
			nav_handle_movement(delta)
			nav_handle_rotation(delta)

func handle_behaviours(delta):
	if behaviour == 'idle':
		wander_check(delta)
		var info = behaviour_handler.idle_target(self, entities_seen, nav_map, SHYNESS)
		nav_agent.target_position = info[0]
		target_lookat = info[1]
	elif behaviour == 'flee':
		attacking = false
		ready_for_attack = false
		nav_agent.target_position = behaviour_handler.flee_target(self, entities_seen, nav_map)
	elif behaviour == 'attack':
		nav_find_target()
		check_attack_area()
		if ready_for_attack and !attacking:
			attack()

func wander_check(delta):
	if behaviour_handler and wander_time < 0.0:
		wander_target = behaviour_handler.pick_wander_target()
		wander_time = WANDER_TIMER + (randf()-0.5) * 0.5 * WANDER_TIMER
	else: wander_time -= delta

# ============================================================
# ENEMY SCRIPTS
# ============================================================

func nav_find_target():
	if !target_handler.is_wanted(TYPE):
		target_entity = target_handler.get_nearest_wanted(self)
		if target_entity:
			nav_agent.target_position = target_entity.global_position
	if target_handler.is_wanted(TYPE):
		target_entity = target_handler.get_nearest_enemy(self)
		if target_entity:
			nav_agent.target_position = target_entity.global_position
	if !target_entity:
		ready_for_attack = false
		nav_agent.target_position = global_position

func nav_handle_movement(delta) -> void:
	next_position = nav_agent.get_next_path_position()
	var direction = (next_position - global_position).normalized()
	
	# Normalize the direction to ensure consistent movement speed in all directions
	if direction != Vector2.ZERO:
		direction = direction.normalized()
	
	if nav_agent.is_navigation_finished() or ready_for_attack or attacking:
		direction = Vector2.ZERO
	
	handle_movement(direction, delta)

func handle_movement(direction: Vector2, delta):
	var new_velocity: Vector2
	var factored_speed = SPEED
	var factored_acceleration = ACCELERATION
	
	if is_player:
		factored_speed *= player_handler.PLAYER_SPEED_FACTOR
		factored_acceleration *= player_handler.PLAYER_SPEED_FACTOR
	elif target_handler.is_wanted(TYPE):
		factored_speed *= 1.5
		factored_acceleration *= 1.5
	
	# Apply acceleration
	if direction != Vector2.ZERO:
		new_velocity = velocity.move_toward(direction * factored_speed
		*
		(0.8 + (0.2 * (Vector2.from_angle(rotation)).normalized().dot(direction.normalized()))), ACCELERATION * delta)
	# Apply deceleration when there's no input
	else:
		new_velocity = velocity.move_toward(Vector2.ZERO, factored_acceleration * delta)
	
	if is_player:
		velocity = new_velocity
		#move_and_collide(velocity * delta)
		move_and_slide()
	else:
		nav_agent.set_velocity(new_velocity)

func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	if !is_player:
		velocity = safe_velocity
		move_and_slide()

func nav_handle_rotation(delta) -> void:
	#if attacking: return
	# Get the mouse position and calculate the angle to face it
	var target_position = next_position
	if target_lookat: target_position = target_lookat
	var angle_to_look = (target_position - global_position).angle()
	
	rotation = rotate_toward(rotation, angle_to_look, 10 * delta)

func check_attack_area():
	var found = false
	for body in attack_detection_area.get_overlapping_bodies():
		if body is CharacterBody2D:
			if target_handler.should_attack(TYPE, body.TYPE) and !body.dead:
				found = true
	ready_for_attack = found

# ============================================================
# PLAYER SCRIPTS
# ============================================================

func player_handle_movement(delta: float) -> void:
	var direction = Vector2.ZERO
	
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
	
	#if attacking: 
		#direction = Vector2.ZERO
	
	handle_movement(direction, delta)

func player_handle_rotation(delta) -> void:
	# Get the mouse position and calculate the angle to face it
	#if attacking: return
	var mouse_position = get_global_mouse_position()
	var angle_to_mouse = (mouse_position - global_position).angle()
	
	rotation = rotate_toward(rotation, angle_to_mouse, 10 * delta)

func _input(event: InputEvent) -> void:
	if (is_player and !attacking and 
		event is InputEventMouseButton and event.is_pressed() and 
		event.button_index == MOUSE_BUTTON_LEFT):
		attack()

func pickup(type):
	player_handler.pickup(type)

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
			if target_handler.should_attack(TYPE, entity.TYPE):
				entity.apply_damage(2)

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
	
	await get_tree().create_timer(0.4).timeout
	target_handler.die(self)
