extends RigidBody3D

# Beállítható változók
@export var max_speed: float = 350.0  # Maximális sebesség előre
@export var acceleration_multiplier: float = 7.5  # Sebesség növekedés mértéke (10%-os lépések)
@export var gravity: float = 9.8  # Gravitációs erő (m/s²)
@export var max_lift_force: float = 150.0  # Maximális emelkedési erő (anti-gravitáció)
@export var lift_force_multiplier: float = 0.5  # Anti-gravitáció mértéke a sebesség függvényében
@export var roll_sensitivity: float = 0.25  # Roll érzékenysége
@export var yaw_sensitivity: float = 0.15  # Yaw érzékenysége
@export var pitch_sensitivity: float = 0.15  # Pitch érzékenysége
@export var roll_return_speed: float = 1.5  # Roll visszatérés gyorsasága
@export var yaw_return_speed: float = 1.5  # Yaw visszatérés gyorsasága
@export var pitch_return_speed: float = 1.5  # Pitch visszatérés gyorsasága
@export var damping_factor: float = 0.5  # Lineáris csillapítás
@export var angular_damping_factor: float = 0.1  # Szögcsillapítás
@export var boost_duration: float = 5.0  # Boost időtartama másodpercben
@export var boost_speed_factor: float = 1.1  # Boost sebesség növelése (110%)
@export var boost_cooldown_duration: float = 10.0  # Boost újratöltési idő

# UI elemek (az első kódból átemelve)
@onready var speed_label: RichTextLabel = $Control/SpeedLabel
@onready var boost_label: RichTextLabel = $Control/BoostLabel

# Állapotváltozók
var current_speed: float = 0.0  # Jelenlegi sebesség
var pitch: float = 0.0  # Függőleges nézés (X-tengely)
var yaw: float = 0.0  # Oldalirányú nézés (Y-tengely)
var roll: float = 0.0  # Forgás (Z-tengely)
var is_falling: bool = false  # A gép esik-e
var boost_timer: float = 0.0  # Boost időzítő
var boost_cooldown: float = 0.0  # Boost újratöltési időzítő
var is_boosting: bool = false  # Boost aktiválva van-e

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	boost_timer = 0.0
	boost_cooldown = 0.0
	$Control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	linear_damp = damping_factor
	angular_damp = angular_damping_factor

func _input(event):
	if event is InputEventMouseMotion:
		handle_mouse_input(event)


	if Input.is_action_pressed("forward"):
		move_forward()
	if Input.is_action_pressed("backward"):
		move_backward()

	if Input.is_action_just_pressed("boost") and boost_cooldown <= 0.0:
		activate_boost()

func _process(_delta):
	update_ui()

func _physics_process(delta):
	check_falling_state()
	apply_gravity_and_lift(delta)
	move_plane(delta)
	update_speed(delta)

	if Input.is_action_pressed("roll_r"):
		roll_right()
	if Input.is_action_pressed("roll_l"):
		roll_left()
	if Input.is_action_pressed("yaw_r"):
		yaw_right()
	if Input.is_action_pressed("yaw_l"):
		yaw_left()

func update_ui():
	speed_label.text = "Speed: %.2f" % current_speed
	if boost_cooldown > 0:
		boost_label.text = "Boost Cooldown: %.1f s" % boost_cooldown
	else:
		boost_label.text = "Boost Ready!"

func handle_mouse_input(event):
	pitch -= event.relative.y * pitch_sensitivity  * get_process_delta_time()*3
	pitch = clamp(pitch, -75.0, 75.0)
	yaw -= event.relative.x * yaw_sensitivity  * get_process_delta_time()*3
	roll += event.relative.x * roll_sensitivity  * get_process_delta_time()*3

func move_forward():
	if current_speed < max_speed:
		var speed_increment = max_speed * 0.1  # 10%-os lépések
		current_speed += speed_increment
		current_speed = clamp(current_speed, 0.0, max_speed)

func move_backward():
	if current_speed > 0:
		current_speed -= acceleration_multiplier * get_process_delta_time()
		current_speed = clamp(current_speed, 0.0, max_speed)

func roll_right():
	roll -= roll_sensitivity * get_process_delta_time() * 250

func roll_left():
	roll += roll_sensitivity * get_process_delta_time() * 250

func yaw_right():
	yaw -= yaw_sensitivity * get_process_delta_time() * 250

func yaw_left():
	yaw += yaw_sensitivity * get_process_delta_time() * 250

func activate_boost():
	is_boosting = true
	boost_timer = boost_duration
	boost_cooldown = boost_cooldown_duration
	current_speed *= boost_speed_factor

func update_speed(delta):
	if is_boosting:
		boost_timer -= delta
		if boost_timer <= 0.0:
			is_boosting = false

	if boost_cooldown > 0.0:
		boost_cooldown -= delta

	if not is_boosting:
		current_speed = min(current_speed, max_speed)

func apply_gravity_and_lift(delta):
	linear_velocity.y -= gravity * delta
	var lift_force = max_lift_force * (abs(current_speed) / max_speed) * lift_force_multiplier
	linear_velocity.y += lift_force * delta

func move_plane(delta):
	#pitch = lerp(pitch, 0.0, delta * pitch_return_speed)
	#roll = lerp(roll, 0.0, delta * roll_return_speed)
	#yaw = lerp(yaw, 0.0, delta * yaw_return_speed)

	rotation_degrees.x = pitch
	rotation_degrees.y = yaw
	rotation_degrees.z = roll
	var forward_direction = -transform.basis.z
	linear_velocity.x = forward_direction.x * current_speed
	linear_velocity.z = forward_direction.z * current_speed

func check_falling_state():
	is_falling = linear_velocity.y < 0.0
