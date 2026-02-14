extends Node2D

@onready var target_handler = $"TargetHandler"
@onready var switch_handler = $"SwitchHandler"
@onready var behaviour_handler = $"BehaviourHandler"
@onready var player_handler = $"PlayerHandler"

@onready var tilemap = $"LightsLayer"

@onready var camera = $"Camera"

@onready var types_navigation = {
	'circle': $Navigation,
	'triangle': $Navigation,
	'square': $Navigation
}

var pickup = preload("res://Scenes/pickup.tscn")

var wanted = 'triangle'

func _ready() -> void:
	for c in $Navigation.get_children():
		target_handler.register(c)
		set_camera_target(c)
		wanted = c.TYPE

func set_camera_target(target):
	camera.target = target

func death_spawn(location, _type):
	# score spawn
	for i in range(int(randfn(
						player_handler.NUM_SCORE_SPAWN, 
						player_handler.NUM_SCORE_SPAWN_STDEV))):
		var score := pickup.instantiate()
		add_child(score)

		# --- random point in an annulus (uniform by area) ---
		var angle := randf_range(0.0, TAU)
		var r := sqrt(randf_range(3 * 3, 25 * 25))
		var offset := Vector2(cos(angle), sin(angle)) * r

		score.global_position = location + offset
		
		# --- direction away from center ---
		var dir := offset.normalized()
		if dir == Vector2.ZERO:
			dir = Vector2.RIGHT.rotated(randf_range(0.0, TAU))
		
		# --- outward speed + spin (Gaussian, clamped) ---
		var speed = clamp(randfn(100, 100), 20, 250)
		var spin = clamp(randfn(0.0, 8.0), -20, 20)
		score.linear_velocity = dir * speed
		score.angular_velocity = spin
		
		score.set_type("score")
	
	# mana spawn
	if randf() < player_handler.MANA_SPAWN_CHANCE:
		var mana = pickup.instantiate()
		mana.global_position = location
		add_child(mana)
		mana.set_type('mana')

func add_entity(entity):
	types_navigation[entity.TYPE].add_child(entity)
	target_handler.register(entity)
