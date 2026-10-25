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

var resources: Dictionary = {"wood": 0, "food": 0, "stone": 0}

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
