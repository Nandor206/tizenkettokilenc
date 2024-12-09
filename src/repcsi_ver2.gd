extends RigidBody3D

# Beállítható változók
@export var max_speed: float = 650.0  # Maximális sebesség előre
@export var acceleration_multiplier: float = 10.0  # Sebesség növekedés mértéke (10%-os lépések)
@export var gravity: float = 9.8  # Gravitációs erő (m/s²)
@export var max_lift_force: float = 150.0  # Maximális emelkedési erő (anti-gravitáció)
@export var lift_force_multiplier: float = 0.5  # Anti-gravitáció mértéke a sebesség függvényében
@export var roll_sensitivity: float = 0.05  # Roll érzékenysége
@export var yaw_sensitivity: float = 0.05  # Yaw érzékenysége
@export var pitch_sensitivity: float = 0.05  # Pitch érzékenysége
@export var roll_return_speed: float = 1.0  # Roll visszatérés gyorsasága
@export var yaw_return_speed: float = 1.0  # Yaw visszatérés gyorsasága
@export var pitch_return_speed: float = 1.0  # Pitch visszatérés gyorsasága
@export var damping_factor: float = 0.5  # Lineáris csillapítás
@export var angular_damping_factor: float = 0.1  # Szögcsillapítás
@export var boost_duration: float = 5.0  # Boost időtartama másodpercben
@export var boost_speed_factor: float = 1.1  # Boost sebesség növelése (110%)

# Állapotváltozók
var current_speed: float = 0.0  # Jelenlegi sebesség
var pitch: float = 0.0  # Függőleges nézés (X-tengely)
var yaw: float = 0.0  # Oldalirányú nézés (Y-tengely)
var roll: float = 0.0  # Forgás (Z-tengely)
var is_falling: bool = false  # A gép esik-e
var boost_cooldown: float = 0.0
var boost_timer: float = 0.0  # Boost időzítő
var is_boosting: bool = false  # Boost aktiválva van-e

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)  # Egér rögzítése és elrejtése
	boost_timer = 0.0
	boost_cooldown = 0.0
	$Control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Csillapítási beállítások
	linear_damp = damping_factor
	angular_damp = angular_damping_factor

func _input(event):
	# Egér mozgás kezelése
	if event is InputEventMouseMotion:
		handle_mouse_input(event)


	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if Input.is_action_just_pressed("mousedown"):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# Billentyűzet bemenetek kezelése
	if Input.is_action_pressed("forward"):  # "W" gomb
		start_accelerating()
	if Input.is_action_pressed("backward"):  # "S" gomb
		stop_accelerating()


	# Boost gomb (pl. Shift) lenyomása esetén boost aktiválása
	if Input.is_action_just_pressed("boost"):
		start_boost()

func _physics_process(delta):
	# Ellenőrizzük, hogy a gép esik-e (a sebesség függőlegesen)
	check_falling_state()

	apply_gravity_and_lift(delta)
	move_plane(delta)

	# Boost időzítő frissítése
	if is_boosting:
		boost_timer -= delta
		if boost_timer <= 0:
			stop_boost()
		
	if Input.is_action_pressed("roll_r"):  # Jobbra roll (D)
		roll_right()
	if Input.is_action_pressed("roll_l"):  # Balra roll (A)
		roll_left()

	if Input.is_action_pressed("yaw_r"):  # Jobbra yaw (Jobb nyíl)
		yaw_right()
	if Input.is_action_pressed("yaw_l"):  # Balra yaw (Bal nyíl)
		yaw_left()

# Sebesség növekedése előre (automatikusan)
func start_accelerating():
	# Ha a sebesség kisebb, mint a maximális, növeljük 10%-kal
	if current_speed < max_speed:
		var speed_increment = max_speed * 0.1  # 10%-os lépések
		current_speed += speed_increment
		current_speed = clamp(current_speed, 0.0, max_speed)

# Sebesség csökkentése hátra
func stop_accelerating():
	# Ha a sebesség nagyobb, mint 0, csökkentjük a sebességet
	if current_speed > 0:
		current_speed -= acceleration_multiplier * get_process_delta_time()
		current_speed = clamp(current_speed, 0.0, max_speed)

# Boost aktiválása
func start_boost():
	if not is_boosting:
		is_boosting = true
		boost_timer = boost_duration  # Boost időzítő kezdete
		current_speed *= boost_speed_factor  # Sebesség 10%-kal növelve
		print("Boost activated!")

# Boost leállítása
func stop_boost():
	is_boosting = false
	current_speed = min(current_speed, max_speed)  # Biztosítjuk, hogy ne lépje túl a max sebességet
	print("Boost ended!")

# Egérmozgás kezelése (pitch, yaw, roll)
func handle_mouse_input(event):
	return
	# Függőleges nézés (pitch)
	pitch -= event.relative.y * pitch_sensitivity
	pitch = clamp(pitch, -75.0, 75.0)  # Max ±75 fokos függőleges dőlés

	# Oldalirányú nézés (yaw)
	yaw -= event.relative.x * yaw_sensitivity

	# Forgás (roll) az egérrel (most már fordítva, ha jobbra viszed, jobbra forog)
	roll += event.relative.x * roll_sensitivity  # Itt megfordítjuk az irányt

# Gravitáció és anti-gravitáció alkalmazása
func apply_gravity_and_lift(delta):
	# Alap gravitáció hatás a repülőre
	linear_velocity.y -= gravity * delta

	# Anti-gravitáció mértéke a sebesség függvényében (minél gyorsabb, annál erősebb)
	var lift_force = max_lift_force * (abs(current_speed) / max_speed) * lift_force_multiplier
	linear_velocity.y += lift_force * delta

# Általános mozgás és stabilizálás
func move_plane(delta):
	# Automatikus visszaállás az alapállapotba (pitch, roll, yaw)
	pitch = lerp(pitch, 0.0, delta * pitch_return_speed)
	roll = lerp(roll, 0.0, delta * roll_return_speed)
	yaw = lerp(yaw, 0.0, delta * yaw_return_speed)

	# Forgatások alkalmazása
	rotation_degrees.x = pitch
	rotation_degrees.y = yaw
	rotation_degrees.z = roll

	# Mozgás előre a repülő aktuális irányában
	var forward_direction = -transform.basis.z
	linear_velocity.x = forward_direction.x * current_speed
	linear_velocity.z = forward_direction.z * current_speed

# Ellenőrizzük, hogy a gép esik-e
func check_falling_state():
	# Ha a Y tengely sebessége negatív, a gép esik
	if linear_velocity.y < 0:
		is_falling = true
	else:
		is_falling = false

# Roll forgatás jobbra
func roll_right():
	roll -= roll_sensitivity * get_process_delta_time()

# Roll forgatás balra
func roll_left():
	roll += roll_sensitivity * get_process_delta_time()

# Yaw forgatás jobbra
func yaw_right():
	yaw -= yaw_sensitivity * get_process_delta_time()  # Jobbra menjen (kevesebb legyen az érték)

# Yaw forgatás balra
func yaw_left():
	yaw += yaw_sensitivity * get_process_delta_time()  # Balra menjen (több legyen az érték)
