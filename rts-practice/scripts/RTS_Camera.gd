extends Node3D

#camera_move
@export_range(0, 100, 1) var camera_move_speed: float = 20.0

#camera_rotate
var camera_rotation_direction: int = 0
@export_range(0, 10, 0.1) var camera_rotation_speed: float = 0.2
@export_range(0, 20, 1) var camera_base_rotation_speed: float = 6

# camera_zoom
var camera_zoom_direction: int = 0
@export_range(0, 100, 1) var camera_zoom_speed = 40.0
@export_range(0, 100, 1) var camera_zoom_min = 10.0
@export_range(0, 100, 1) var camera_zoom_max = 25.0
@export_range(0, 2, 0.1) var camera_zoom_damp = 0.92

# camera_pan
@export_range(0, 32, 4) var camera_automatic_pan_margin: int = 16
@export_range(0, 20, 0.5) var camera_automatic_pan_speed: float = 12

# Flags
var camera_can_process: bool = true
var camera_can_move_base: bool = true
var camera_can_zoom: bool = true
var camera_can_automatic_pan: bool = false
var camera_can_rotate: bool = true

# Internal Flag
var camera_is_rotating_base: bool = false

# Nodes
@onready var camera_socket: Node3D = $camera_socket
@onready var camera: Camera3D = $camera_socket/Camera3D

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	if !camera_can_process: return
	
	camera_base_move(delta)
	camera_zoom(delta)
	camera_automatic_pan(delta)
	camera_base_rotate(delta)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action("zoom_in"):
		camera_zoom_direction = -1
	elif event.is_action("zoom_out"):
		camera_zoom_direction = 1
	
	if event.is_action_pressed("camera_rotate_left"):
		camera_rotation_direction = 1
		camera_is_rotating_base = true
	elif event.is_action_pressed("camera_rotate_right"):
		camera_rotation_direction = -1
		camera_is_rotating_base = true
	elif event.is_action_released("camera_rotate_left") or event.is_action_released("camera_rotate_right"):
		camera_is_rotating_base = false


# Move camera with WASD
func camera_base_move(delta: float) -> void:
	if !camera_can_move_base: return
	
	var velocity_direction: Vector3 = Vector3.ZERO
	if Input.is_action_pressed("camera_forward"): velocity_direction -= transform.basis.z
	if Input.is_action_pressed("camera_backward"): velocity_direction += transform.basis.z
	if Input.is_action_pressed("camera_left"): velocity_direction -= transform.basis.x
	if Input.is_action_pressed("camera_right"): velocity_direction += transform.basis.x
	
	position += velocity_direction.normalized() * delta * camera_move_speed

# Camera base rotate
func camera_base_rotate(delta: float) -> void:
	if !camera_can_rotate or !camera_is_rotating_base: return
	
	camera_base_rotate_left_right(delta, camera_rotation_direction * camera_base_rotation_speed)

# Rotate base of the camera left / right
func camera_base_rotate_left_right(delta: float, direction: int) -> void:
	rotation.y += direction * camera_rotation_speed * delta

# Zoom with the camera
func camera_zoom(delta: float) -> void:
	if !camera_can_zoom: return
	
	var new_zoom: float = clamp(camera.position.z + camera_zoom_speed * camera_zoom_direction * delta, camera_zoom_min, camera_zoom_max)
	camera.position.z = new_zoom
	camera_zoom_direction *= camera_zoom_damp

# Move screen with mouse
func camera_automatic_pan(delta: float) -> void:
	if !camera_can_automatic_pan: return
	
	var viewport_current: Viewport =  get_viewport()
	var pan_direction: Vector2 = Vector2(-1, -1)
	var viewport_visible_rectangle: Rect2i = Rect2i(viewport_current.get_visible_rect())
	var viewport_size: Vector2i = viewport_visible_rectangle.size
	var current_mouse_position: Vector2 = viewport_current.get_mouse_position()
	var margin: float = camera_automatic_pan_margin
	var zoom_factor: float = camera.position.z * 0.1
	
	if((current_mouse_position.x < margin) or (current_mouse_position.x > viewport_size.x - margin)):
		if current_mouse_position.x > viewport_size.x / 2:
			pan_direction.x = 1
		translate(Vector3(pan_direction.x * camera_automatic_pan_speed * zoom_factor * delta, 0, 0))
	
	if((current_mouse_position.y < margin) or (current_mouse_position.y > viewport_size.y - margin)):
		if current_mouse_position.y > viewport_size.y / 2:
			pan_direction.y = 1
		translate(Vector3(0, 0, pan_direction.y * camera_automatic_pan_speed * zoom_factor * delta))
