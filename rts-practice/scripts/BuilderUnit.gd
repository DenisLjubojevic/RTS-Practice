class_name BuilderUnit
extends "res://scripts/base_unit.gd"

enum Task { NONE, BUILD, HARVEST, DELIVER }

@export var build_power: float = 10.0
@export var harvest_rate: float = 2.0
@export var carry_capacity: int = 10

var task: Task = Task.NONE
var build_target: Node3D = null
var harvest_target: ResourceNode = null
var dropoff_target: Node3D = null

var carried_type: String = ""
var carried_amount: int = 0
var _gather_buffer: float = 0.0
var _default_desired_distance: float

func _ready() -> void:
	super._ready()
	_default_desired_distance = navigation_agent.target_desired_distance

func moveUnit(newMovementGoal: Vector3 = Vector3.ZERO) -> void:
	clear_task()
	super.moveUnit(newMovementGoal)

func go_to(pos: Vector3, stop_distance: float) -> void:
	navigation_agent.target_desired_distance = stop_distance
	super.moveUnit(pos)

func clear_task() -> void:
	task = Task.NONE
	build_target = null
	harvest_target = null
	dropoff_target = null
	_gather_buffer = 0.0
	navigation_agent.target_desired_distance = _default_desired_distance

func assign_to_build(building: Node3D) -> void:
	clear_task()
	task = Task.BUILD
	build_target = building
	go_to(building.position, building.get_interaction_range())

func stop_building(building: Node3D = null) -> void:
	if task != Task.BUILD:
		return
	if building != null and building != build_target:
		return
	clear_task()

func assign_to_harvest(resource: ResourceNode) -> void:
	clear_task()
	if carried_type != resource.resource_type:
		carried_amount = 0
	carried_type = resource.resource_type
	task = Task.HARVEST
	harvest_target = resource
	if carried_amount >= carry_capacity:
		start_delivery()
	else:
		go_to_resource(resource)

func start_delivery() -> void:
	dropoff_target = find_dropoff()
	if dropoff_target == null:
		clear_task()
		return
	task = Task.DELIVER
	go_to(dropoff_target.global_position, dropoff_target.get_interaction_range())

func find_dropoff() -> Node3D:
	var best: Node3D = null
	var best_distance: float = INF
	for building in get_tree().get_nodes_in_group("DropOffs"):
		if not building.is_constructed:
			continue
		var dist: float = global_position.distance_squared_to(building.global_position)
		if dist < best_distance:
			best_distance = dist
			best = building
	return best

func go_to_resource(resource: ResourceNode) -> void:
	harvest_target = resource
	go_to(resource.global_position, resource.get_interaction_range())

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	match task:
		Task.BUILD:
			process_build(delta)
		Task.HARVEST:
			process_harvest(delta)
		Task.DELIVER:
			process_delivery()

func process_build(delta: float) -> void:
	if not is_instance_valid(build_target):
		clear_task()
		return
	var dist: float = global_position.distance_to(build_target.global_position)
	if dist <= build_target.get_interaction_range():
		build_target.add_build_progress(build_power * delta)

func process_harvest(delta: float) -> void:
	if not is_instance_valid(harvest_target) or harvest_target.amount <= 0:
		on_harvest_target_lost()
		return
	if global_position.distance_to(harvest_target.global_position) > harvest_target.get_interaction_range():
		return
	
	_gather_buffer += harvest_rate * delta
	var whole: int = int(_gather_buffer)
	if whole <= 0:
		return
	_gather_buffer -= whole
	carried_amount += harvest_target.take(mini(whole, carry_capacity - carried_amount))
	if carried_amount >= carry_capacity:
		start_delivery()

func on_harvest_target_lost() -> void:
	var next: ResourceNode = find_nearby_resource(carried_type)
	if next != null and carried_amount < carry_capacity:
		go_to_resource(next)
	elif carried_amount > 0:
		start_delivery()
	else:
		clear_task()

func find_nearby_resource(type: String, search_radius: float = 15.0) -> ResourceNode:
	var best: ResourceNode = null
	var best_dist: float = search_radius * search_radius
	for res in get_tree().get_nodes_in_group("Resources"):
		if res.resource_type != type or res.amount <= 0:
			continue
		var dist: float = global_position.distance_squared_to(res.global_position)
		if dist < best_dist:
			best_dist = dist
			best = res
	return best

func _start_delivery() -> void:
	dropoff_target = find_dropoff()
	if dropoff_target == null:
		clear_task()
		return
	task = Task.DELIVER
	go_to(dropoff_target.global_position, dropoff_target.get_interaction_range())

func process_delivery() -> void:
	if not is_instance_valid(dropoff_target):
		_start_delivery()
		return
	if global_position.distance_to(dropoff_target.global_position) > dropoff_target.get_interaction_range():
		return
	
	Globals.add_resource(carried_type, carried_amount)
	carried_amount = 0
	task = Task.HARVEST
	if is_instance_valid(harvest_target) and harvest_target.amount > 0:
		go_to_resource(harvest_target)
	else:
		on_harvest_target_lost()
