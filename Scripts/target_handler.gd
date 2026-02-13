extends Node

var LIGHT_RADIUS = 200
var PLAYER_LIGHT_RADIUS = 300

var entity_dict = {}
var lights_on = {}

@onready var world = get_parent()

func register(entity):
	entity_dict[entity.TYPE] = entity_dict.get(entity.TYPE, []) + [entity]
	entity.target_handler = self
	entity.switch_handler = world.switch_handler
	entity.behaviour_handler = world.behaviour_handler
	entity.player_handler = world.player_handler

func _process(delta: float) -> void:
	update_tile_lights()
	pass

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

func update_tile_lights():
	var new_lights_on = {}
	for entity_type in entity_dict:
		for entity in entity_dict[entity_type]:
			if entity:
				var entity_lights = get_lights_on(entity)
				for i in entity_lights:
					if i in new_lights_on:
						new_lights_on[i] = max(new_lights_on[i], entity_lights[i])
					else: 
						new_lights_on [i] = entity_lights[i]
	
	for light in new_lights_on:
		if not light in lights_on:
			set_tile_light(light, true, new_lights_on[light])
		elif new_lights_on[light] != lights_on[light]:
			set_tile_light(light, true, new_lights_on[light])
	
	for light in lights_on:
		if not light in new_lights_on:
			set_tile_light(light, false)
	
	lights_on = new_lights_on

func get_lights_on(entity: CharacterBody2D):
	if !entity: return {}
	var pos = world.tilemap.local_to_map(
		world.tilemap.to_local(entity.global_position)
	)
	var radius_pixels = LIGHT_RADIUS
	if entity.dead:
		radius_pixels /= 2
	var tile_size = world.tilemap.tile_set.tile_size
	var radius_in_tiles = int(ceil(radius_pixels / tile_size.x))
	
	var on_lights = {}

	for x in range(pos.x - radius_in_tiles, pos.x + radius_in_tiles + 1):
		for y in range(pos.y - radius_in_tiles, pos.y + radius_in_tiles + 1):
			var cell = Vector2i(x, y)
			if world.tilemap.get_cell_source_id(cell) == -1:
				continue
			
			var tile_world_pos = world.tilemap.map_to_local(cell)
			tile_world_pos = world.tilemap.to_global(tile_world_pos)
			
			if has_light(cell):
				if tile_world_pos.distance_to(entity.global_position) <= radius_pixels:
					if entity.is_player:
						on_lights[cell] = 2
					elif world.wanted != entity.TYPE:
						on_lights[cell] = 3
					else:
						on_lights[cell] = 1
	
	return on_lights

func set_tile_light(cell: Vector2i, on: bool, color: int = 0):
	var source_id = world.tilemap.get_cell_source_id(cell)
	if source_id == -1:
		return
	var atlas = world.tilemap.get_cell_atlas_coords(cell)
	
	if on:
		world.tilemap.set_cell(cell, source_id, atlas, color)
	else: 
		world.tilemap.set_cell(cell, source_id, atlas, 0)

func has_light(cell: Vector2i):
	return world.tilemap.get_cell_atlas_coords(cell) == Vector2i(1,1)
