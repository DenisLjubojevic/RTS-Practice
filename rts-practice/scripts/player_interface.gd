extends Node2D

const MODULE_CAMERA: GDScript = preload("res://scripts/moduleCamera.gd")

# Nodes
@onready var player_camera: Node3D = $camera_base
@onready var player_camera_visibleunits_Area3D: Area3D = $camera_base/visible_units_ares3D

# Variables
@onready var visibleUnitsInArea: Dictionary =  {}
var selectedUnits: Array = []

# Dragging
var drag_start: Vector2 = Vector2.ZERO
var is_dragging: bool = false
var drag_threshold: float = 5.0 

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
			if !selectedUnits.has(unit):
				selectionAdd(unit)

# add one unit to selected array
func selectionAdd(unit: Node3D) -> void:
	selectedUnits.append(unit)
	unit.selected = true

func selectMultipleUnits(unitsToSelect: Array) -> void:
	for unit in unitsToSelect:
		if !selectedUnits.has(unit):
			selectionAdd(unit)

# removing one unit from selected array
func removeOneUnit(unitToRemove: Node3D) -> void:
	var index: int = 0
	for unit in selectedUnits:
		if unit == unitToRemove:
			selectedUnits.remove_at(index)
			unitToRemove.selected = false
			break
		index += 1

# removing multiple units from array
func removeMultipleUnits(unitsToRemove: Array) -> void:
	var index = 0
	for unit in selectedUnits:
		for unitToRemove in unitsToRemove:
			if unit == unitToRemove:
				selectedUnits.remove_at(index)
				unit.selected = false
				break
		index += 1

# deselect all units
func deselectAllUnits() -> void:
	for unit in selectedUnits:
		if is_instance_valid(unit):
			unit.selected = false
	selectedUnits.clear()

# select / unselect one unit
func toggleSelectUnit(unit: Node3D) -> void:
	if unit.selected:
		removeOneUnit(unit)
	else:
		selectionAdd(unit)

# detecting mouse left btn clicked
func _input(event: InputEvent) -> void:
	var shift: bool = Input.is_action_pressed("shift")
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			drag_start = get_global_mouse_position()
			is_dragging = false
		else:
			if is_dragging:
				selectionDragBox(shift)
			else:
				singleSelection(get_global_mouse_position(), shift)
			is_dragging = false
			queue_redraw()
	
	if event is InputEventMouseMotion and Input.is_action_pressed("mouse_leftclick"):
		if get_global_mouse_position().distance_to(drag_start) > drag_threshold:
			is_dragging = true
			queue_redraw()
	
	if Input.is_action_just_released("mouse_rightclick"):
		if !selectedUnits.is_empty():
			var mouse_pos: Vector2 = get_viewport().get_mouse_position()
			var camera: Camera3D = get_viewport().get_camera_3d()
			var cameraRaycastCords: Vector3 = MODULE_CAMERA.getVerctor3FromCameraRaycast(camera, mouse_pos)
			
			if cameraRaycastCords != Vector3.ZERO:
				for unit in selectedUnits:
					if unit.has_method("moveUnit"):
						unit.moveUnit(cameraRaycastCords)

# dragbox selection
func selectionDragBox(shiftEnabled: bool = false) ->void:
	if !shiftEnabled: deselectAllUnits()
	
	selectUnits()

func singleSelection(mouse2Dpos: Vector2, shift: bool) -> void:
	var camera = get_viewport().get_camera_3d()
	
	for unit in visibleUnitsInArea.values():
		var unit2Dpos: Vector2 = camera.unproject_position((unit as Node3D).transform.origin + Vector3(0, 0.85, 0))
		
		if mouse2Dpos.distance_to(unit2Dpos) < 30:
			if shift:
				toggleSelectUnit(unit)
			else:
				deselectAllUnits()
				selectionAdd(unit)
			return
	
	if !shift:
		deselectAllUnits()

# drawing selection box
func _draw() -> void:
	if !is_dragging: return
	
	var drag_end = get_global_mouse_position()
	var rect = Rect2(drag_start, drag_end - drag_start)
	
	draw_rect(rect, Color(0.49, 0.81, 1.0, 0.15))
	draw_rect(rect, Color(0.49, 0.81, 1.0, 0.9), false, 1.5)
