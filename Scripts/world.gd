extends Node2D

@onready var square1: CharacterBody2D = $SquareNavigation/Square
@onready var square2: CharacterBody2D = $SquareNavigation/Square2
@onready var square3: CharacterBody2D = $SquareNavigation/Square3
@onready var circle1: CharacterBody2D = $CircleNavigation/Circle
@onready var circle2: CharacterBody2D = $CircleNavigation/Circle2
@onready var circle3: CharacterBody2D = $CircleNavigation/Circle3
@onready var triangle1: CharacterBody2D = $CircleNavigation/Triangle
@onready var triangle2: CharacterBody2D = $CircleNavigation/Triangle2
@onready var triangle3: CharacterBody2D = $CircleNavigation/Triangle3

@onready var target_handler = $"TargetHandler"
@onready var switch_handler = $"SwitchHandler"
@onready var camera = $"Camera"

var wanted = 'circle'

func _ready() -> void:
	target_handler.register(square1)
	target_handler.register(square2)
	target_handler.register(square3)
	
	target_handler.register(circle1)
	set_camera_target(circle1)
	target_handler.register(circle2)
	target_handler.register(circle3)
	
	target_handler.register(triangle1)
	target_handler.register(triangle2)
	target_handler.register(triangle3)

func set_camera_target(target):
	camera.target = target
