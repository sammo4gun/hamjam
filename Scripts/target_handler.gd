extends Node

var entity_dict = {}

func register(entity, type):
	entity_dict[type] = entity_dict.get(type, []) + [entity]
	entity.target_handler = self
	if type == get_parent().wanted:
		entity.is_wanted = true

func get_nearest_wanted(entity) -> CharacterBody2D:
	var wanted = get_parent().wanted
	# gets the nearest entity of the 'wanted' type from the specified entity
	var nearest = null
	var dist = 100000000
	for wanted_entity in entity_dict.get(wanted, []):
		var entity_dist = entity.global_position.distance_to(wanted_entity.global_position)
		if entity_dist < dist:
			nearest = wanted_entity
			dist = entity_dist
	
	return nearest
	
func get_nearest_enemy(entity) -> CharacterBody2D:
	var wanted = get_parent().wanted
	# gets the nearest entity of the 'wanted' type from the specified entity
	var nearest = null
	var dist = 100000000
	for entity_type in entity_dict.keys():
		if entity_type != wanted:
			for enemy_entity in entity_dict.get(entity_type, []):
				var entity_dist = entity.global_position.distance_to(enemy_entity.global_position)
				if entity_dist < dist:
					nearest = enemy_entity
					dist = entity_dist
	
	return nearest
