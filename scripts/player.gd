extends CharacterBody3D

var speed
const WALK_SPEED = 10.0
const SPRINT_SPEED = 15.0
const JUMP_VELOCITY = 18
const SENSITIVITY = 0.001
var can_double_jump = true

# More forgivable jumps variables
var can_jump = true
var is_on_ground = true
var jump_timer: Timer

# Bob variables
const BOB_FREQ = 1.5
const BOB_AMP = 0.04
var t_bob = 0.0

# FOV variables
const BASE_FOV = 75.0
const SPRINT_FOV = BASE_FOV * 1.2
const FOV_TRANSITION_SPEED = 5.0
var target_fov = 0.0

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# More forgivable jumps
	jump_timer = Timer.new()
	jump_timer.wait_time = 0.15
	jump_timer.one_shot = true
	add_child(jump_timer)
	jump_timer.connect("timeout", Callable(self, "_on_jump_timer_timeout"))

# Mouse controls
func _unhandled_input(event):
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))

func _physics_process(delta: float) -> void:
	# Add the gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
		# More forgivable jumps
		if is_on_ground:
			is_on_ground = false
			start_jump_timer()
	else:
		# More forgivable jumps
		is_on_ground = true
		can_jump = true
		
		# Reset double jump ability
		can_double_jump = true

	# Handle jump
	if Input.is_action_just_pressed("jump") and can_jump:
		velocity.y = JUMP_VELOCITY
		can_jump = false
	elif Input.is_action_just_pressed("jump") and not is_on_floor() and can_double_jump:
		velocity.y = JUMP_VELOCITY
		can_double_jump = false
		
	# Handle sprint
	if Input.is_action_pressed("sprint"):
		speed = SPRINT_SPEED
		target_fov = SPRINT_FOV
	else:
		speed = WALK_SPEED
		target_fov = BASE_FOV
		
	# Transition the FOV
	camera.fov = lerp(camera.fov, target_fov, FOV_TRANSITION_SPEED * delta)

	# Get the input direction and handle the movement/deceleration
	# As good practice, you should replace UI actions with custom gameplay actions
	var input_dir := Input.get_vector("left", "right", "forward", "back")
	var direction := (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 8.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 8.0)
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 8.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 8.0)
		
	# Head bob
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)
	
	# To quit the game since mouse is locked (will change this when an actual menu exists)
	if Input.is_action_pressed("temp_quit"):
		get_tree().quit()

	move_and_slide()

func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP	
	return pos

func start_jump_timer():
	jump_timer.start()
	print("jump timer started")
	
func _on_jump_timer_timeout():
	can_jump = false
	print("timer ended")
