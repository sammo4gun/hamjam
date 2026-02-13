extends Area2D

@export var speed: float = 600.0
@export var lifetime: float = 0.5

@onready var ray = $"RayCast2D"

var finished_particles;

var enemies = []
var direction: Vector2 = Vector2.RIGHT

func _ready():
	# Delete bullet after lifetime expires
	await get_tree().create_timer(lifetime).timeout
	
	end_of_life()

func end_of_life(collision_normal = null):
	if finished_particles:
		var impact = finished_particles.instantiate()
		get_parent().add_child(impact)
		if collision_normal:
			impact.process_material.spread = 90
			impact.rotation = ray.get_collision_normal().angle()
		impact.global_position = global_position
		impact.emitting = true
	
	queue_free()

func _physics_process(delta):
	global_position += direction * speed * delta

func _on_body_entered(body):
	if body is CharacterBody2D:
		if body.TYPE in enemies and !body.dead:
			body.apply_damage(1)
			end_of_life(true)
	else:
		end_of_life(true)
