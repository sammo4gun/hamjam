extends Node2D

@onready var target_handler = $"TargetHandler"
@onready var switch_handler = $"SwitchHandler"
@onready var behaviour_handler = $"BehaviourHandler"
@onready var player_handler = $"PlayerHandler"

@onready var wanted_indicator = $"Camera/CanvasLayer/WantedIndicator"
@onready var health_indicator = $"Camera/CanvasLayer/HealthIndicator"
@onready var paused_indicator = $"Camera/CanvasLayer/PausedLabel"
@onready var end_game_screen = $"Camera/CanvasLayer/EndGameScreen"

@onready var tilemap = $"LightsLayer"

@onready var camera = $"Camera"

@onready var types_navigation = {
	'circle': $Navigation,
	'triangle': $Navigation,
	'square': $Navigation
}

var square_entity = preload("res://Scenes/square.tscn")
var circle_entity = preload("res://Scenes/circle.tscn")
var triangle_entity = preload("res://Scenes/triangle.tscn")

var type_dict = {
	'square': square_entity,
	'triangle': triangle_entity,
	'circle': circle_entity
}

@onready var hit_layer = $"Camera/CanvasLayer/HitLayer"

var start_spawn_type = 'circle'

var pickup = preload("res://Scenes/pickup.tscn")

var wanted = 'triangle'

var game_started = false
var game_fadeout = false

var time = 0

func _ready() -> void:
	Engine.time_scale = 1.
	hit_layer.material.set_shader_parameter("intensity", 0.0)
	get_tree().paused = true

func _process(delta: float) -> void:
	time += delta
	if game_fadeout:
		if camera.zoom.x > 0.5:
			camera.zoom.x = lerpf(camera.zoom.x, 0.5, delta * 0.6)
			camera.zoom.y = lerpf(camera.zoom.y, 0.5, delta * 0.6)
		if Engine.time_scale > 0.01:
			Engine.time_scale = lerpf(Engine.time_scale, 0.0, delta * 2.)
		else: 
			Engine.time_scale = 0.0
	else:
		if camera.zoom.x < 1.:
			camera.zoom.x = lerpf(camera.zoom.x, 1., delta * 2.)
			camera.zoom.y = lerpf(camera.zoom.y, 1., delta * 2.)


func _input(event: InputEvent) -> void:
	if game_fadeout and Engine.time_scale < 0.2:
		if event is InputEventKey or event is InputEventMouseButton and event.pressed:
			get_tree().reload_current_scene()

func start_game() -> void:
	game_started = true
	wanted = start_spawn_type
	wanted_indicator.set_wanted(wanted)
	
	var entity = type_dict[start_spawn_type].instantiate()
	entity.global_position = Vector2(0, 0)
	add_entity(entity)
	set_camera_target(entity)
	new_player(entity)
	
	for pos in [
		Vector2(100, 100),
		Vector2(-100, 100),
		Vector2(100, -100),
		Vector2(-100, -100),
	]:
		entity = type_dict[start_spawn_type].instantiate()
		entity.global_position = pos
		add_entity(entity)

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

func swap_wanted(type):
	wanted = ''
	wanted_indicator.set_wanted(null)
	await get_tree().create_timer(0.5).timeout
	wanted = type
	wanted_indicator.set_wanted(type)

func new_player(entity):
	entity.is_player = true
	health_indicator.set_health(entity.health, entity.MAX_HEALTH)

func player_hit(damage: int, player: CharacterBody2D):
	health_indicator.set_health(max(0, player.health), player.MAX_HEALTH)
	if player.health > 0:
		var tween = create_tween()
		tween.tween_property(hit_layer.material, "shader_parameter/intensity", 1.0, 0.1)
		tween.tween_property(hit_layer.material, "shader_parameter/intensity", 0.0, 0.5)
		
		camera.shake_power = 6 * damage
	else:
		# player died
		camera.shake_power = 12
		hit_layer.material.set_shader_parameter("intensity", 1.0)
		end_game()

func end_game():
	game_fadeout = true
	end_game_screen.visible = true
	Globals.first_run_done = true
	Globals.high_score = max(player_handler.score, Globals.high_score)
	Globals.longest_time_s = max(int(time), Globals.longest_time_s)
	end_game_screen.text = """
	TIME                            %02d:%02d
	SCORE                      %s
	
	LONGEST TIME            %02d:%02d
	HIGH_SCORE            %s
	
	READY TO START?
	""" % [int(time) / 60, int(time) % 60, str(player_handler.score).pad_zeros(7), 
	Globals.longest_time_s / 60, Globals.longest_time_s % 60, str(Globals.high_score).pad_zeros(7)]

func set_mana(mana):
	health_indicator.set_mana(mana)

func set_score(score):
	health_indicator.set_score(score)
