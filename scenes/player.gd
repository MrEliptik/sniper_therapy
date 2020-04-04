extends KinematicBody

const GRAVITY = -10
var vel = Vector3()
const MAX_SPEED = 1.5
const JUMP_SPEED = 2.5
const ACCEL = 4
const PACK_THROW_FORCE = 12

const MAX_SPEED_SCOPED = 0.75
const JUMP_SPEED_SCOPED = 2
const ACCEL_SCOPED = 3.5

const DAMAGE = 50

var dir = Vector3()

const DEACCEL= 12
const MAX_SLOPE_ANGLE = 40

var camera
var rotation_helper

var MOUSE_SENSITIVITY = 0.1

var JOYPAD_SENSITIVITY = 3
const JOYPAD_DEADZONE = 0.15

var grabbed_object = null
const OBJECT_THROW_FORCE = 8
const OBJECT_GRAB_DISTANCE = 0.3
const OBJECT_GRAB_RAY_DISTANCE = 1

const CAMERA_FOV_SCOPED = 65
const CAMERA_FOV_UNSCOPED = 90
const CAMERA_FOV_SCOPED_2X = 25
var scoped = false
var scoped_2x = false
var can_fire = true
var can_reload = true

func _ready():
	set_process(true)
	camera = $RotationHelper/Camera
	rotation_helper = $RotationHelper

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
	process_input(delta)
	process_movement(delta)
	process_view_input(delta)

func process_input(delta):

	# ----------------------------------
	# Walking
	dir = Vector3()
	var cam_xform = camera.get_global_transform()

	var input_movement_vector = Vector2()

	if Input.is_action_pressed("ui_up"):
		input_movement_vector.y += 1
	if Input.is_action_pressed("ui_down"):
		input_movement_vector.y -= 1
	if Input.is_action_pressed("ui_left"):
		input_movement_vector.x -= 1
	if Input.is_action_pressed("ui_right"):
		input_movement_vector.x += 1
		
	if Input.get_connected_joypads().size() > 0:
		
		var joypad_vec = Vector2(0, 0)
		
		if OS.get_name() == "Windows":
			joypad_vec = Vector2(Input.get_joy_axis(0, 0), -Input.get_joy_axis(0, 1))
		elif OS.get_name() == "X11":
			joypad_vec = Vector2(Input.get_joy_axis(0, 1), Input.get_joy_axis(0, 2))
		elif OS.get_name() == "OSX":
			joypad_vec = Vector2(Input.get_joy_axis(0, 1), Input.get_joy_axis(0, 2))
	
		if joypad_vec.length() < JOYPAD_DEADZONE:
			joypad_vec = Vector2(0, 0)
		else:
			joypad_vec = joypad_vec.normalized() * ((joypad_vec.length() - JOYPAD_DEADZONE) / (1 - JOYPAD_DEADZONE))
	
		input_movement_vector += joypad_vec

	input_movement_vector = input_movement_vector.normalized()

	# Basis vectors are already normalized.
	dir += -cam_xform.basis.z.normalized() * input_movement_vector.y
	dir += cam_xform.basis.x.normalized() * input_movement_vector.x
	# ----------------------------------

	# ----------------------------------
	# Jumping
	if is_on_floor():
		if Input.is_action_just_pressed("jump"):
			if scoped or scoped_2x:
				vel.y = JUMP_SPEED_SCOPED
			else:
				vel.y = JUMP_SPEED
	# ----------------------------------

	# ----------------------------------
	# Capturing/Freeing the cursor
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			$PauseMenu.visible = true
			get_tree().paused = true
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	# ----------------------------------
	
	# ----------------------------------
	# Throwing packs
