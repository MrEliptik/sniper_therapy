extends Control

signal play_again
signal exit

# Called when the node enters the scene tree for the first time.
func _ready():
	if not visible: return
	get_tree().paused = true

func _on_Buttons_play_again():
	if not visible: return
	emit_signal("play_again")
	get_tree().paused = false

func _on_Buttons_exit():
	if not visible: return
	emit_signal("exit")

func _on_WinScreen_visibility_changed():
	if visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_tree().paused = true
