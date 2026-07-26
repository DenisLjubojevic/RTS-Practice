extends Node2D

const MODULE_CAMERA: GDScript = preload("res://scripts/moduleCamera.gd")

# Nodes
@onready var player_camera: Node3D = $camera_base
@onready var player_camera_visibleunits_Area3D: Area3D = $camera_base/visible_units_ares3D
@onready var nodeBuildingPlacer: Node3D = $buildingPlacement
@onready var buildingPlacmentButton: Button = $NinePatchRect/Background/ActionPanel/placeBuildingButton
@onready var buildingPanel: PanelContainer = $NinePatchRect/Background/ActionPanel/BuildingPanel
@onready var buildingLabel: Label = $NinePatchRect/Background/ActionPanel/BuildingPanel/VBoxContainer/BuildingLabel
@onready var trainUnitButton: TextureButton = $NinePatchRect/Background/ActionPanel/BuildingPanel/VBoxContainer/TrainUnitButton
@onready var buildGrid: GridContainer = $NinePatchRect/Background/ActionPanel/buildGrid
@onready var trainProgressBar: ProgressBar = $NinePatchRect/Background/ActionPanel/BuildingPanel/VBoxContainer/TrainUnitButton/ProgressBar
@onready var visibleUnitsInArea: Dictionary =  {}
@onready var constructionBarsLayer: Control = $NinePatchRect/ConstructionBarsLayer

# Variables
var selectedUnits: Array = []
var selectedBuilding: Node3D = null
var _selected_building_scene_path: String = "res://scenes/TurtleHQ.tscn"
var construction_sites: Dictionary = {}

# Dragging
var drag_start: Vector2 = Vector2.ZERO
var is_dragging: bool = false
var drag_threshold: float = 5.0

signal building_selected(building: Node3D)
signal building_deselected


var _interface_input_mode: int:
	set(newValue):
		_interface_input_mode = newValue
		
		if _interface_input_mode == 1:
			buildingPlacmentButton.show()
			nodeBuildingPlacer.enableArea()
		else:
			nodeBuildingPlacer.hide()
			nodeBuildingPlacer.disableArea()

var _building_placer_can_place: bool = false
var _building_placer_location: Vector3 = Vector3.ZERO

func _ready() -> void:
	_interface_input_mode = 0
	initalizeInterface() 
	
	buildingPanel.hide()
	building_selected.connect(_on_building_selected)
	building_deselected.connect(_on_building_deselected)
	
	trainUnitButton.pressed.connect(_on_train_unit_pressed)
	trainUnitButton.texture_normal = load("res://image/icons/icon_unit_turtle.png")
	trainProgressBar.hide()
	
	buildGrid.hide()
	buildingPlacmentButton.pressed.connect(_on_build_button_pressed)
	populate_build_menu()

func populate_build_menu() -> void:
	var buildings_data: Dictionary = Globals.data["buildings"]
	for building_id in buildings_data.keys():
		var info: Dictionary = buildings_data[building_id]
		var btn := TextureButton.new()
		btn.texture_normal = load(info["ICON"])
		btn.custom_minimum_size = Vector2(48, 48)
		btn.pressed.connect(_on_building_option_pressed.bind(info["SCENE"]))
		buildGrid.add_child(btn)

func _on_build_button_pressed() -> void:
	buildGrid.visible = not buildGrid.visible

func _on_building_option_pressed(scene_path: String) -> void:
	_selected_building_scene_path = scene_path
	buildGrid.hide()
	_interface_input_mode = 1

func _on_building_selected(building: Node3D) -> void:
	if building.has_method("get") and "building_type" in building:
		buildingLabel.text = building.building_type
	else:
		buildingLabel.text = "Not recognized building"
	buildingPanel.show()

func update_selection_ui() -> void:
	var has_builder: bool = false
	for unit in selectedUnits:
		if unit is BuilderUnit:
			has_builder = true
			break
	buildingPlacmentButton.visible = has_builder
	buildingPanel.visible = false

