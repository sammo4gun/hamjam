extends Node2D

@onready var main = $Main
@onready var corners = [$Q1, $Q2, $Q3, $Q4]

@export var float_strength = 2.0
@export var float_speed = 1.5
@export var spring_strength = 200.0
@export var damping = 10.0
@export var velocity_influence = 1
@export var max_offset = 20.0
@export var damage_push_strength = 300.0
@export var shoot_push_strength = 300.0

@export var damage_color: Color = Color("#E84855")
@export var shoot_color: Color = Color("#93a8ac")
@export var flash_duration: float = 0.35
@export var shoot_flash_duration: float = 0.65

var rest_offsets = []
var velocities = []
var base_colors = []
var color_flash_progress = []
var color_flash_progress_main = 0.0

var object_velocity = Vector2.ZERO
var time = 0.0

func _ready():
	# set initial color
	var base_color = Color("#212738")
	main.modulate = base_color
	for c in corners:
		c.top_level = false
		c.modulate = base_color
		rest_offsets.append(c.position)
		velocities.append(Vector2.ZERO)
		base_colors.append(base_color)
		color_flash_progress.append(0.0)

func _physics_process(delta):
	time += delta
	
	if color_flash_progress_main > 0.0:
		color_flash_progress_main -= delta / shoot_flash_duration
		color_flash_progress_main = max(color_flash_progress_main, 0.0)
		main.modulate = shoot_color.lerp(base_colors[0], 1.0 - color_flash_progress_main)
	
	for i in range(corners.size()):
		var c = corners[i]

		# subtle floating
		var float_offset = Vector2(
			sin(time * float_speed + i * 1.3),
			cos(time * float_speed * 1.7 + i * 2.1)
		) * float_strength

		# velocity contribution in local space
		var local_velocity = object_velocity.rotated(-global_rotation)
		var velocity_offset = -local_velocity * velocity_influence * delta

		# target position
		var target = rest_offsets[i] + float_offset + velocity_offset

		# spring-damper physics
		var displacement = target - c.position
		if displacement.length() > max_offset:
			displacement = displacement.normalized() * max_offset

		var acceleration = displacement * spring_strength

		velocities[i] += acceleration * delta
		velocities[i] -= velocities[i] * damping * delta
		c.position += velocities[i] * delta

		# color flash back to base
		if color_flash_progress[i] > 0.0:
			color_flash_progress[i] -= delta / flash_duration
			color_flash_progress[i] = max(color_flash_progress[i], 0.0)
			c.modulate = damage_color.lerp(base_colors[i], 1.0 - color_flash_progress[i])

func set_velocity(vel: Vector2) -> void:
	object_velocity = vel

func apply_damage_push():
	for i in range(corners.size()):
		var dir = rest_offsets[i]
		if dir.length() != 0:
			dir = dir.normalized()
			velocities[i] += dir * damage_push_strength

		# color flash
		corners[i].modulate = damage_color
		color_flash_progress[i] = 1.0

func apply_shoot_push():
	var facing_global = main.global_transform.x.normalized().rotated(deg_to_rad(90))
	var facing_local = facing_global.rotated(-global_rotation)
	var knockback_dir = facing_local 

	for i in range(corners.size()):
		var dir = rest_offsets[i]
		if dir.length() != 0:
			dir = dir.normalized()
			# blend: mostly facing direction, small radial component
			dir = (dir * 0.3 + knockback_dir * 0.7).normalized()
			velocities[i] += dir * shoot_push_strength

	# main sprite flash
	main.modulate = shoot_color
	color_flash_progress_main = 1.0

	
