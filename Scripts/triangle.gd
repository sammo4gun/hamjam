extends CharacterBody2D

var TYPE = 'triangle'

#export vars
@export var SPEED = 200.0
@export var IDLE_SLOWDOWN = 0.6
@export var ACCELERATION : float = 1200
@export var DECELERATION : float = 2000

@export var MAX_HEALTH = 5
var health = MAX_HEALTH

@export var ATTACK_TIME = 0.1
@export var ATTACK_COOLDOWN = 0.1

@export var BACKUP_SLOWDOWN = 0.2
@export var BACKUP_RANGE = 300

@export var FIRE_SHOT_SPEED = 1400
@export var FIRE_RANGE = 600.0

@export var SHYNESS = 100

@export var is_player = false

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var entity_view = $EntityView
@onready var nav_map = get_world_2d().navigation_map
var next_position = global_position
var target_entity = null
var target_lookat = null

var ready_for_attack = false
var attacking = false
var backing_up = true
var cooldown = 0
@onready var attack_sprite = $"AttackSprite"
@onready var target_finder = $"TargetFinder"
@onready var switch_finder = $"SwitchFinder"

var target_handler
var switch_handler
var idle_behaviour_handler

var entities_seen = []
var behaviour = 'idle'

var dead = false

@export var bullet_scene: PackedScene = preload("res://Scenes/triangle_bullet.tscn")
@onready var fire_point: Node2D = $"FirePoint"

func _ready():
	# Optional tuning
	nav_agent.path_desired_distance = 4.0
	nav_agent.target_desired_distance = 4.0
	nav_agent.max_speed = SPEED
	target_finder.target_position = Vector2(FIRE_RANGE, 0)

func _physics_process(delta: float) -> void:
	if target_handler: # make sure this doesn't happen before we assign a target handler
		if is_player:
			player_handle_movement(delta)
			player_handle_rotation(delta)
			switch_handler.switch_available(self)
		elif target_handler.is_wanted(TYPE):
			entities_seen = idle_behaviour_handler.get_visible_entities(entity_view)
			var new_behaviour = idle_behaviour_handler.get_behaviour(self, entities_seen)
			if behaviour != new_behaviour:
				target_lookat = null
				behaviour = new_behaviour
			handle_behaviours(delta)
			nav_handle_movement(delta)
			nav_handle_rotation(delta)
		else:
			behaviour = 'attack'
			nav_find_target() # what we could do at one point is ping for this every second,
			# and just follow the target for the time that we have. this could be better for processing
			# speed
			check_target_finder()
			nav_handle_movement(delta)
			nav_handle_rotation(delta)
			if cooldown > 0: cooldown -= delta
			if ready_for_attack and !attacking and cooldown <= 0:
				attack()

func handle_behaviours(delta):
	if behaviour == 'idle':
		var info = idle_behaviour_handler.idle_target(self, entities_seen, SHYNESS)
		nav_agent.target_position = info[0]
		target_lookat = info[1]
	elif behaviour == 'flee':
		nav_agent.target_position = idle_behaviour_handler.flee_target(self, entities_seen, nav_map)
	elif behaviour == 'attack':
		nav_find_target()
		check_target_finder()
		if cooldown > 0: cooldown -= delta
		if ready_for_attack and !attacking and cooldown <= 0:
			attack()

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
	var new_velocity = Vector2.ZERO
	
	# Normalize the direction to ensure consistent movement speed in all directions
	if direction != Vector2.ZERO:
		direction = direction.normalized()
	
	if behaviour == 'idle':
		direction = direction.normalized() * IDLE_SLOWDOWN
	
	if nav_agent.is_navigation_finished() or ready_for_attack or attacking:
		direction = Vector2.ZERO
		if backing_up and not attacking:
			direction = Vector2.from_angle(rotation).rotated(PI) * BACKUP_SLOWDOWN
	else: backing_up = false
	
	# Apply acceleration
	if direction != Vector2.ZERO:
		new_velocity = velocity.move_toward(direction * SPEED
		*
		(0.8 + (0.2 * (Vector2.from_angle(rotation)).normalized().dot(direction.normalized()))), ACCELERATION * delta)
	# Apply deceleration when there's no input
	else:
		new_velocity = velocity.move_toward(Vector2.ZERO, DECELERATION * delta)
	
	nav_agent.set_velocity(new_velocity)

func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	if !is_player:
		velocity = safe_velocity
		move_and_slide()

func nav_handle_rotation(delta) -> void:
	if attacking: return
	# Get the mouse position and calculate the angle to face it
	var target_position = next_position
	if target_lookat: target_position = target_lookat
	var angle_to_look = (target_position - global_position).angle()
	
	rotation = rotate_toward(rotation, angle_to_look, 10 * delta)

func check_target_finder() -> void:
	var found = false
	if target_finder.is_colliding():
		var collider = target_finder.get_collider()
		if collider is CharacterBody2D:
			if target_handler.should_attack(TYPE, collider.TYPE) and !collider.dead:
				found = true
				ready_for_attack = true
				if global_position.distance_to(target_finder.get_collision_point()) < BACKUP_RANGE:
					backing_up = true
	if not found:
		ready_for_attack = false
		backing_up = false

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
	
	if attacking: 
		direction = Vector2.ZERO
	
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
	if attacking: return
	var mouse_position = get_global_mouse_position()
	var angle_to_mouse = (mouse_position - global_position).angle()
	
	rotation = rotate_toward(rotation, angle_to_mouse, 10 * delta)

func _input(event: InputEvent) -> void:
	if (is_player and !attacking and 
		event is InputEventMouseButton and event.is_pressed() and 
		event.button_index == MOUSE_BUTTON_LEFT):
		attack()

func attack():
	attacking = true
	await get_tree().create_timer(ATTACK_TIME).timeout
	fire()
	attack_sprite.visible = true
	attack_sprite.play()
	await attack_sprite.animation_finished
	attack_sprite.visible = false
	attacking = false
	cooldown = ATTACK_COOLDOWN

func fire():
	var bullet = bullet_scene.instantiate()
	bullet.global_position = fire_point.global_position
	bullet.direction = Vector2.from_angle(rotation)
	bullet.speed = FIRE_SHOT_SPEED
	bullet.lifetime = FIRE_RANGE / FIRE_SHOT_SPEED * 2
	bullet.enemies = target_handler.get_enemies(TYPE)
	get_tree().current_scene.add_child(bullet)

func apply_damage(amount):
	health -= amount
	if is_player:
		# damage effects?
		if health <= 0:
			# die as a player, do some cool stuff here
			die()
			pass
	else:
		# damage effects?
		if health <= 0:
			# entity dies, do some cool stuff here
			die()
			pass

func die():
	dead = true
	# death animation
	await get_tree().create_timer(0.4).timeout
	target_handler.die(self)
