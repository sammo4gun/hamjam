extends Node

var MANA = 0

func pickup(type):
	if type == 'mana':
		MANA += 1
		print(MANA)
