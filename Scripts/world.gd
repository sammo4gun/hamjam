extends Node2D

@onready var square1: CharacterBody2D = $SquareNavigation/Square
@onready var square2: CharacterBody2D = $SquareNavigation/Square2
@onready var square3: CharacterBody2D = $SquareNavigation/Square3
@onready var circle1: CharacterBody2D = $CircleNavigation/Circle
@onready var circle2: CharacterBody2D = $CircleNavigation/Circle2
@onready var circle3: CharacterBody2D = $CircleNavigation/Circle3

@onready var target_handler = $"TargetHandler"

var wanted = 'circle'

func _physics_process(delta: float) -> void:
	target_handler.register(square1, 'square')
	target_handler.register(square2, 'square')
	target_handler.register(square3, 'square')
	target_handler.register(circle1, 'circle')
	target_handler.register(circle2, 'circle')
	target_handler.register(circle3, 'circle')
