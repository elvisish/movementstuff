extends KinematicBody


onready var body : Spatial = $Body
onready var head : Spatial = $Body/Head
onready var cam : Camera = $Body/Head/Camera


export(float) var mouse_sensitivity := 5.0

export(float) var stop_speed := 4.0
export(float) var move_speed := 20.0
export(float) var max_slope_angle := 50.0

export(float) var gravity := 60.0
export(float) var max_fall_speed := 50.0
export(float) var jump_height := 2.0

export(float) var accel_ground := 10.0
export(float) var accel_air := 1.0
#export(float) var accel_water := 4.0

export(float) var friction_ground := 6.0
#export(float) var friction_water := 1.0

var queue_jump := false
var snap_vector := Vector3.ZERO
var grounded := false


var velocity := Vector3.ZERO

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func get_move_direction() -> Vector3:
	
	var input_dir := Vector2(
		Input.get_action_strength("down") - Input.get_action_strength("up"),
		Input.get_action_strength("right") - Input.get_action_strength("left")
	).clamped(1.0)
	
	return input_dir.x * body.global_transform.basis.z + input_dir.y * body.global_transform.basis.x


func _input(event):
	if event is InputEventMouseMotion:
		rotate_look(event.relative * 0.001 * mouse_sensitivity)


func rotate_look(amount : Vector2) -> void:
	body.rotation.y -= amount.x
	head.rotation.x = clamp(head.rotation.x - amount.y, -PI * 0.5, PI * 0.5)

func _process(delta):
	if Input.is_action_just_pressed("jump"):
		queue_jump = true
	if Input.is_action_just_released("jump"):
		queue_jump = false

func _physics_process(delta):
	grounded = is_on_floor()
	
	velocity.y = max(-max_fall_speed, velocity.y - (gravity if !grounded else 0.0) * delta)
	
	var h_target_dir : Vector3 = get_move_direction()
	if grounded:
		apply_friction(delta)
		accelerate(delta, h_target_dir, move_speed, accel_ground)
		snap_vector = -get_floor_normal()
		if queue_jump:
			velocity.y = sqrt(2 * jump_height * abs(gravity))
			queue_jump = false
			snap_vector = Vector3.ZERO
	else:
		accelerate(delta, h_target_dir, move_speed, accel_air)
		snap_vector = Vector3.ZERO
	
	#velocity = move_and_slide(velocity, Vector3.UP, true, 4, deg2rad(max_slope_angle), false)
	velocity = move_and_slide_with_snap(velocity, snap_vector, Vector3.UP, true, 4, deg2rad(max_slope_angle), false)


func accelerate(delta : float, p_target_dir : Vector3, p_target_speed : float, p_accel : float):
	var current_speed : float = velocity.dot(p_target_dir)
	var add_speed : float = p_target_speed - current_speed
	if add_speed > 0:
		var accel_speed : float = min(add_speed, p_accel * delta * p_target_speed)
		velocity += p_target_dir * accel_speed


func apply_friction(delta : float):
	
	var vec : Vector3 = velocity
	var speed : float = velocity.length()
	if is_zero_approx(speed):
		velocity = Vector3.ZERO
		return
	
	var drop : float = 0.0
	var control : float = max(speed, stop_speed)
	
	# ground friction
	if grounded:
		drop += control * friction_ground * delta
	
	# water friction not implemented
	var new_speed : float = max(0.0, speed - drop)
	new_speed /= speed
	
	velocity *= new_speed
