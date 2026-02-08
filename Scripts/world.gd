extends Node2D

@onready var square1: CharacterBody2D = $SquareNavigation/Square
@onready var square2: CharacterBody2D = $SquareNavigation/Square2
@onready var square3: CharacterBody2D = $SquareNavigation/Square3
@onready var circle: CharacterBody2D = $SquareNavigation/Circle

func _physics_process(delta: float) -> void:
	square1.set_target(circle.global_position)
	square2.set_target(circle.global_position)
	square3.set_target(circle.global_position)
