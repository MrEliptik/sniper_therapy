extends Spatial

const p = preload("res://scenes/people.tscn")
const world = preload("res://scenes/world_1.tscn")
const population_size = 20
const min_percentage_sick = 10

const lose_kill_threshold = 50
const lose_virus_threshold = 70

onready var spawn_area = $SpawnArea/CollisionShape
onready var people_container = $People
onready var player = $Player

var positions = []

var to_delete = Array()

# Stats collection
var stats = {
	"population":population_size,
	"sick":0,
	"killed":0,
	"healed":0
}

var game_started = false

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	
	# Deactivate contact for play options exit
	$People/Exit/ContactArea/CollisionShape.disabled = true
	$People/Play/ContactArea/CollisionShape.disabled = true
	$People/Options/ContactArea/CollisionShape.disabled = true
	
	player.connect("hit", self, "on_hit")
	player.connect("play", self, "tutorial")
	player.connect("options", self, "on_options")
	
func _process(delta):
	if not game_started: return
	# Update hud
	if Settings.safe_mode:
		player.get_node('HUD').set_kill(stats['healed'])
	else:
		player.get_node("HUD").set_kill(stats['killed'])
	player.get_node("HUD").set_sick(stats['sick'], stats['population'])
	
	# Check number of people healed / people sick
	if stats['sick']*100.0/stats['population'] > lose_virus_threshold:
		on_lose("virus")
	
	# If number of kill too high: lose
	if stats['killed']*100.0/stats['population'] > lose_kill_threshold: 
		on_lose("kill")
		
	if stats['sick'] == 0:
		on_win()
	

func place_random_people(number):
	var ext = spawn_area.shape.get_extents()
	
	# x, y, z (y is up)
	var lower_limit = Vector3(spawn_area.transform.origin-ext)
	var upper_limit = Vector3(spawn_area.transform.origin+ext)

	# Random placement
	for i in range(number):
		var transf = Vector3(rand_range(lower_limit.x, upper_limit.x), 0.2, rand_range(lower_limit.z, upper_limit.z))
		# Loop to not get the same position
		while transf in positions:
			transf = Vector3(rand_range(lower_limit.x, upper_limit.x), 0.2, rand_range(lower_limit.z, upper_limit.z))
		positions.append(transf)	

		var people = p.instance()
		if stats['sick']*100.0/stats['population'] < min_percentage_sick:
			people.set_sick(true)
			stats['sick'] += 1
			player.get_node("HUD").set_sick(stats['sick'], stats['population'])
		
		people.translation = transf
		people.connect("dead", self, "on_dead")
		people.connect("sick", self, "on_sick")
		people.connect("heal", self, "on_heal")
		people_container.add_child(people)
		
		
	game_started = true

func reset_stats():
	stats["population"] = population_size
	stats["sick"] = 0
	stats["killed"] = 0
	stats["healed"] = 0

func tutorial():
	player.get_node("Fire").stop()
	get_tree().paused = true
	$Tutorial.visible = true
	$Tutorial.play()
	
func _on_Tutorial_finished():
	$Tutorial.visible = false
	get_tree().paused = false
	on_play()

func on_play():
	# Remove play, options and exit
	for child in people_container.get_children():
		people_container.remove_child(child)
		
	# Remove start screen
	remove_child($StartScreen)
	
	# Load and environment
	$Environment.add_child(world.instance())
	
	# Place people
	place_random_people(population_size)
	
	# Place player
	player.game_started = true
	player.global_transform = $Environment.get_child(0).get_node('PlayerSpawn').global_transform
	player.get_node("HUD").visible = true
	player.scoped = false
	player.scoped_2x = false
	player.get_node("Reticle").visible = false
	player.get_node("RotationHelper/sniper").visible = true
	player.get_node("HUD/Crosshair").visible = true
	player.get_node("RotationHelper/Camera").fov = player.CAMERA_FOV_UNSCOPED
	player.get_node("AnimationPlayer").play('idle')
	
func on_replay():
	reset_stats()
	
	# Remove people
	for child in people_container.get_children():
		people_container.remove_child(child)
	
	# Place people
	place_random_people(population_size)
	
	# Place player
	player.global_transform = $Environment.get_child(0).get_node('PlayerSpawn').global_transform
	player.get_node("HUD").visible = true
	player.scoped = false
	player.scoped_2x = false
	player.get_node("Reticle").visible = false
	player.get_node("RotationHelper/sniper").visible = true
	player.get_node("HUD/Crosshair").visible = true
	player.get_node("RotationHelper/Camera").fov = player.CAMERA_FOV_UNSCOPED
	player.get_node("AnimationPlayer").play('idle')
	player.ammo = 100
	player.ammo_magazine = 5
	player.get_node('HUD').set_ammo(player.ammo)
	player.get_node('HUD').set_magazine(player.ammo_magazine)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Hide win or lose screen
	$WinScreen.visible = false
	$DeathScreen.visible = false
	
func on_options():
	pass

func on_dead(who):
	stats['killed'] += 1
	stats['population'] -= 1
	if who.is_sick(): stats['sick'] -= 1
	to_delete.append(who)
	$RemovePeopleTimer.start()
	
func on_sick(who):
	stats['sick'] += 1
	
func on_heal(who):
	stats['sick'] -= 1
	stats['healed'] += 1		

func _on_RemovePeopleTimer_timeout():
	var del = to_delete.pop_front()
	while del != null:
		people_container.remove_child(del)
		del = to_delete.pop_front()
		
func on_win():
	player.get_node("HUD").visible = false
	player.get_node("Reticle").visible = false
	player.get_node("RotationHelper/sniper").visible = true
	player.get_node("HUD/Crosshair").visible = true
	player.get_node("RotationHelper/Camera").fov = player.CAMERA_FOV_UNSCOPED
	player.get_node("AnimationPlayer").play('idle')
	get_tree().paused = true
	$WinScreen.visible = true
	
func on_lose(cause):
	player.get_node("HUD").visible = false
	player.get_node("Reticle").visible = false
	player.get_node("RotationHelper/sniper").visible = true
	player.get_node("HUD/Crosshair").visible = true
	player.get_node("RotationHelper/Camera").fov = player.CAMERA_FOV_UNSCOPED
	player.get_node("AnimationPlayer").play('idle')
	get_tree().paused = true
	if cause == "virus":
		$DeathScreen/VBoxContainer/TextVirus.visible = true
	elif cause == "kill":
		$DeathScreen/VBoxContainer/TextKill.visible = true
	$DeathScreen.visible = true

func on_exit():
	get_tree().quit()

func _on_WinScreen_play_again():
	on_replay()

func _on_DeathScreen_play_again():
	on_replay()
