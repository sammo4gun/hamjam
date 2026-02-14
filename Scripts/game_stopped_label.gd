extends Label

@onready var world = get_parent().get_parent().get_parent()

func _ready() -> void:
	var minutes = Globals.longest_time_s / 60.
	var seconds = Globals.longest_time_s % 60
	text = """
	LONGEST TIME            %02d:%02d
	HIGH_SCORE            %s
	
	READY TO START?
	""" % [minutes, seconds, str(Globals.high_score).pad_zeros(7)]

func _process(_delta: float) -> void:
	if Globals.first_run_done and !world.game_fadeout and !world.game_started and visible:
		get_tree().paused = false
		world.start_game()
		visible = false

func _unhandled_input(event):
	if !world.game_started:
		if event is InputEventKey or event is InputEventMouseButton and event.pressed:
			get_tree().paused = false
			world.start_game()
			visible = false
