extends Node2D

@onready var circle1: CharacterBody2D = $CircleNavigation/Circle

@onready var target_handler = $"TargetHandler"
@onready var switch_handler = $"SwitchHandler"
@onready var camera = $"Camera"

@onready var types_navigation = {
	'circle': $CircleNavigation,
	'triangle': $CircleNavigation,
	'square': $SquareNavigation
}

var wanted = 'circle'

func _ready() -> void:
	target_handler.register(circle1)
	set_camera_target(circle1)

func set_camera_target(target):
	camera.target = target

func add_entity(entity):
	types_navigation[entity.TYPE].add_child(entity)
	target_handler.register(entity)
