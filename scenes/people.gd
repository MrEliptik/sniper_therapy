extends KinematicBody

signal dead(who)
signal sick(who)
signal heal(who)

const GRAVITY = -10
var vel = Vector3()
const MAX_SPEED = 0.5
const JUMP_SPEED = 2.5
const ACCEL = 2


const DAMAGE = 50

var dir = Vector3()

const DEACCEL= 12
const MAX_SLOPE_ANGLE = 40

var camera
var rotation_helper

var MOUSE_SENSITIVITY = 0.1

var sick = false
var male = true
var dead = false
var contact = false
var safe_mode = false
var contact_body = null
var ignore_contact = false

const bool_val = [true, false]
const sickness_probability = 0.1

var sickness = {
	true:0.2,
	false:0.8
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

var temperature = Color('c0ffc4c4')

# Wander behavior specific
var wander_circle_radius = 200
var wander_circle_distance = 100

var direction = {
	Vector2(0, 1):0.2, # Up
	Vector2(0.5, 0.5):0.1, # Up-right
	Vector2(-0.5, 0.5):0.1, # Up-left
	Vector2(0, -1):0.5, # Down
	Vector2(0.5, -0.5):0.025, # Down-right
	Vector2(-0.5, -0.5):0.025, # Down-left
	Vector2(-1, 0):0.25, # Left
	Vector2(1, 0):0.25  # Right
}

var direction_without_up = {
	Vector2(0, -1):0.4, # Down
	Vector2(0.5, -0.5):0.1, # Down-right
	Vector2(-0.5, -0.5):0.1, # Down-left
	Vector2(-1, 0):0.25, # Left
	Vector2(1, 0):0.25  # Right
}

func _ready():
	safe_mode = Settings.get_param("General", "safe_mode", false)
	
	$Skeleton/AnimationPlayer.play('walk')
	randomize()
	
	# Chose skin
	var skin = pick_random_weighted_dict(skins)
	for bone in bones:
		#get_node("Skeleton/"+bone).get_mesh().surface_set_material(0, load("models/people/"+skin+".material"))
		get_node("Skeleton/"+bone).set_material_override(load("models/people/"+skin+".material"))
		
	if skin in ["geisha", "woman", "womanAlternative"]: male = false
	
	print('Skin: ' + str(skin) + ' - Male: ' + str(male) + ' - Sick: ' + str(sick))
	
	$Skeleton.physical_bones_add_collision_exception(get_rid())
	
	# Initial movement
	wander()
	$WanderTimer.start()
	if sick: $DelayTimer.start()
	
func set_sick(val):
	sick = val

func _physics_process(delta):
	process_movement(delta)

func process_movement(delta):
	if dead: return
	# Don't move if contact
	if contact and contact_body != null:
		if get_transform().origin.angle_to(contact_body.get_transform().origin) != 0:
			look_at(-contact_body.get_transform().origin, Vector3(0, 1, 0))
		return
		
	dir.y = 0
	dir = dir.normalized()
	
	if (get_transform().origin-dir).angle_to(get_transform().origin) != 0:
		look_at(get_transform().origin - dir, Vector3(0, 1, 0))

	vel.y += delta * GRAVITY

	var hvel = vel
	hvel.y = 0

	var target = dir
	target *= MAX_SPEED

	var accel
	if dir.dot(hvel) > 0:
			accel = ACCEL	
	else:
		accel = DEACCEL

	hvel = hvel.linear_interpolate(target, accel * delta)
	vel.x = hvel.x
	vel.z = hvel.z
	
	# Movement
	if Vector2(hvel.x, hvel.y) != Vector2(0, 0):
		if not $Skeleton/AnimationPlayer.is_playing():
			$Skeleton/AnimationPlayer.play("walk")
	else:
		$Skeleton/AnimationPlayer.stop()
		
	# Can be useful to avoid falling or hitting wall before really moving
	# test_move(Transfrom from, Vector3 rel_vec, bool infinite_inertia=true)
	
	vel = move_and_slide(vel, Vector3(0, 1, 0), 0.05, 4, deg2rad(MAX_SLOPE_ANGLE))
	
# This function should set the direction we want to move to
# and then process_movement will actually move the object
func wander():
	# Calculate the circle center
#	var circleCenter = Vector3()
#	circleCenter = vel
#	circleCenter.normalized()
#	circleCenter.scale()
	
	dir = Vector3()
	var xform = get_global_transform()
	
	# Check if something is in front
	# if its the case, we don't want to go forward
	var ray = $RayCast
	ray.force_raycast_update()

	var dir_picked
	if ray.is_colliding():
		var body = ray.get_collider()
		if body.name == "GridMap":
			dir_picked = pick_random_weighted_dict(direction_without_up)
		else:
			dir_picked = pick_random_weighted_dict(direction)
	else:
		dir_picked = pick_random_weighted_dict(direction)

	var input_movement_vector = Vector2()

	input_movement_vector += dir_picked
	input_movement_vector = input_movement_vector.normalized()

	# Basis vectors are already normalized
	dir += xform.basis.z * input_movement_vector.y
	dir += xform.basis.x * input_movement_vector.x
	
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
	if get_node('ContactArea/CollisionShape'):
		$ContactArea/CollisionShape.disabled = true
	if get_node('HeadArea/CollisionShape'):
		$HeadArea/CollisionShape.disabled = true
	if get_node('BodyArea/CollisionShape'):
		$BodyArea/CollisionShape.disabled = true
	if safe_mode:
		sick = false
		emit_signal("heal", self)
	else:
		$Body.disabled = true
		$Feet.disabled = true
		dead = true
		$Skeleton.physical_bones_start_simulation(["rig_1", "spine_1", "spine_2", "arm_r_1", 
			"arm_r_2", "hand_r_1", "arm_l_1", "arm_l_2", "hand_l_1", "leg_r_1", "leg_r_2",
			"leg_l_1", "leg_l_2"])
		var impulse = $Skeleton.get_global_transform().basis.xform(Vector3(0,0,-1))
		impulse *= 600
		$"Skeleton/Physical Bone spine_1".apply_impulse(Vector3(), impulse)
	
		emit_signal("dead", self)

func _on_ContactArea_body_entered(body):
	if dead or ignore_contact: return
	if not body.has_method('is_sick'): return
	$ContactTimer.start()
	contact = true
	contact_body = body
	$Skeleton/AnimationPlayer.stop()
	if body.is_sick() and not sick:
		# Probability that he contaminates us
		sick = pick_random_weighted_dict(contagion)
		if sick: 
			emit_signal('sick', self)
			$DelayTimer.start()
		
func _on_ContactArea_body_exited(body):
	contact = false
	contact_body = null
	$IgnoreTimer.start()
	
func _on_ContactTimer_timeout():
	contact = false
	ignore_contact = true
	
func _on_IgnoreTimer_timeout():
	ignore_contact = false
	
func _on_DelayTimer_timeout():
	if dead: return
	# Randomly choose between sneeze and cough
	if not sick: return
	if randf() > 0.5:
		$Skeleton/AnimationPlayer.play("cough")
		if male:
			$MaleCough.play()
			pass
		else:
			if not $FemaleCough.is_playing():
				$FemaleCough.play()
	else:
		$Skeleton/AnimationPlayer.play("sneeze")
		if male:
			$MaleSneeze.play()
			pass
		else:
			if not $FemaleSneeze.is_playing():
				$FemaleSneeze.play()
				
	# Setup next cough/sneeze
	$DelayTimer.wait_time = rand_range(1.5, 10)
	$DelayTimer.start()

# Change direction every X seconds
func _on_WanderTimer_timeout():
	if contact: return
	wander()
	$WanderTimer.wait_time = rand_range(0.5, 2.5)
	$WanderTimer.start()
