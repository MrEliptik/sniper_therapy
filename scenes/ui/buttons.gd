extends Control

signal play_again
signal exit

func _on_Play_again_pressed():
	if not visible: return
	emit_signal("play_again")


func _on_Exit_pressed():
	if not visible: return
	emit_signal("exit")
