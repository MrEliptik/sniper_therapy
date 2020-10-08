extends Control

const ammo_color = preload("res://art/ammo.png")
const ammo_bw = preload("res://art/ammo_bw.png")

const LOW_LIMIT = 10
const MID_LIMIT = 30
const EXTREME_LIMIT = 60 

enum COLORS {
	YELLOW,
	WHITE,
	GREEN,
	YELLOWRANGE,
	ORANGE,
	RED
}

var colors = {
	COLORS.YELLOW: Color('ffe809'),
	COLORS.WHITE: Color('ffffff'),
	COLORS.GREEN: Color('76ff0d'),
	COLORS.YELLOWRANGE: Color('ffcb0d'),
	COLORS.ORANGE: Color('ed601f'),
	COLORS.RED: Color('ed2d1f')
}

func _ready():
	if Settings.safe_mode:
		$HBoxContainer/HBoxContainer2/HBoxContainer2/Kill_label.texte = "Healed: "

func animate_score(val, color):
	$Score.modulate = colors[color]
	$Score.text = '+'+str(val)
	$AnimationPlayer.play("notif")
	
func set_magazine(val):
	var ammo_display_count = $HBoxContainer/HBoxContainer.get_child_count()
	for i in range(ammo_display_count-val):
		$HBoxContainer/HBoxContainer.get_child(i).texture = ammo_bw
	for i in range(ammo_display_count-val, ammo_display_count):
		$HBoxContainer/HBoxContainer.get_child(i).texture = ammo_color

func set_ammo(val):
	$HBoxContainer/HBoxContainer3/Ammo.text = str(val) + "/100"
	
func set_kill(val):
	$HBoxContainer/HBoxContainer2/HBoxContainer2/Kill.text = str(val)
	
func set_sick(val, total_pop):
	var percentage = val*100.0/total_pop
	$HBoxContainer/HBoxContainer2/HBoxContainer/SickBar.value = percentage

func _on_SickBar_value_changed(value):
	var sickbar = $HBoxContainer/HBoxContainer2/HBoxContainer/SickBar
	if value <= LOW_LIMIT:
		sickbar.get("custom_styles/fg").bg_color = colors[COLORS.GREEN]
	elif value <= MID_LIMIT and value > LOW_LIMIT:
		sickbar.get("custom_styles/fg").bg_color = colors[COLORS.YELLOWRANGE]
	elif value < MID_LIMIT and value <= EXTREME_LIMIT:
		sickbar.get("custom_styles/fg").bg_color = colors[COLORS.YELLOW]
	elif value > EXTREME_LIMIT:
		sickbar.get("custom_styles/fg").bg_color = colors[COLORS.RED]
		
