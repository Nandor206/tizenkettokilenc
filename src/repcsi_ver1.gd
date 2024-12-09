extends RigidBody3D

@export var max_speed: float = 650.0
@export var acceleration_multiplier: float = 50.0
@export var mouse_sensitivity: float = 0.2
@export var gravity: float = 9.8
@export var max_lift_force: float = 150.0
@export var lift_force_multiplier: float = 0.5
@export var roll_sensitivity: float = 0.05
@export var yaw_sensitivity: float = 0.05
@export var pitch_sensitivity: float = 0.05
@export var pitch_return_speed: float = 1.5
@export var yaw_return_speed: float = 1.5
@export var roll_return_speed: float = 1.5
@export var boost_duration: float = 5.0
@export var boost_cooldown_duration: float = 10.0

@onready var speed_label: RichTextLabel = $Control/SpeedLabel
@onready var boost_label: RichTextLabel = $Control/BoostLabel

var current_speed: float = 300.0
var boost_timer: float = 0.0
var boost_cooldown: float = 0.0
var pitch: float = 0.0
var yaw: float = 0.0
var roll: float = 0.0
var is_boosting: bool = false

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	boost_timer = 0.0
	boost_cooldown = 0.0
	$Control.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _input(event):
	if event is InputEventMouseMotion:
		handle_mouse_input(event)

	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if Input.is_action_just_pressed("mousedown"):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if Input.is_action_pressed("forward"):
		move_forward()
	if Input.is_action_pressed("backward"):
		move_backward()
	if Input.is_action_pressed("roll_r"):
		roll_right()
	if Input.is_action_pressed("roll_l"):
		roll_left()
	if Input.is_action_pressed("yaw_r"):
		yaw_right()
	if Input.is_action_pressed("yaw_l"):
		yaw_left()
	if Input.is_action_just_pressed("boost") and boost_cooldown <= 0.0:
		activate_boost()

func _process(delta):
	update_speed(delta)
	update_ui()
	apply_gravity_and_lift(delta)
	move_plane(delta)

func update_ui():
	speed_label.text = "Speed: %.2f" % current_speed
	if boost_cooldown > 0:
		boost_label.text = "Boost Cooldown: %.1f s" % boost_cooldown
	else:
		boost_label.text = "Boost Ready!"

func handle_mouse_input(event):
	return
	pitch -= event.relative.y * mouse_sensitivity
	pitch = clamp(pitch, -75.0, 75.0)
	yaw -= event.relative.x * mouse_sensitivity
	roll -= event.relative.x * roll_sensitivity

func move_forward():
	current_speed += acceleration_multiplier * get_process_delta_time()
	current_speed = clamp(current_speed, 0.0, max_speed)

func move_backward():
	current_speed -= acceleration_multiplier * get_process_delta_time()
	current_speed = clamp(current_speed, 0.0, max_speed)

func roll_right():
	roll -= roll_sensitivity*get_process_delta_time()

func roll_left():
	roll += roll_sensitivity*get_process_delta_time()

func yaw_right():
	yaw -= yaw_sensitivity*get_process_delta_time()

func yaw_left():
	yaw += yaw_sensitivity*get_process_delta_time()

func activate_boost():
	is_boosting = true
	boost_timer = boost_duration
	boost_cooldown = boost_cooldown_duration

func update_speed(delta):
	if is_boosting:
		boost_timer -= delta
		if boost_timer <= 0.0:
			is_boosting = false

	if boost_cooldown > 0.0:
		boost_cooldown -= delta
	if is_boosting:
		current_speed = min(max_speed * 1.1, current_speed + acceleration_multiplier * 2 * delta)
	else:
		pass
		#current_speed = clamp(current_speed, 0.0, max_speed)

func apply_gravity_and_lift(delta):
	linear_velocity.y -= gravity * delta
	var lift_force = max_lift_force * (abs(current_speed) / max_speed) * lift_force_multiplier
	linear_velocity.y += lift_force * delta

func move_plane(delta):
	pitch = move_toward(pitch, 0.0, delta * pitch_return_speed)
	roll = move_toward(roll, 0.0, delta * roll_return_speed)
	yaw = move_toward(yaw, 0.0, delta * yaw_return_speed)
	
	rotation_degrees.x = pitch
	rotation_degrees.y = yaw
	rotation_degrees.z = roll
	var forward_direction = -transform.basis.z
	linear_velocity.x = forward_direction.x * current_speed
	linear_velocity.z = forward_direction.z * current_speed
	
