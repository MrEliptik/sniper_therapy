extends Control

# Called when the node enters the scene tree for the first time.
func _ready():
	if not visible: return
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_YesButton_pressed():
	if not visible: return
	get_tree().paused = false
	visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	Settings.safe_mode = true
	Settings.set_param("General", "safe_mode", true)

func _on_NoButton_pressed():
	if not visible: return
	get_tree().paused = false
	visible = false
	Settings.safe_mode = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	Settings.set_param("General","safe_mode", false)
