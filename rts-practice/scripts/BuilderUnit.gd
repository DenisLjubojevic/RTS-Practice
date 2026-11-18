class_name BuilderUnit
extends "res://scripts/base_unit.gd"

enum Task { NONE, BUILD, HARVEST, DELIVER }

@export var build_power: float = 10.0
@export var harvest_rate: float = 2.0
@export var carry_capacity: int = 10
@export var axe: Node3D
@export var hammer: Node3D
@export var box: Node3D

const TASK_VISUALS: Dictionary = {
	Task.NONE:    {"anim": "", "tool": "", "moving": false},
	Task.BUILD:   {"anim": "Building", "tool": "hammer", "moving": false},
	Task.HARVEST: {"anim": "Chop", "tool": "axe", "moving": false},
	Task.DELIVER: {"anim": "Delivery", "tool": "box", "moving": true},
}

var task: Task = Task.NONE
var tools: Dictionary = {}
var _working: bool = false

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
	tools = {"axe": axe, "hammer": hammer, "box": box}
	refresh_visuals()

func set_task(new_task: Task) -> void:
	task = new_task
	_working = false
	refresh_visuals()

func set_working(value: bool) -> void:
	if _working == value:
		return
	_working = value
	refresh_visuals()

func refresh_visuals() -> void:
	var visuals: Dictionary = TASK_VISUALS[task]
	var active: bool = _working or visuals["moving"]
	work_animation = visuals["anim"] if _working else ""
	move_animation = visuals["anim"] if visuals["moving"] else "walk"
	for tool_name in tools:
		var tool_node: Node3D = tools[tool_name]
		if tool_node != null:
			tool_node.visible = active and tool_name == visuals["tool"]

func moveUnit(newMovementGoal: Vector3 = Vector3.ZERO) -> void:
	clear_task()
	super.moveUnit(newMovementGoal)

func go_to(pos: Vector3, stop_distance: float) -> void:
	navigation_agent.target_desired_distance = stop_distance
	super.moveUnit(pos)

func clear_task() -> void:
	build_target = null
	harvest_target = null
	dropoff_target = null
	_gather_buffer = 0.0
	navigation_agent.target_desired_distance = _default_desired_distance
	set_task(Task.NONE)

func assign_to_build(building: Node3D) -> void:
	clear_task()
	set_task(Task.BUILD)
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
	set_task(Task.HARVEST)
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
	set_task(Task.DELIVER)
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
	var in_range: bool = global_position.distance_to(build_target.global_position) <= build_target.get_interaction_range()
	set_working(in_range)
	if in_range:
		build_target.add_build_progress(build_power * delta)

func process_harvest(delta: float) -> void:
	if not is_instance_valid(harvest_target) or harvest_target.amount <= 0:
		set_working(false)
		on_harvest_target_lost()
		return
	var in_range: bool = global_position.distance_to(harvest_target.global_position) <= harvest_target.get_interaction_range()
	set_working(in_range)
	if not in_range:
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

func process_delivery() -> void:
	if not is_instance_valid(dropoff_target):
		start_delivery()
		return
	if global_position.distance_to(dropoff_target.global_position) > dropoff_target.get_interaction_range():
		return
	
	Globals.add_resource(carried_type, carried_amount)
	carried_amount = 0
	set_task(Task.HARVEST)
	if is_instance_valid(harvest_target) and harvest_target.amount > 0:
		go_to_resource(harvest_target)
	else:
		on_harvest_target_lost()
