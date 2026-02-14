extends Control

var health_on_color = Color("dc1414")
var mana_on_color = Color("5efdf7")

@onready var health = {
	1: $Health1,
	2: $Health2,
	3: $Health3,
	4: $Health4,
	5: $Health5,
	6: $Health6,
}

@onready var mana = {
	1: $Mana1,
	2: $Mana2,
	3: $Mana3,
	4: $Mana4,
	5: $Mana5,
	6: $Mana6,
	7: $Mana7,
}

@onready var score_label = $Score

func set_health(value, max_value):
	for i in range(1, value+1):
		health[i].modulate = health_on_color
	for i in range(value+1, max_value+1):
		health[i].modulate = Color(1, 1, 1)
	for i in range(max_value+1, 7):
		health[i].modulate = Color(0,0,0,0)

func set_mana(value):
	for i in range(1, value+1):
		mana[i].modulate = mana_on_color
	for i in range(value+1, 8):
		mana[i].modulate = Color(1,1,1)

func set_score(value):
	score_label.text = "SCORE   " + str(value).pad_zeros(7)
