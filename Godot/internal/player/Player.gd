extends KinematicBody
class_name Player

# Base player class used by players and puppets.

const MOUSE_SENSITIVITY = 0.05

# Really simple physics simulation
const physics_const = {
	GRAVITY = -9.8,
	MAX_SPEED = 3.0,
	ACCEL = 8.0,
	DEACCEL = 6.0,
	MAX_SLOPE_ANGLE = 50.0
}

var input_movement_vector = Vector2.ZERO
var vel = Vector3.ZERO
var dir = Vector3.ZERO
var accel = physics_const.DEACCEL

# Keyboard input
var cmd = {
	move_forward = false,
	move_backward = false,
	move_left = false,
	move_right = false,
}

onready var my_head = get_node("Head")
onready var my_camera = get_node("Head/Camera")

# Networking server: Synchronize position of active player
var can_send_pos = true
onready var send_pos_timer = get_node("Timers/NetworkSendpos")
const CORRECTION_THRESHOLD = 0.25
# Networking (server and client)
var can_send = true
onready var send_timer = get_node("Timers/NetworkSend")

func _ready():
	var _err_send = send_timer.connect("timeout", self, "_on_send_timeout")
	if Globals.is_server == true:
		var _err_sendpos = get_node("Timers/NetworkSendpos").connect("timeout",
										 self, "_on_send_pos_timeout")
	elif Globals.my_id == name: # Active player
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
	process_commands(delta)
	process_movement(delta)
	if Globals.is_server == true:
		# Update player representations
		update_puppets()
	elif Globals.my_id == name: # Active player
		rpc_unreliable_id(1, "check_pos", translation)
		process_input(delta)

func process_commands(_delta):
	dir = Vector3()
	var cam_xform = my_camera.get_global_transform()
	input_movement_vector = Vector2.ZERO
	if cmd.move_forward:
		input_movement_vector.y += 1
	if cmd.move_backward:
		input_movement_vector.y -= 1
	if cmd.move_left:
		input_movement_vector.x -= 1
	if cmd.move_right:
		input_movement_vector.x += 1
	input_movement_vector = input_movement_vector.normalized()
	dir += -cam_xform.basis.z * input_movement_vector.y
	dir += cam_xform.basis.x * input_movement_vector.x

# Process movements (influenced by our input) and send them to KinematicBody
func process_movement(delta):
	# Assure our movement direction on the Y axis is zero, and then normalize it
	dir.y = 0
	dir = dir.normalized()
		
	# Ground detection and gravity
	if $Ground.is_colliding() == true:
		var ground_normal = $Ground.get_collision_normal()
		var ground_angle = rad2deg(acos(ground_normal.dot(Vector3.UP)))
		# Stand fix on inclined plane
		if ground_angle > physics_const.MAX_SLOPE_ANGLE:
			vel.y += delta * physics_const.GRAVITY
	else:
		vel.y += delta * physics_const.GRAVITY
	
	# New variable with Y velocity removed
	var hvel = vel
	hvel.y = 0
	
	# Acceleration or deceleration
	accel = physics_const.DEACCEL
	if dir.dot(hvel) > 0:
			accel = physics_const.ACCEL
	
	# Interpolate our velocity (without gravity), then move using move_and_slide
	hvel = hvel.linear_interpolate(dir * physics_const.MAX_SPEED, accel * delta)
	vel.x = hvel.x
	vel.z = hvel.z
	vel = move_and_slide(vel, Vector3.UP, true, 4, deg2rad(physics_const.MAX_SLOPE_ANGLE), true)

# Active player, move head and camera into mouse direction
func process_rotations(x : float, y : float):
	my_head.rotate_x(deg2rad(y))
	rotate_y(deg2rad(x))
	var camera_rot = my_head.rotation_degrees
	camera_rot.x = clamp(camera_rot.x, -85, 85)
	my_head.rotation_degrees = camera_rot
	if can_send:
		rpc_unreliable_id(1, "update_rotation", rotation, my_head.rotation)
		can_send = false
		send_timer.start()

# Server and client use the timer for different purposes, limits network load
func _on_send_timeout():
	can_send = true

# Active player, mouse rotation
func _input(event):
	if Globals.my_id == name: # Active player
		if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			process_rotations(-event.relative.x * MOUSE_SENSITIVITY,
								-event.relative.y * MOUSE_SENSITIVITY)
	else:
		pass

# Active player, mouse and keyboard interactions
func process_input(_delta):
	# Input
	if Input.is_action_pressed("move_forward"):
		cmd.move_forward = true
		rpc_unreliable_id(1, "execute_command", "move_forward", true)
	else:
		cmd.move_forward = false
		rpc_unreliable_id(1, "execute_command", "move_forward", false)
	if Input.is_action_pressed("move_backward"):
		cmd.move_backward = true
		rpc_unreliable_id(1, "execute_command", "move_backward", true)
	else:
		cmd.move_backward = false
		rpc_unreliable_id(1, "execute_command", "move_backward", false)
	if Input.is_action_pressed("move_left"):
		cmd.move_left = true
		rpc_unreliable_id(1, "execute_command", "move_left", true)
	else:
		cmd.move_left = false
		rpc_unreliable_id(1, "execute_command", "move_left", false)
	if Input.is_action_pressed("move_right"):
		cmd.move_right = true
		rpc_unreliable_id(1, "execute_command", "move_right", true)
	else:
		cmd.move_right = false
		rpc_unreliable_id(1, "execute_command", "move_right", false)
	
	# Capturing/freeing the cursor
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Recapture the mouse on left click
	if Input.is_action_just_pressed("primary_fire") and Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# Server but called from client: Update rotation of active player (not puppets)
remote func update_rotation(rot, head_rot):
	if int(name) == get_tree().get_rpc_sender_id():
		rotation = rot
		my_head.rotation = head_rot

# Server but called from client: Update enumeration of command states
# if self is the target, see function "process_commands"
remote func execute_command(a, b):
	if int(name) == get_tree().get_rpc_sender_id():
		cmd[a] = b

# Server but called from client: Synchronize position data of the active player
remote func check_pos(pos):
	if int(name) == get_tree().get_rpc_sender_id():
		if global_transform.origin.distance_to(pos) > CORRECTION_THRESHOLD and can_send_pos:
			rpc_unreliable("correct_pos", global_transform.origin)
			can_send_pos = false
			send_pos_timer.start()

# Server
master func _on_send_pos_timeout():
	can_send_pos = true

# Client: Here we update the position of the active player (not puppets)
puppet func correct_pos(pos):
	global_transform.origin = pos

# Server
master func update_puppets():
	if can_send:
		rpc_unreliable("update_puppet", global_transform.origin, rotation,
						my_head.rotation, vel, accel, input_movement_vector)
		can_send = false
		send_timer.start()

# Client: Here we are updating the position, rotation, head rotation, velocity,
# acceleration and input vector of puppets (not active player)
puppet func update_puppet(pos : Vector3, rot : Vector3, h_rot : Vector3,
							v : Vector3, a : float, imv : Vector2):
	if Globals.my_id == name: # Active player
		pass
	else:
		translation = pos
		rotation = rot
		my_head.rotation = h_rot
		vel = v
		accel = a
		input_movement_vector = imv