#	if Input.is_action_just_pressed("toss_pack"):
#		var roll_pack_clone
#		roll_pack_clone = roll_pack.instance()
#		roll_pack_clone.connect('explode', self, 'on_explode')
#
#
#		get_tree().root.add_child(roll_pack_clone)
##		$Tween.interpolate_property(roll_pack_clone, 'scale', Vector3(0, 0, 0), Vector3(1, 1 ,1), 0.4, Tween.TRANS_LINEAR, Tween.EASE_IN)
##		$Tween.start()
#		roll_pack_clone.global_transform = $RotationHelper/GrenadeTossPos.global_transform
#		roll_pack_clone.apply_impulse(Vector3(0,0,0), roll_pack_clone.global_transform.basis.z * PACK_THROW_FORCE)
#		$RotationHelper/rocketLauncher/AnimationPlayer.play('fire')
#		$Thump.play()
	# ----------------------------------
	
	# ----------------------------------
	# Reload
	if Input.is_action_just_pressed("reload"):
		if can_reload:
			can_fire = false
			if scoped:
				$AnimationPlayer.play('reload')
			else:
				$AnimationPlayer.play('reload')
	# ----------------------------------
	
	# ----------------------------------
	# Fire
	if Input.is_action_just_pressed("fire"):
		if can_fire:
			can_fire = false
			can_reload = false
			$Fire.play()
			$StartReloadTimer.start()
			$FireRateTimer.start()
			if scoped:
				fire_weapon()
				$RotationHelper/Camera.shake(0.5, 20, 0.08)
			else:
				fire_weapon()
				$AnimationPlayer.play('fire')
				$RotationHelper/Camera.shake(0.5, 20, 0.02)
	# ----------------------------------
	
	# ----------------------------------
	# Scope the sniper
	if Input.is_action_just_pressed("scope"):
		if scoped:
			$RotationHelper/Camera.fov = CAMERA_FOV_SCOPED_2X
			scoped_2x = true
			scoped = false
		elif scoped_2x:
			$Reticle.visible = false
			$HUD/Crosshair.visible = true
			$RotationHelper/Camera.fov = CAMERA_FOV_UNSCOPED
			$AnimationPlayer.play("unscope")
			scoped_2x = false
		else:
			$AnimationPlayer.play("scope")
			scoped = true
			$HUD/Crosshair.visible = false
	# ----------------------------------

func process_movement(delta):
	dir.y = 0
	dir = dir.normalized()

	vel.y += delta * GRAVITY

	var hvel = vel
	hvel.y = 0

	var target = dir
	if scoped or scoped_2x:
		target *= MAX_SPEED_SCOPED
	else:
		target *= MAX_SPEED
		target *= MAX_SPEED

	var accel
	if dir.dot(hvel) > 0:
		if scoped or scoped_2x:
			accel = ACCEL_SCOPED
		else:
			accel = ACCEL	
	else:
		accel = DEACCEL

	hvel = hvel.linear_interpolate(target, accel * delta)
	vel.x = hvel.x
	vel.z = hvel.z
	vel = move_and_slide(vel, Vector3(0, 1, 0), 0.05, 4, deg2rad(MAX_SLOPE_ANGLE))
	
func process_view_input(delta):
	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		return

	# NOTE: Until some bugs relating to captured mouses are fixed, we cannot put the mouse view
	# rotation code here. Once the bug(s) are fixed, code for mouse view rotation code will go here!

	# ----------------------------------
	# Joypad rotation
	var joypad_vec = Vector2()
	if Input.get_connected_joypads().size() > 0:

		if OS.get_name() == "Windows":
			joypad_vec = Vector2(Input.get_joy_axis(0, 2), -Input.get_joy_axis(0, 3))
		elif OS.get_name() == "X11":
			joypad_vec = Vector2(Input.get_joy_axis(0, 3), Input.get_joy_axis(0, 4))
		elif OS.get_name() == "OSX":
			joypad_vec = Vector2(Input.get_joy_axis(0, 3), Input.get_joy_axis(0, 4))

		if joypad_vec.length() < JOYPAD_DEADZONE:
			joypad_vec = Vector2(0, 0)
		else:
			joypad_vec = joypad_vec.normalized() * ((joypad_vec.length() - JOYPAD_DEADZONE) / (1 - JOYPAD_DEADZONE))

		rotation_helper.rotate_x(deg2rad(joypad_vec.y * JOYPAD_SENSITIVITY))

		rotate_y(deg2rad(joypad_vec.x * JOYPAD_SENSITIVITY * -1))

		var camera_rot = rotation_helper.rotation_degrees
		camera_rot.x = clamp(camera_rot.x, -70, 70)
		rotation_helper.rotation_degrees = camera_rot

func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotation_helper.rotate_x(deg2rad(event.relative.y * MOUSE_SENSITIVITY * -1))
		self.rotate_y(deg2rad(event.relative.x * MOUSE_SENSITIVITY * -1))

		var camera_rot = rotation_helper.rotation_degrees
		camera_rot.x = clamp(camera_rot.x, -70, 70)
		rotation_helper.rotation_degrees = camera_rot

func fire_weapon():
	var ray = $RotationHelper/RayCast
	ray.force_raycast_update()

	if ray.is_colliding():
		var body = ray.get_collider()
		print(body)

		if body == self:
			pass
		elif body.has_method("bullet_hit"):
			body.bullet_hit(DAMAGE, ray.global_transform)

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == 'scope':
		$RotationHelper/Camera.fov = CAMERA_FOV_SCOPED
		$Reticle.visible = true
	elif anim_name == 'fire':
		can_reload = true
	elif anim_name == 'reload':
		can_fire = true
		

func _on_FireRateTimer_timeout():
	can_fire = true

func _on_StartReloadTimer_timeout():
	$Reload.play()