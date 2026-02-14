extends Node2D

@export var type = 'mana'
@export var pickup_range = 500
var pickup_ranges = {
	'mana': 500,
	'score': 250,
	'health': 300,
}
@export var lifetime = 0.0
var lifetimes = {
	'mana': 10.,
	'score': 3.,
	'health': 10.,
}
var current_lifetime = 0.0

@export var speed = 800
@export var speed_lerp = 1

@onready var player_finder = $"PlayerFinder"
@onready var player_finder_shape = $"PlayerFinder/CollisionShape2D"

@onready var mana_sprite = $"ManaSprite"
@onready var health_sprite = $"HealthSprite"
@onready var score_sprite = $"ScoreSprite"

func set_type(type_str: String):
	if type_str == "mana":
		type = 'mana'
		mana_sprite.visible = true
		pickup_range = pickup_ranges[type_str]
		lifetime = lifetimes[type_str]
		player_finder_shape.shape.radius = pickup_range
		
	elif type_str == "health":
		type = 'health'
		health_sprite.visible = true
		pickup_range = pickup_ranges[type_str]
		lifetime = lifetimes[type_str]
		player_finder_shape.shape.radius = pickup_range
		
	elif type_str == "score":
		type = 'score'
		pickup_range = pickup_ranges[type_str]
		lifetime = lifetimes[type_str]
		player_finder_shape.shape.radius = pickup_range
		
		var r := randf_range(4.0, 8.0)
		var poly := make_shard_polygon(r, 0.4)
		poly = roughen_polygon(poly, 1, 2.0)
		var vis := Polygon2D.new()
		vis.polygon = poly
		vis.color = Color.BLACK
		add_child(vis)

func _physics_process(delta: float) -> void:
	var player_seen = false
	for player in player_finder.get_overlapping_bodies():
		if player is CharacterBody2D:
			if player.is_player:
				player_seen = true
				move_towards_player(delta, player)
	if !player_seen:
		if lifetime and current_lifetime < lifetime:
			current_lifetime += delta
			modulate.a = 1. - (current_lifetime/lifetime) * 0.5
		else: queue_free()

func move_towards_player(delta, player: CharacterBody2D):
	var dist = player.global_position.distance_to(global_position)
	
	global_position += delta * speed * pow((1. - (dist / pickup_range)),4) * (player.global_position - global_position).normalized()
	
	if dist < 20:
		pickup(player)

func pickup(player: CharacterBody2D):
	# animation
	player.pickup(type)
	queue_free()

func make_shard_polygon(
	avg_radius: float,
	radius_jitter: float = 0.35,
	vertex_count_range := Vector2i(6, 11),
	angle_jitter: float = 0.25
) -> PackedVector2Array:
	var n := randi_range(vertex_count_range.x, vertex_count_range.y)

	# Build increasing angles so polygon doesn't self-intersect.
	var angles := PackedFloat32Array()
	angles.resize(n)
	for i in n:
		angles[i] = TAU * float(i) / float(n)
		angles[i] += randf_range(-angle_jitter, angle_jitter) * (TAU / float(n))

	angles.sort()

	var poly := PackedVector2Array()
	poly.resize(n)

	for i in n:
		var a := angles[i]
		var r := avg_radius * (1.0 + randf_range(-radius_jitter, radius_jitter))
		poly[i] = Vector2(cos(a), sin(a)) * r

	# Make sure winding is consistent (helps some geometry/physics cases)
	if Geometry2D.is_polygon_clockwise(poly):
		poly.reverse()
	
	
	return poly

func roughen_polygon(poly: PackedVector2Array, splits := 1, roughness := 3.0) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		out.append(a)

		for s in splits:
			var t := float(s + 1) / float(splits + 1)
			var p := a.lerp(b, t)

			# offset perpendicular to edge
			var edge := (b - a)
			var nrm := Vector2(-edge.y, edge.x).normalized()
			p += nrm * randf_range(-roughness, roughness)

			out.append(p)

	return out
