extends CharacterBody3D

const MODULE_CAMERA: GDScript = preload("res://scripts/moduleCamera.gd")

var steerSpeed: float = 4.0
var navigationPathGoalPosition: Vector3
var rotationFast: bool = true

@onready var selection_circle: MeshInstance3D = $SelectionCircle
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var navigationPathTimer: Timer = $Timer
@onready var animPlayer: AnimationPlayer = $AnimationPlayer

var selected: bool = false:
	set(value):
		selected = value
		selection_circle.visible = value

func _ready() -> void:
	selection_circle.visible = false
	navigation_agent.velocity_computed.connect(charaterMove)
	navigationPathTimer.timeout.connect(navigationPathTimerUpdate)
	animPlayer.play("Idle")

# detects right mouse input and update goal position
func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("mouse_rightclick"):
		var mouse_pos: Vector2 = get_viewport().get_mouse_position()
		var camera: Camera3D = get_viewport().get_camera_3d()
		var cameraRaycastCords: Vector3 = MODULE_CAMERA.getVerctor3FromCameraRaycast(camera, mouse_pos)
		if cameraRaycastCords != Vector3.ZERO:
			navigation_agent.set_target_position(cameraRaycastCords)
			navigationPathGoalPosition = cameraRaycastCords

# updates velocity of agent so he knows where to move
func _physics_process(delta: float) -> void:
	if navigation_agent.is_navigation_finished():
		if !is_on_floor():
			velocity.y -= 9.8 * delta
			move_and_slide()
		animPlayer.play("Idle")
		return
	
	animPlayer.play("walk")
	var nextPosition: Vector3 = navigation_agent.get_next_path_position()
	var direction: Vector3 = global_position.direction_to(nextPosition) * navigation_agent.max_speed
	
	rotateToDirection(direction, delta)
	
	var steeredVelocity: Vector3 = (direction - velocity) * delta * steerSpeed
	var newAgentVelocity: Vector3 = velocity + steeredVelocity
	navigation_agent.set_velocity(newAgentVelocity)

# make a rotation for character before starting to move
func rotateToDirection(dir: Vector3, delta: float) -> void:
	if rotationFast:
		rotation.y = atan2(-dir.x, -dir.z) + deg_to_rad(90)
	else:
		var targetAngle: float = atan2(-dir.x, -dir.z) + deg_to_rad(90)
		var angleDiff: float = wrapf(targetAngle - rotation.y, -PI, PI)
		rotation.y += angleDiff * delta * steerSpeed

# method to move character after it got a signal
func charaterMove(newVelocity: Vector3) -> void:
	var currentVelocity: float = velocity.y
	velocity = newVelocity
	
	if !is_on_floor():
		velocity.y = currentVelocity - 9.8 * get_physics_process_delta_time()
	else:
		velocity.y = 0.0
	
	move_and_slide()

# updates navigation path of characters after timer run out
func navigationPathTimerUpdate() -> void:
	if navigation_agent.is_navigation_finished(): return
	
	navigation_agent.set_target_position(navigationPathGoalPosition)
