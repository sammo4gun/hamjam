extends Node

var entity_dict = {}

@onready var world = get_parent()

func register(entity):
	entity_dict[entity.TYPE] = entity_dict.get(entity.TYPE, []) + [entity]
	entity.target_handler = self
	entity.switch_handler = world.switch_handler
	entity.behaviour_handler = world.behaviour_handler
	entity.player_handler = world.player_handler

func get_nearest_wanted(entity) -> CharacterBody2D:
	var wanted = world.wanted
	# gets the nearest entity of the 'wanted' type from the specified entity
	var nearest = null
	var dist = 100000000
	for wanted_entity in entity_dict.get(wanted, []):
		if wanted_entity:
			if !wanted_entity.dead:
				var entity_dist = entity.global_position.distance_to(wanted_entity.global_position)
				if entity_dist < dist:
					nearest = wanted_entity
					dist = entity_dist
	
	return nearest

func is_wanted(type) -> bool:
	return type == world.wanted

func should_attack(type, target_type) -> bool: # returns true if you should attack
	if type == world.wanted:
		return target_type != type
	return target_type == world.wanted

func get_enemies(type) -> Array:
	if type != world.wanted:
		return [world.wanted]
	
	var output = []
	for target in entity_dict.keys():
		if target != type: output.append(target)
	return output

func get_nearest_enemy(entity) -> CharacterBody2D:
	var wanted = get_parent().wanted
	# gets the nearest entity of the 'wanted' type from the specified entity
	var nearest = null
	var dist = 100000000
	for entity_type in entity_dict.keys():
		if entity_type != wanted:
			for enemy_entity in entity_dict.get(entity_type, []):
				if enemy_entity:
					if !enemy_entity.dead:
						var entity_dist = entity.global_position.distance_to(enemy_entity.global_position)
						if entity_dist < dist:
							nearest = enemy_entity
							dist = entity_dist
	
	return nearest

func die(entity):
	world.death_spawn_mana(entity.global_position, entity.TYPE)
	
	if entity in entity_dict[entity.TYPE]:
		entity_dict[entity.TYPE].erase(entity)
	entity.queue_free()
