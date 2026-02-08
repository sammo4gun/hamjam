extends Camera2D

@export var target: Node2D
@export var follow_speed: float = 6.0

func _process(delta):
	if not target:
		return

	global_position = global_position.lerp(
		target.global_position,
		follow_speed * delta
	)
