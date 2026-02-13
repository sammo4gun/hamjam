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

var mana_pickup = preload("res://Scenes/mana_pickup.tscn")

var wanted = 'triangle'

func _ready() -> void:
	for c in $Navigation.get_children():
		target_handler.register(c)
		set_camera_target(c)
		wanted = c.TYPE

func set_camera_target(target):
	camera.target = target

func death_spawn_mana(location, _type):
	var mana = mana_pickup.instantiate()
	mana.global_position = location
	add_child(mana)

func add_entity(entity):
	types_navigation[entity.TYPE].add_child(entity)
	target_handler.register(entity)
