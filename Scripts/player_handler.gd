extends Node

@export var PLAYER_SPEED_FACTOR = 2.0
@export var SCORE_AMOUNT = 10

@export var SWITCH_COST = 0

@export var NUM_SCORE_SPAWN = 5
@export var NUM_SCORE_SPAWN_STDEV = 2
@export var MANA_SPAWN_CHANCE = 0.8

@onready var world = get_parent()

var can_switch = false
var mana = 0
var score = 0

func _process(delta: float) -> void:
	can_switch = mana >= SWITCH_COST

func switch():
	assert(mana >= SWITCH_COST)
	mana -= SWITCH_COST

func pickup(player: CharacterBody2D, type):
	if type == 'mana':
		mana += 1
		print(mana)
	if type == "health":
		player.heal(1)
	if type == "score":
		score += SCORE_AMOUNT
		print(score)

func player_hit(damage, dead):
	world.player_hit(damage, dead)
