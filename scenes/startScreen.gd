extends Spatial


# Called when the node enters the scene tree for the first time.
func _ready():
	$Timer.start()

func _on_Timer_timeout():
	$Hit.play()

func _on_Timer2_timeout():
	$Rumble.play()
