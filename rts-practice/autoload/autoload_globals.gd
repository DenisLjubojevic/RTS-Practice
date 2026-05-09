extends Node

const MODUL_CONSTANTS = preload("res://scripts/modulConstants.gd")
const MODUL_DATA_COMPILER = preload("res://scripts/modulDataCompiler.gd")
const MODUL_FILE_MANAGER = preload("res://scripts/modulFileManager.gd")

var data: Dictionary = {
	"gamedata": {}
}

func _ready() -> void:
	MODUL_DATA_COMPILER.compileCSVDataFiles()
	MODUL_DATA_COMPILER.buildDataDictionary(data)
	print(JSON.stringify(data, "\t"))
	print(data["gamedata"][1])
