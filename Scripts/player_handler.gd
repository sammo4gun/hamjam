extends Node

@export var PLAYER_SPEED_FACTOR = 2.0
@export var SCORE_AMOUNT = 10

@export var NUM_SCORE_SPAWN = 5
@export var NUM_SCORE_SPAWN_STDEV = 2
@export var MANA_SPAWN_CHANCE = 0.8

var mana = 0
var score = 0

func pickup(player: CharacterBody2D, type):
	if type == 'mana':
		mana += 1
		print(mana)
	if type == "health":
		player.heal(1)
	if type == "score":
		score += SCORE_AMOUNT
		print(score)
