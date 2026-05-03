extends Node

const MODUL_CONSTANTS = preload("res://scripts/modulConstants.gd")
const MODUL_FILE_MANAGER = preload("res://scripts/modulFileManager.gd")

func _ready() -> void:
	MODUL_FILE_MANAGER.PrintAllFilesInFolder(MODUL_CONSTANTS.PATH_FOLDER_DATA)
