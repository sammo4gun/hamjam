extends Node

@export var PLAYER_SPEED_FACTOR = 2.0
@export var SCORE_AMOUNT = 10

@export var SWITCH_COST = 7

@export var NUM_SCORE_SPAWN = 5
@export var NUM_SCORE_SPAWN_STDEV = 2
@export var MANA_SPAWN_CHANCE = 0.8
@export var MANA_BONUS_SCORE = 50

@onready var world = get_parent()

var can_switch = false
var mana = 0
var score = 0

func _process(_delta: float) -> void:
	can_switch = mana >= SWITCH_COST
	world.defector_indicator.visible = can_switch

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		world.paused_indicator.visible = !get_tree().paused
		get_tree().paused = !get_tree().paused

func switch():
	mana = max(mana - SWITCH_COST, 0)
	world.set_mana(mana)
	$SwitchEffect.play()

func pickup(player: CharacterBody2D, type):
	if type == 'mana':
		if mana < SWITCH_COST:
			mana += 1
			world.set_mana(mana)
		else:
			score += MANA_BONUS_SCORE
	if type == "health":
		player.heal(1)
	if type == "score":
		score += SCORE_AMOUNT
		world.set_score(score)

func player_hit(damage, player):
	world.player_hit(damage, player)
