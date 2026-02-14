extends Control

@onready var sprites = {
	'square': $SquareSprite,
	'triangle': $TriangleSprite,
	'circle': $CircleSprite
}

func set_wanted(type):
	for i in sprites.keys():
		if i == type:
			sprites[i].visible = true
		else:
			sprites[i].visible = false
