extends Node

const MODULE_CONSTANTS = preload("res://scripts/moduleConstants.gd")
const MODULE_DATA_COMPILER = preload("res://scripts/moduleDataCompiler.gd")
const MODULE_FILE_MANAGER = preload("res://scripts/moduleFileManager.gd")

var data: Dictionary = {
	"gamedata": {}
}

func _ready() -> void:
	MODULE_DATA_COMPILER.compileCSVDataFiles()
	MODULE_DATA_COMPILER.buildDataDictionary(data)
	print(JSON.stringify(data, "\t"))
	print(data["gamedata"][1])
