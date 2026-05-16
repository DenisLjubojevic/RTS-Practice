extends CharacterBody3D

const MODULE_CAMERA: GDScript = preload("res://scripts/moduleCamera.gd")

var steerSpeed: float = 1.0
var navigationPathGoalPosition: Vector3 

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
		animPlayer.play("Idle")
		return
	
	animPlayer.play("walk")
	var nextPosition: Vector3 = navigation_agent.get_next_path_position()
	var direction: Vector3 = global_position.direction_to(nextPosition) * navigation_agent.max_speed
	var steeredVelocity: Vector3 = (direction - velocity) * delta * steerSpeed
	var newAgentVelocity: Vector3 = velocity + steeredVelocity
	navigation_agent.set_velocity(newAgentVelocity)

# method to move character after it got a signal
func charaterMove(newVelocity: Vector3) -> void:
	velocity = newVelocity
	move_and_slide()
	rotation.y = atan2(velocity.x, velocity.z) + deg_to_rad(-90)

# updates navigation path of characters after timer run out
func navigationPathTimerUpdate() -> void:
	if navigation_agent.is_navigation_finished(): return
	
	navigation_agent.set_target_position(navigationPathGoalPosition)
