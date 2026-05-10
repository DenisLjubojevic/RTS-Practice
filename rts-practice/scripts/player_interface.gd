extends Node2D

# Nodes
@onready var player_camera: Node3D = $camera_base
@onready var player_camera_visibleunits_Area3D: Area3D = $camera_base/visible_units_ares3D

# Variables
@onready var visibleUnitsInArea: Dictionary =  {}
var selectedUnits: Array = []

# Dragging
var drag_start: Vector2 = Vector2.ZERO
var is_dragging: bool = false

func _ready() -> void:
	initalizeInterface() 

# detects when unit has entered visible area
func unitEnterVisibleArea(unit: CharacterBody3D) -> void:
	var unitId: int = unit.get_instance_id()
	
	if visibleUnitsInArea.keys().has(unitId): return
	visibleUnitsInArea[unitId] = unit

# detects when unit has exited visible area
func unitExitVisibleArea(unit: CharacterBody3D) -> void:
	var unitId: int = unit.get_instance_id()
	
	if !visibleUnitsInArea.keys().has(unitId): return
	visibleUnitsInArea.erase(unitId)

func initalizeInterface() -> void:
	player_camera_visibleunits_Area3D.body_entered.connect(unitEnterVisibleArea)
	player_camera_visibleunits_Area3D.body_exited.connect(unitExitVisibleArea)

# select all unit in selectBox
func selectUnits() -> void:
	var drag_end: Vector2 = get_global_mouse_position()
	var rect: Rect2 = Rect2(drag_start, drag_end - drag_start).abs()
	var camera = get_viewport().get_camera_3d()
	
	for unit in visibleUnitsInArea.values():
		if !is_instance_valid(unit): continue
		var screen_pos = camera.unproject_position(unit.global_position)
		if rect.has_point(screen_pos):
			unit.selected = true
			if !selectedUnits.has(unit):
				selectedUnits.append(unit)

# deselect all units
func deselectAllUnits() -> void:
	for unit in selectedUnits:
		if is_instance_valid(unit):
			unit.selected = false
	selectedUnits.clear()

# detecting mouse left btn clicked
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			drag_start = get_global_mouse_position()
			is_dragging = true
			deselectAllUnits()
		else:
			if is_dragging:
				selectUnits()
			is_dragging = false
			queue_redraw()
	
	if event is InputEventMouseMotion and is_dragging:
		queue_redraw()

# drawing selection box
func _draw() -> void:
	if !is_dragging: return
	
	var drag_end = get_global_mouse_position()
	var rect = Rect2(drag_start, drag_end - drag_start)
	
	draw_rect(rect, Color(0.49, 0.81, 1.0, 0.15))
	draw_rect(rect, Color(0.49, 0.81, 1.0, 0.9), false, 1.5)
