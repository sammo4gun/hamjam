extends Node

@onready var world = get_parent()

@export var TIME_TILL_WANTED = 3.

var switcher
var switchee

func _process(delta: float) -> void:
	if !world.game_fadeout:
		if Engine.time_scale < 0.99:
			Engine.time_scale = lerpf(Engine.time_scale, 1.0, delta * 2.)
		else: Engine.time_scale = 1.0

func switch_available(entity):
	var new_switcher = null
	var new_switchee = null
	
	if entity.player_handler:
		if entity.player_handler.can_switch:
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
	var current_switcher = switcher
	var current_switchee = switchee
	
	current_switcher.player_handler.switch()
	
	current_switcher.is_player = false
	current_switcher.die()
	
	world.new_player(current_switchee)
	current_switchee.activate_glitch(4.0)
	current_switchee.invincible = 3.0
	Engine.time_scale = 0.2
	world.set_camera_target(current_switchee)
	await get_tree().create_timer(0.5).timeout
	current_switchee.is_player = true
	
	await get_tree().create_timer(TIME_TILL_WANTED).timeout
	
	world.swap_wanted(new_type)
