extends KinematicBody

onready var cam = $Camera
onready var gimbaly = $GimbalY
onready var gimbalx = $GimbalY/GimbalX

var speedLabel
var grounded = false
var wishJump = false

# Movement Varabiles
var deltaTime : float
export var gravity  : float = 20
export var friction : float = 6
export var moveSpeed              : float = 7.0   # Ground move speed
export var runAcceleration        : float = 14    # Ground accel
export var runDeacceleration      : float = 10    # Deacceleration that occurs when running on the ground
export var airAcceleration        : float = 2.0   # Air accel
export var airDeacceleration      : float = 2.0   # Deacceleration experienced when opposite strafing
export var airControl             : float = 0.3   # How precise air control is
export var jumpSpeed              : float = 8.0   # The speed at which the characters up axis gains when hitting jump
export var holdJumpToBhop         : bool = false  # When enabled allows player to just hold jump button to keep on bhopping perfectly
var playerFriction         : float = 0.0

# All Vector Varabiles
var moveDirection : Vector3 = Vector3()
var moveDirectionNorm : Vector3 = Vector3()
var playerVelocity : Vector3 = Vector3()
var playerTopVelocity : float = 0.0

export var mouseSens = .4

var forwardmove : Vector3 setget _set_forwardMove, _get_forwardMove
var rightmove : Vector3 setget _set_rightMove, _get_rightMove
var upmove : Vector3 setget _set_upMove, _get_upMove

func _get_forwardMove():
	return forwardmove
func _set_forwardMove(Newforwardmove):
	forwardmove = Newforwardmove
func _get_rightMove():
	return rightmove
func _set_rightMove(Newrightmove):
	rightmove = Newrightmove
func _get_upMove():
	return upmove
func _set_upMove(Newupmove):
	upmove = Newupmove

func _ready():
	#gimbaly.set_as_toplevel(true)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED) #Sets the mouse to captured

func _input(event):
	#This will rotate the cam based off mouse movement
	if event is InputEventMouseMotion:
		rotate_y(deg2rad(-event.relative.x * mouseSens))
		#gimbaly.rotate_y(deg2rad(-event.relative.x * mouseSens))
		gimbalx.rotate_x(deg2rad(-event.relative.y * mouseSens))
		gimbalx.rotation.x = clamp(gimbalx.rotation.x, deg2rad(-89), deg2rad(89))

func _process(delta):
	#gimbaly.global_transform.origin = global_transform.origin
	pass

func _physics_process(delta):
	#rotation.y = gimbaly.rotation.y
	
	deltaTime = delta
	
	#Calls all functions based off if player is on the ground or not
	QueueJump()
	if is_on_floor():
		GroundMove()
	else:
		AirMove()
	
	#This will move the player
	move_and_slide(playerVelocity, Vector3.UP)

func set_cmd():
	#Sets forward move and right move
	_set_forwardMove(-global_transform.basis.z * (Input.get_action_strength("ui_up") - Input.get_action_strength("ui_down")))
	_set_rightMove(-global_transform.basis.x * (Input.get_action_strength("ui_left") - Input.get_action_strength("ui_right")))

func QueueJump():
	#This lets you queue the next jump
	if holdJumpToBhop:
		wishJump = Input.is_action_pressed("jump")
		return
	
	if Input.is_action_just_pressed("jump"):
		wishJump = true
	
	if Input.is_action_just_released("jump"):
		wishJump = false

func AirMove():
	#Allows for movement to slightly increase as you move through the air
	var wishdir : Vector3
	#var wishvel : float = airAcceleration
	var accel : float
	
	set_cmd()
	
	wishdir = forwardmove + rightmove
	
	var wishspeed = wishdir.length()
	wishspeed *= moveSpeed
	
	wishdir = wishdir.normalized()
	moveDirectionNorm = wishdir
	
	var wishspeed2 = wishspeed
	if playerVelocity.dot(wishdir) < 0:
		accel = airDeacceleration
	else:
		accel = airAcceleration
	
	accelerate(wishdir, wishspeed, airAcceleration); # accel
	
	playerVelocity.y -= gravity * deltaTime

func GroundMove():
	#Allows for normal movement on the ground
	var wishdir : Vector3
	var wishvel : Vector3
	
	if !wishJump:
		ApplyFriction(1.0)
	else:
		ApplyFriction(0)
	
	set_cmd()
	
	wishdir = forwardmove + rightmove
	wishdir = wishdir.normalized()
	moveDirectionNorm = wishdir
	
	var wishspeed = wishdir.length()
	wishspeed *= moveSpeed
	
	accelerate(wishdir, wishspeed, runAcceleration)
	
	playerVelocity.y = 0
	
	if wishJump:
		playerVelocity.y = jumpSpeed
		wishJump = false
		#$AudioStreamPlayer.play()
	

func ApplyFriction(t : float):
	#Applys friction based off t
	var vec : Vector3 = playerVelocity
	var vel : float
	var speed : float
	var newspeed : float
	var control : float
	var drop : float
	
	vec.y = 0.0
	speed = vec.length()
	drop = 0.0
	
	if is_on_floor():
		if speed < runDeacceleration:
			control = runDeacceleration
		else:
			control = speed
		
		drop = control * friction * deltaTime * t;
	
	newspeed = speed - drop;
	playerFriction = newspeed;
	if newspeed < 0:
		newspeed = 0
	if speed > 0:
		newspeed /= speed
	
	playerVelocity.x *= newspeed
	playerVelocity.z *= newspeed
	

func accelerate(wishdir : Vector3, wishspeed : float, accel : float):
	#Allows the player to accelerate faster
	var addspeed : float
	var accelspeed : float
	var currentspeed : float
	
	currentspeed = playerVelocity.dot(wishdir)
	addspeed = wishspeed - currentspeed
	if addspeed <= 0:
		return
	accelspeed = accel * deltaTime * wishspeed;
	if accelspeed > addspeed:
		accelspeed = addspeed
	
	playerVelocity.x += accelspeed * wishdir.x
	playerVelocity.z += accelspeed * wishdir.z
	