func _on_building_deselected() -> void:
	buildingPanel.hide()

func _on_train_unit_pressed() -> void:
	if selectedBuilding and selectedBuilding.has_method("train_unit"):
		selectedBuilding.train_unit()

func _process(_delta: float) -> void:
	var camera: Camera3D = get_viewport().get_camera_3d()
	var to_remove: Array = []
	
	for building in construction_sites.keys():
		if not is_instance_valid(building):
			to_remove.append(building)
			continue
		var bar: ProgressBar = construction_sites[building]
		var progress: float = building.get_construction_progress()
		
		if progress < 0.0:
			construction_sites[building].queue_free()
			to_remove.append(building)
			continue
		
		bar.value = progress
		var screen_pos: Vector2 = camera.unproject_position(building.global_position + Vector3(0, building.get_bar_height_offset(), 0))
		bar.position = screen_pos - bar.custom_minimum_size * 0.5
	
	for building in to_remove:
		construction_sites.erase(building)
	
	if selectedBuilding and selectedBuilding.has_method("get_train_progress"):
		var progress: float = selectedBuilding.get_train_progress()
		if progress >= 0.0:
			trainProgressBar.show()
			trainProgressBar.value = progress
		else:
			trainProgressBar.hide()

func _physics_process(delta: float) -> void:
	if _interface_input_mode == 1:
		var mouse_pos: Vector2 = get_global_mouse_position()
		var camera: Camera3D = get_viewport().get_camera_3d()
		
		var ray_from: Vector3 = camera.project_ray_origin(mouse_pos)
		var ray_to: Vector3 = ray_from + camera.project_ray_normal(mouse_pos) * 1000.0
		var ray_param:  PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(ray_from, ray_to)
		ray_param.collision_mask = 0b10
		
		var raycasted_result: Variant = camera.get_world_3d().get_direct_space_state().intersect_ray(ray_param)
		if raycasted_result:
			if nodeBuildingPlacer.transform.origin != raycasted_result.position:
				nodeBuildingPlacer.transform.origin = raycasted_result.position
				nodeBuildingPlacer.show()
				
				var world = get_parent() as Node3D
				var is_fow_visible: bool = world.is_position_visible_in_fow(raycasted_result.position)
				
				if nodeBuildingPlacer.placementCheck(visibleUnitsInArea, is_fow_visible):
					_building_placer_location = raycasted_result.position
					_building_placer_can_place = true
				else:
					_building_placer_can_place = false
					_building_placer_location = Vector3.ZERO
	else:
		_building_placer_can_place = false
		_building_placer_location = Vector3.ZERO

# detects when unit has entered visible area
func unitEnterVisibleArea(unit: Node3D) -> void:
	if not unit is CharacterBody3D: return
	
	var unitId: int = unit.get_instance_id()
	
	if visibleUnitsInArea.keys().has(unitId): return
	visibleUnitsInArea[unitId] = unit

# detects when unit has exited visible area
func unitExitVisibleArea(unit: Node3D) -> void:
	if not unit is CharacterBody3D: return
	
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
	update_selection_ui()

func selectMultipleUnits(unitsToSelect: Array) -> void:
	for unit in unitsToSelect:
		if !selectedUnits.has(unit):
			selectionAdd(unit)
	update_selection_ui()

# removing one unit from selected array
func removeOneUnit(unitToRemove: Node3D) -> void:
	var index: int = 0
	for unit in selectedUnits:
		if unit == unitToRemove:
			selectedUnits.remove_at(index)
			unitToRemove.selected = false
			break
		index += 1
	update_selection_ui()

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
	update_selection_ui()

# deselect all units
func deselectAllUnits() -> void:
	for unit in selectedUnits:
		if is_instance_valid(unit):
			unit.selected = false
	selectedUnits.clear()
	update_selection_ui()

