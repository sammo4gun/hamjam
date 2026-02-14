extends Node

var mood = 'nothing'
var silent = -60
var mid = -40
var playing = -20

var current_playing = playing

@onready var mood_players = {
	'nothing': $MusicNothing,
	'chill': $MusicChill,
	'normal': $Music,
	'intense': $MusicIntense
}

func _process(delta: float) -> void:
	if current_playing != playing:
		current_playing = lerpf(current_playing, playing, delta)
	for i in mood_players.keys():
		if i != mood:
			mood_players[i].volume_db = lerpf(mood_players[i].volume_db, silent, delta)
		else:
			if mood_players[i].volume_db < mid: mood_players[i].volume_db = mid
			mood_players[i].volume_db = lerpf(mood_players[i].volume_db, current_playing, delta * 3)
