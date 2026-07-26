class_name BuilderUnit
extends "res://scripts/base_unit.gd"

@export var build_power: float = 10.0

var is_building: bool = false
var build_target: Node3D = null

func moveUnit(newMovementGoal: Vector3 = Vector3.ZERO) -> void:
	if is_building:
		stop_building()
	super.moveUnit(newMovementGoal)

func assign_to_build(building: Node3D) -> void:
	build_target = building
	navigation_agent.target_desired_distance = building.get_interaction_range()
	moveUnit(building.global_position)
	is_building = true

func stop_building() -> void:
	is_building = false
	build_target = null

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	if is_building and is_instance_valid(build_target):
		var required_range: float = build_target.get_interaction_range()
		var distance: float = global_position.distance_to(build_target.global_position)
		if distance <= required_range:
			build_target.add_build_progress(build_power * delta)
