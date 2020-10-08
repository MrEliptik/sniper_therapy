extends Control

signal finished

const image = preload("res://art/scientist/scientist_explanations_2.png")

var playback_position = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func play():
	Music.pause()
	$BeginDelay.start()

func _on_BeginDelay_timeout():
	$Tween.interpolate_property($"Explanation 1", "percent_visible", 0, 1, 10, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$Tween.start()
	$Part1.play()

func _on_Tween_tween_all_completed():
	$ReadTimer.start()

func _on_ReadTimer_timeout():
	if $"Explanation 1".visible:
		$"Explanation 1".visible = false
		$"Explanation 2".visible = true
		$Tween.interpolate_property($"Explanation 2", "percent_visible", 0, 1, 10, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		$Tween.start()
		$Part2.play()
	elif $"Explanation 2".visible:
		$"Explanation 2".visible = false
		$"Explanation 3".visible = true
		$Tween.interpolate_property($"Explanation 3", "percent_visible", 0, 1, 10, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		$Tween.start()
		$Part3.play()
	elif $"Explanation 3".visible:
		$"Explanation 3".visible = false
		$"Explanation 4".visible = true
		$Scientist.texture = image
		$Tween.interpolate_property($"Explanation 4", "percent_visible", 0, 1, 2, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		$Tween.start()
		$Part4.play()
	elif $"Explanation 4".visible:
		emit_signal('finished')
		Music.resume()
