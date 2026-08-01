class_name BaseBuilding
extends Node3D

@export var building_type: String = "Unknown"
@export var construction_total: float = 100.0
@export var construction_site_mesh: Mesh = preload("res://models/constructionSite/constructionSite.obj")
@export var is_constructed: bool = false

@onready var model: Node3D = $Model
@onready var selection_collision: CollisionShape3D = $Model/StaticBody3D/CollisionShape3D
@onready var nav_obstacle: NavigationObstacle3D = $NavigationObstacle3D

var construction_progress: float = 0.0
var builders_assigned: Array = []
var construction_visual: Node3D = null

func _ready() -> void:
	if not is_in_group("Buildings"):
		add_to_group("Buildings")
	
	if not is_constructed:
		model.hide()
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.mesh = construction_site_mesh
		add_child(mesh_instance)
		construction_visual = mesh_instance
	
	setup_nav_obstacle()
	nav_obstacle.avoidance_enabled = true

func add_build_progress(amount: float) -> void:
	if is_constructed: return
	construction_progress = min(construction_progress + amount, construction_total)
	if construction_progress >= construction_total:
		finish_construction()

func finish_construction() -> void:
	is_constructed = true
	model.show()
	if is_instance_valid(construction_visual):
		construction_visual.queue_free()
	for builder in builders_assigned:
		if is_instance_valid(builder):
			builder.stop_building()
	builders_assigned.clear()

func get_construction_progress() -> float:
	if is_constructed:
		return -1.0
	return construction_progress / construction_total

func get_interaction_range() -> float:
	var shape: Shape3D = selection_collision.shape
	if shape is BoxShape3D: 
		var box: BoxShape3D = shape as BoxShape3D
		var footprint_diagonal: float = Vector2(box.size.x, box.size.z).length()
		return footprint_diagonal * 0.5 + 0.3
	return 1.5

func setup_nav_obstacle() -> void:
	var shape: Shape3D = selection_collision.shape
	if shape is BoxShape3D:
		var box: BoxShape3D = shape as BoxShape3D
		var hx: float = box.size.x * 0.5
		var hz: float = box.size.z * 0.5
		nav_obstacle.vertices = PackedVector3Array([
			Vector3(-hx, 0, -hz),
			Vector3(hx, 0, -hz),
			Vector3(hx, 0, hz),
			Vector3(-hx, 0, hz)
		])
	nav_obstacle.avoidance_enabled = true

func get_bar_height_offset() -> float:
	var aabb: AABB = model.get_aabb()
	return aabb.size.y + 0.5
