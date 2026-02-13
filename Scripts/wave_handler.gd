extends Node2D

@onready var spawn_areas = get_children()

var square_entity = preload("res://Scenes/square.tscn")
var circle_entity = preload("res://Scenes/circle.tscn")
var triangle_entity = preload("res://Scenes/triangle.tscn")

var type_dict = {
	'square': square_entity,
	'triangle': triangle_entity,
	'circle': circle_entity
}

@export var SPAWN = true

@export var WAVE_WAIT = 6
@export var WAVE_DURATION: float = 5.0
@export var max_attempts_per_spawn: int = 10

@onready var world = get_parent()

var spawn_counts := {
	'circle': 0,
	'triangle': 0,
	'square': 0
}
var spawned := {
	'circle': 0,
	'triangle': 0,
	'square': 0
}
var spawn_interval = 0
var current_wave_wait = WAVE_WAIT
var current_spawn_interval = spawn_interval
var total_to_spawn = 0

var current_wave = 0

var spawning = false

func start_spawn():
	spawning = true
	current_wave += 1
	print("NEW WAVEEE!!!")
	print("wave:", current_wave)
	var total_to_spawn = 3 + int(current_wave * 1.5)
	# define what to spawn
	var all_types = ['circle', 'triangle', 'square']
	all_types.erase(world.wanted)
	spawn_counts = {
		'circle': 0,
		'triangle': 0,
		'square': 0
	}
	for i in range(total_to_spawn):
		var type = all_types.pick_random()
		spawn_counts[type] += 1
	
	spawn_interval = WAVE_DURATION / float(get_dict_sum(spawn_counts))

func end_spawn():
	spawning = false
	for k in spawn_counts.keys():
		spawn_counts[k] = 0
		spawned[k] = 0
	current_wave_wait = WAVE_WAIT * (0.5 * current_wave)

func _physics_process(delta: float) -> void:
	if current_wave_wait <= 0 and !spawning and SPAWN:
		start_spawn()
	elif current_wave_wait <= 0 and spawning:
		if current_spawn_interval <= 0:
			if get_dict_sum(spawned) < get_dict_sum(spawn_counts):
				var type = try_spawn_entity()
				if type:
					spawned[type] += 1
				current_spawn_interval = spawn_interval
			else:
				end_spawn()
		else: current_spawn_interval -= delta
	else: 
		current_wave_wait -= delta

func try_spawn_entity():
	var spawn_area = spawn_areas.pick_random()
	var shape: RectangleShape2D = spawn_area.get_node("CollisionShape2D").shape
	var space_state := get_world_2d().direct_space_state

	for i in max_attempts_per_spawn:
		var point = get_random_point_in_shape(shape)

		var params := PhysicsPointQueryParameters2D.new()
		params.position = spawn_area.global_position + point
		params.collide_with_bodies = true
		params.collide_with_areas = false

		var result = space_state.intersect_point(params)

		if result.is_empty():
			return spawn_entity_at(params.position)

	print("Failed to find free spawn position")

func get_random_point_in_shape(shape):
	if shape is RectangleShape2D:
		var rect = shape.get_rect()
		return Vector2(
			randi_range(rect.position.x, rect.position.x+rect.size.x),
			randi_range(rect.position.y, rect.position.y+rect.size.y)
		)
	return Vector2.ZERO

func spawn_entity_at(pos: Vector2):
	var type = pick_type()
	var entity = type_dict[type].instantiate()
	entity.global_position = pos
	
	world.add_entity(entity)
	return type

func pick_type():
	var potentials = []
	for k in spawn_counts.keys():
		for i in range(spawn_counts[k] - spawned[k]):
			potentials.append(k)
	var picked_type = potentials.pick_random()
	return picked_type


func get_dict_sum(spawn_dict) -> int:
	var i = 0
	for k in spawn_dict.values():
		i += k
	return i
