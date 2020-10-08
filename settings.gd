extends Node

var config
var path = "user://settings.cfg"
var loaded = false

var safe_mode = false

# Called when the node enters the scene tree for the first time.
func _ready():
	config = ConfigFile.new()	
	load_config()
	
func save_config():
	config.save(path)
		
func load_config():
	var err = config.load(path)
	if err == OK: # If not, something went wrong with the file loading
		loaded = true
		
func set_param(section, key, value):
	# Store a variable
	config.set_value(section, key, value)
		
func get_param(section, key, default):
	return config.get_value(section, key, default)