# select / unselect one unit
func toggleSelectUnit(unit: Node3D) -> void:
	if unit.selected:
		removeOneUnit(unit)
	else:
		selectionAdd(unit)

# detecting mouse left btn clicked
func _unhandled_input(event: InputEvent) -> void:
	var shift: bool = Input.is_action_pressed("shift")
	
	if event is InputEventKey and event.pressed:
		if _interface_input_mode == 1:
			_interface_input_mode = 0
			get_viewport().set_input_as_handled()
		return
	
	if _interface_input_mode == 1:
		if Input.is_action_just_pressed("mouse_leftclick"):
			if _building_placer_can_place and _building_placer_location != Vector3.ZERO:
				var building_packed_scene: PackedScene = load("res://scenes/TurtleHQ.tscn")
				var buildingNode: Node3D = building_packed_scene.instantiate()
				get_parent().add_child(buildingNode, true)
				buildingNode.transform.origin = _building_placer_location
				buildingNode.building_type = "TurtleHQ"
				
				var world: Node3D = get_parent() as Node3D
				world.add_to_fow(buildingNode, 64)	
				
				for builder in selectedUnits:
					if builder is BuilderUnit:
						buildingNode.builders_assigned.append(builder)
						builder.assign_to_build(buildingNode)
						register_construction_site(buildingNode)
				
				if !shift:
					_interface_input_mode = 0
	else:
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
				
				var ray_from: Vector3 = camera.project_ray_origin(mouse_pos)
				var ray_to: Vector3 = ray_from + camera.project_ray_normal(mouse_pos) * 1000
				var ray_param := PhysicsRayQueryParameters3D.create(ray_from, ray_to)
				ray_param.collision_mask = 0b100
				var building_result: Dictionary = camera.get_world_3d().get_direct_space_state().intersect_ray(ray_param)
				if building_result:
					var building: Node3D = building_result.collider.owner
					var assigned_any: bool = false
					if building is BaseBuilding and not building.is_constructed:
						for unit in selectedUnits:
							if unit is BuilderUnit:
								building.builders_assigned.append(unit)
								unit.assign_to_build(building)
								assigned_any = true
						if assigned_any and not construction_sites.has(building):
							register_construction_site(building)
					if assigned_any:
						return
				
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
	
	var ray_from:  Vector3 = camera.project_ray_origin(mouse2Dpos)
	var ray_to: Vector3 = ray_from + camera.project_ray_normal(mouse2Dpos) * 1000.0
	var ray_param := PhysicsRayQueryParameters3D.create(ray_from, ray_to)
	ray_param.collision_mask = 0b100
	var result: Dictionary = camera.get_world_3d().get_direct_space_state().intersect_ray(ray_param)
	
	if result:
		if !shift: deselectAllUnits()
		selectBuilding(result.collider.owner)
		return
	
	deselectBuilding()
	
	if !shift:
		deselectAllUnits()

func selectBuilding(building: Node3D) -> void:
	selectedBuilding = building
	building_selected.emit(building)

func deselectBuilding() -> void:
	if selectedBuilding:
		selectedBuilding = null
		building_deselected.emit()

# drawing selection box
func _draw() -> void:
	if !is_dragging: return
	
	var drag_end = get_global_mouse_position()
	var rect = Rect2(drag_start, drag_end - drag_start)
	
	draw_rect(rect, Color(0.49, 0.81, 1.0, 0.15))
	draw_rect(rect, Color(0.49, 0.81, 1.0, 0.9), false, 1.5)

func register_construction_site(building: Node3D) -> void:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(100, 10)
	bar.max_value = 1.0
	bar.show_percentage = false
	
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = Color(0.9, 0.7, 0.1)
	bar.add_theme_stylebox_override("fill", fill_style)

	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.1, 0.1, 0.6)
	bar.add_theme_stylebox_override("background", bg_style)
	
	constructionBarsLayer.add_child(bar)
	construction_sites[building] = bar
