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

@export var i_am_a_square = false

# ShaderMaterials
@onready var glitch_main = $"Main".material as ShaderMaterial
@onready var glitch_q1 = $"Q1".material as ShaderMaterial
@onready var glitch_q2 = $"Q2".material as ShaderMaterial
@onready var glitch_q3 = $"Q3".material as ShaderMaterial
@onready var glitch_q4 = $"Q4".material as ShaderMaterial

# Colors
@export var damage_color: Color = Color("#dc1414")
@export var shoot_color: Color = Color("#ffffff")
@export var flash_duration: float = 0.35
@export var shoot_flash_duration: float = 0.65

# State
var rest_offsets = []
var velocities = []
var base_colors = []
var color_flash_progress = []
var color_flash_progress_main = 0.0

var glitch_timer = 0.0
var glitch_max_timer = 0.0

var object_velocity = Vector2.ZERO
var time = 0.0

# -----------------------------
# Initialization
# -----------------------------ss
func _ready():
	var base_color = Color("#fdfe89")
	$AttackAnim.modulate = Color.WHITE
	# Set initial shader color for main
	glitch_main.set_shader_parameter("u_color", base_color)
	for c in corners:
		c.top_level = false
		# Set initial shader color for corners
		c.get_material().set_shader_parameter("u_color", base_color)
		rest_offsets.append(c.position)
		velocities.append(Vector2.ZERO)
		base_colors.append(base_color)
		color_flash_progress.append(0.0)

# -----------------------------
# Physics update
# -----------------------------
func _physics_process(delta):
	time += delta

	# Main flash
	if color_flash_progress_main > 0.0:
		color_flash_progress_main -= delta / shoot_flash_duration
		color_flash_progress_main = max(color_flash_progress_main, 0.0)
		var main_color = shoot_color.lerp(base_colors[0], 1.0 - color_flash_progress_main)
		glitch_main.set_shader_parameter("u_color", main_color)

	# Glitch effect decay
	if glitch_timer > 0.0:
		glitch_timer -= delta
		var shake_value = 0.3 * glitch_timer / glitch_max_timer
		glitch_main.set_shader_parameter("shake_power", shake_value)
		glitch_q1.set_shader_parameter("shake_power", shake_value)
		glitch_q2.set_shader_parameter("shake_power", shake_value)
		glitch_q3.set_shader_parameter("shake_power", shake_value)
		glitch_q4.set_shader_parameter("shake_power", shake_value)
	else:
		stop_glitch()

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

		# corner color flash
		if color_flash_progress[i] > 0.0:
			color_flash_progress[i] -= delta / flash_duration
			color_flash_progress[i] = max(color_flash_progress[i], 0.0)
			var corner_color = damage_color.lerp(base_colors[i], 1.0 - color_flash_progress[i])
			c.get_material().set_shader_parameter("u_color", corner_color)

# -----------------------------
# External velocity for trailing
# -----------------------------
func set_velocity(vel: Vector2) -> void:
	object_velocity = vel

# -----------------------------
# Glitch control
# -----------------------------
func activate_glitch(period):
	glitch_max_timer = period
	glitch_timer = period
	glitch_main.set_shader_parameter("shake_rate", 1)
	glitch_q1.set_shader_parameter("shake_rate", 1)
	glitch_q2.set_shader_parameter("shake_rate", 1)
	glitch_q3.set_shader_parameter("shake_rate", 1)
	glitch_q4.set_shader_parameter("shake_rate", 1)

func stop_glitch():
	glitch_max_timer = 0.0

# -----------------------------
# Damage push for corners
# -----------------------------
func apply_damage_push():
	for i in range(corners.size()):
		var dir = rest_offsets[i]
		if dir.length() != 0:
			dir = dir.normalized()
			velocities[i] += dir * damage_push_strength

		# flash corners
		color_flash_progress[i] = 1.0
		corners[i].get_material().set_shader_parameter("u_color", damage_color)

# -----------------------------
# Shoot / knockback opposite facing
# -----------------------------
func apply_shoot_push():
	# main facing in local space
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

	# main flash
	color_flash_progress_main = 1.0
	glitch_main.set_shader_parameter("u_color", shoot_color)
	
	$AttackAnim.frame = 0
	if i_am_a_square:
		$AttackAnim.play("square_attack")
	else:
		$AttackAnim.play("default")
