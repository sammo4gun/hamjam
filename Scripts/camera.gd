extends Camera2D

@export var target: Node2D
@export var follow_speed: float = 6.0

@export var shake_strength: float = 30.0
@export var shake_decay: float = 5.0

var shake_power: float = 0.0

func _process(delta):
	if not target:
		return

	global_position = global_position.lerp(
		target.global_position,
		follow_speed * delta
	)

	if shake_power > 0:
		shake_power = lerp(shake_power, 0.0, shake_decay * delta)
		offset = Vector2(
			randf_range(-shake_power, shake_power),
			randf_range(-shake_power, shake_power)
		)
	else:
		offset = Vector2.ZERO
