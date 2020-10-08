extends Spatial


var playback_pos = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func pause():
	playback_pos = $Music.get_playback_position()
	$Music.stop()
	
func resume():
	$Music.play(playback_pos)
