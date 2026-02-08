extends Area2D

@export var speed: float = 600.0
@export var lifetime: float = 0.5

var enemies = []
var direction: Vector2 = Vector2.RIGHT

func _ready():
	# Delete bullet after lifetime expires
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta):
	global_position += direction * speed * delta

func _on_body_entered(body):
	if body is CharacterBody2D:
		if body.TYPE in enemies and !body.dead:
			body.apply_damage(1)
			queue_free()
	else:
		queue_free()
