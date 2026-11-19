extends Node

const MODULE_CONSTANTS = preload("res://scripts/moduleConstants.gd")
const MODULE_DATA_COMPILER = preload("res://scripts/moduleDataCompiler.gd")
const MODULE_FILE_MANAGER = preload("res://scripts/moduleFileManager.gd")

signal resource_changed(type: String, amount: int)

var data: Dictionary = {
	"gamedata": {},
	"buildings": {},
	"units": {}
}

var resources: Dictionary = {"wood": 0, "stone": 0, "food": 0}

func _ready() -> void:
	MODULE_DATA_COMPILER.compileCSVDataFiles()
	MODULE_DATA_COMPILER.buildDataDictionary(data)

func add_resource(type: String, amount: int) -> void:
	resources[type] += amount
	resource_changed.emit(type, resources[type])

func spend_resource(type: String, amount: int) -> bool:
	if resources[type] < amount:
		return false
	resources[type] -= amount
	resource_changed.emit(type, resources[type])
	return true

func spend_resources(cost: Dictionary) -> bool:
	if not can_afford(cost):
		return false
	for type in cost:
		if cost[type] > 0:
			spend_resource(type, cost[type])
	return true

func get_building_cost(info: Dictionary) -> Dictionary:
	var cost: Dictionary = {}
	for type in ["wood", "stone", "food"]:
		var value = info.get(type.to_upper(), 0)
		cost[type] = int(value) if value != null else 0
	return cost

func can_afford(cost: Dictionary) -> bool:
	for type in cost:
		if resources.get(type, 0) < cost[type]:
			return false
	return true
