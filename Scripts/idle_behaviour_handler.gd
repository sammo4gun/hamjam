extends Node

@onready var world = get_parent()

var world_min_x = -1150
var world_max_x = 1150
var world_min_y = -640
var world_max_y = 640

func get_visible_entities(visible_area: Area2D) -> Array:
	var entities = []
	for body in visible_area.get_overlapping_bodies():
		if body is CharacterBody2D:
			entities.append(body)
	return entities

func get_behaviour(entity: CharacterBody2D, visible_entities: Array):
	var my_type = entity.TYPE
	var good_guys = 0
	var bad_guys = 0
	for i in visible_entities:
		if world.target_handler.should_attack(my_type, i.TYPE):
			bad_guys += 1
		else: good_guys += 1
	if bad_guys == 0:
		return 'idle'
	if good_guys >= bad_guys:
		return 'attack'
	return 'flee'

# these return an array with 2 vector2ds, first one is target, second is look_target
func idle_target(entity: CharacterBody2D, visible_entities: Array,
					nav_map, shyness = 200):
		
	if world.wanted == entity.TYPE:
		for player in visible_entities:
			if player is CharacterBody2D:
				if player.is_player:
					var dist
					if player.global_position.distance_to(entity.global_position) < shyness:
						dist = (entity.global_position - player.global_position).normalized() * 10
						return [entity.global_position + dist, player.global_position]
					dist = (player.global_position - entity.global_position).length() - shyness
					return [entity.global_position + (player.global_position - entity.global_position).limit_length(dist), player.global_position]
	
	var wander_targets = [entity.wander_target]
	
	for friend in visible_entities:
		if friend is CharacterBody2D:
			if friend.TYPE == entity.TYPE:
				if friend.wander_target:
					wander_targets.append(friend.wander_target)
	
	var sum_target = Vector2(0,0)
	for i in wander_targets:
		sum_target += i
	
	return [NavigationServer2D.map_get_closest_point(nav_map, sum_target/len(wander_targets)), null]

func pick_wander_target():
	var desired = Vector2(	randf_range(world_min_x, world_max_x), 
							randf_range(world_min_y, world_max_y))
	return desired

func flee_target(entity: CharacterBody2D, visible_entities: Array, nav_map, flee_distance := 300.0):
	var closest_enemy : CharacterBody2D = null
	var closest_dist = 10000
	for enemy in visible_entities:
		if enemy is CharacterBody2D:
			if world.target_handler.should_attack(enemy.TYPE, entity.TYPE):
				var dist = enemy.global_position.distance_to(entity.global_position)
				if dist < closest_dist:
					closest_enemy = enemy
					closest_dist = dist
	
	var away_dir = (entity.global_position - closest_enemy.global_position).normalized()
	var desired_pos = entity.global_position + away_dir * flee_distance
	
	desired_pos = Vector2(
		desired_pos.x,
		desired_pos.y
	)
	
	# Snap to nearest valid nav position
	var safe_pos = NavigationServer2D.map_get_closest_point(nav_map, desired_pos)
	
	return safe_pos
