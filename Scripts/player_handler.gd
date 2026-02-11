extends Node

@export var PLAYER_SPEED_FACTOR = 2.0

var MANA = 0

func pickup(type):
	if type == 'mana':
		MANA += 1
		print(MANA)
