extends ColorRect

@onready var glitch = material as ShaderMaterial

var timer = 0.0
var max_period = 0.0

func _process(delta):
	rotation = -get_parent().rotation
