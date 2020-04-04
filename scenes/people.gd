extends KinematicBody

const GRAVITY = -10
var vel = Vector3()
const MAX_SPEED = 1
const JUMP_SPEED = 2.5
const ACCEL = 3


const DAMAGE = 50

var dir = Vector3()

const DEACCEL= 12
const MAX_SLOPE_ANGLE = 40

var camera
var rotation_helper

var MOUSE_SENSITIVITY = 0.1

var sick = false
var male = false

const bool_val = [true, false]
const sickness_probability = 0.1

var sickness = {
	true:0.1,
	false:0.9
}

var contagion = {
	true:0.3,
	false:0.7
}

var skins = {
	"cowboy":0.1,
	"geisha":0.05,
	"man":0.15,
	"manAlternative":0.15,
	"police":0.1,
	"scientist":0.1,
	"soldier":0.05,
	"woman":0.15,
	"womanAlternative":0.15
}

var bones = ["ArmLeft1", "ArmRight1", "Body1", "Head1", "LegLeft1", "LegRight1"]

# Wander behavior specific
var wander_circle_radius = 200
var wander_circle_distance = 100

func _ready():
	$Skeleton/AnimationPlayer.play('walk')
	randomize()
	
	# Chose sick or not
	sick = pick_random_weighted_dict(sickness)
	if sick: $DelayTimer.start()
	
	# Chose sex
	if randf() > 0.5: male = true #intialized at false
	
	# Chose skin
	var skin = pick_random_weighted_dict(skins)
	for bone in bones:
		get_node("Skeleton/"+bone).get_mesh().surface_set_material(0, load("models/people/"+skin+".material"))
	
	$Skeleton.physical_bones_add_collision_exception(get_rid())
	

func _physics_process(delta):
	#process_input(delta)
	process_movement(delta)
	wander()

func process_input(delta):

	# ----------------------------------
	# Walking
	dir = Vector3()

#	var input_movement_vector = Vector2()
#
#	if Input.is_action_pressed("ui_up"):
#		input_movement_vector.y += 1
#	if Input.is_action_pressed("ui_down"):
#		input_movement_vector.y -= 1
#	if Input.is_action_pressed("ui_left"):
#		input_movement_vector.x -= 1
#	if Input.is_action_pressed("ui_right"):
#		input_movement_vector.x += 1
#
#
#	input_movement_vector = input_movement_vector.normalized()

func process_movement(delta):
	dir.y = 0
	dir.x = -1
	dir.y = -1
	dir = dir.normalized()

	vel.y += delta * GRAVITY

	var hvel = vel
	hvel.y = 0

	var target = dir
	target *= MAX_SPEED
	
	look_at(target, Vector3(0, 0, 0))

	var accel
	if dir.dot(hvel) > 0:
			accel = ACCEL	
	else:
		accel = DEACCEL

	hvel = hvel.linear_interpolate(target, accel * delta)
	vel.x = hvel.x
	vel.z = hvel.z
	vel = move_and_slide(vel, Vector3(0, 1, 0), 0.05, 4, deg2rad(MAX_SLOPE_ANGLE))
	
func wander():
	# Calculate the circle center
	var circleCenter = Vector3()
	circleCenter = vel
	circleCenter.normalized()
	circleCenter.scale()
	
# Pick random from weighted dictionnary
func pick_random_weighted_dict(dict):
	var obj = Array(dict.keys())
	var probabilities = Array(dict.values())
	var _max = 0
	var _max_idx
	
	for i in range(len(obj)):
		var p = randf()*probabilities[i]
		if p > _max: 
			_max = p
			_max_idx = i
			
	return obj[_max_idx]
		
		
func is_sick():
	return sick

func bullet_hit(damage, transf):
	print('hit: ' + str(transf))
	$Skeleton/AnimationPlayer.stop()
	$Skeleton.physical_bones_start_simulation(["rig_1", "spine_1", "spine_2", "arm_r_1", 
		"arm_r_2", "hand_r_1", "arm_l_1", "arm_l_2", "hand_l_1", "leg_r_1", "leg_r_2",
		"leg_l_1", "leg_l_2"])
	var impulse = $Skeleton.get_global_transform().basis.xform(Vector3(0,0,-1))
	impulse *= 600
	$"Skeleton/Physical Bone spine_1".apply_impulse(Vector3(), impulse)


func _on_ContactArea_body_entered(body):
	$Skeleton/AnimationPlayer.stop()
	if body.is_sick() and not sick:
		# Probability that he contaminates us
		sick = pick_random_weighted_dict(contagion)
		if sick: $DelayTimer.start()
	
func _on_DelayTimer_timeout():
	# Randomly choose between sneeze and cough
	if sick:
		$Skeleton/AnimationPlayer.play("cough")
		if male:
			#$MaleCough.play()
			pass
		else:
			if not $FemaleCough.is_playing():
				$FemaleCough.play()
				
	# Setup next cough/sneeze
	$DelayTimer.wait_time = rand_range(1.5, 10)
	$DelayTimer.start()
