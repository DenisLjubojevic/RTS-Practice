extends Node3D

@export var unit_scene: PackedScene = preload("res://scenes/turtleUnit.tscn")
@export var train_time: float = 5.0
@export var building_type: String = "TurtleHQ"

@onready var spawn_point: Marker3D = $SpawnPoint
@onready var train_timer: Timer = $TrainTimer

var is_training: bool = false

func _ready() -> void:
	train_timer.timeout.connect(_on_train_finished)
	if not is_in_group("Buildings"):
		add_to_group("Buildings")

func train_unit() -> void:
	if is_training: return
	is_training = true
	train_timer.start(train_time)

func _on_train_finished() -> void:
	is_training = false
	var new_unit: Node3D = unit_scene.instantiate()
	get_tree().current_scene.add_child(new_unit)
	new_unit.transform.origin = spawn_point.global_position
	
	if not new_unit.is_in_group("Units"):
		new_unit.add_to_group("Units")
	
	var world: Node3D = get_tree().current_scene
	if world.has_method("register_unit"):
		world.register_unit(new_unit)

func get_train_progress() -> float:
	if not is_training:
		return -1.0
	return 1.0 - (train_timer.time_left / train_time)
