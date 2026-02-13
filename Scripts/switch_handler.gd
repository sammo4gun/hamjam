extends Node

@onready var world = get_parent()

@export var TIME_TILL_WANTED = 3.

var switcher
var switchee

func switch_available(entity):
	var new_switcher = null
	var new_switchee = null
	
	var switch_finder : RayCast2D = entity.switch_finder
	if switch_finder.is_colliding():
		var collider = switch_finder.get_collider()
		if collider is CharacterBody2D:
			if collider.TYPE != entity.TYPE and !collider.dead:
				new_switcher = entity
				new_switchee = collider
	
	if new_switchee and switchee != new_switchee:
		set_switchee(new_switchee, true)
		if switchee: set_switchee(switchee, false)
	if !new_switchee and switchee != new_switchee:
		set_switchee(switchee, false)
	
	switcher = new_switcher
	switchee = new_switchee

func set_switchee(entity, toggle):
	pass # sets a target as switchable, we can do some visual effects

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("switch"):
		if switcher:
			switch()

func switch():
	var new_type = switchee.TYPE
	switcher.is_player = false
	switcher.die()
	switchee.is_player = true
	world.set_camera_target(switchee)
	
	await get_tree().create_timer(TIME_TILL_WANTED).timeout
	
	swap_wanted(new_type)

func swap_wanted(type):
	world.wanted = type
