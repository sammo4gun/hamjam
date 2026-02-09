extends Node2D

@export var type = 'mana'
@export var pickup_range = 500
@export var speed = 800
@export var speed_lerp = 1

@onready var player_finder = $"PlayerFinder"
@onready var player_finder_shape = $"PlayerFinder/CollisionShape2D"

func _ready() -> void:
	player_finder_shape.shape.radius = pickup_range

func _physics_process(delta: float) -> void:
	for player in player_finder.get_overlapping_bodies():
		if player is CharacterBody2D:
			if player.is_player:
				move_towards_player(delta, player)

func move_towards_player(delta, player: CharacterBody2D):
	var dist = player.global_position.distance_to(global_position)
	
	global_position += delta * speed * pow((1. - (dist / pickup_range)),4) * (player.global_position - global_position).normalized()
	
	if dist < 20:
		pickup(player)

func pickup(player: CharacterBody2D):
	# animation
	player.pickup(type)
	queue_free()
