extends Node

@export var PLAYER_SPEED_FACTOR = 1.3

var MANA = 0

func pickup(type):
	if type == 'mana':
		MANA += 1
		print(MANA)
