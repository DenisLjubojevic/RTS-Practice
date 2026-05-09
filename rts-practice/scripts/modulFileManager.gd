extends RefCounted
# Modul file manager
# -----------------------------------------------------------------------------
# Handle file operations
# -----------------------------------------------------------------------------

const MODUL_CONSTANTS = preload("res://scripts/modulConstants.gd")
const MODUL_DATA_COMPILER = preload("res://scripts/modulDataCompiler.gd")

static func printFile(filepath: String) -> void:
	var text: String = FileAccess.open(filepath, FileAccess.READ).get_as_text()
	print("Contains: \n" + text)

static func printAllFilesInFolder(filepathFolder: String) -> void:
	for file in DirAccess.get_files_at(filepathFolder):
		print("Loading data: " + file)
		printFile(filepathFolder + file)

static func saveTextFile(filePath: String, text: String) -> void:
	var file: FileAccess = FileAccess.open(filePath, FileAccess.WRITE)
	file.store_string(text)
	file.close()

static func loadTextFile(filePath: String) -> String:
	var text :String = FileAccess.open(filePath, FileAccess.READ).get_as_text()
	return text

static func fileExists(filePath: String) -> bool:
	if FileAccess.file_exists(filePath): return true
	printerr("ModulFileManager: file does not exists! path: ", filePath)
	return false

static func encodeDataFile(filePath: String) -> void:
	if !fileExists(filePath): return
	
	var loadFileData: String = FileAccess.open(filePath, FileAccess.READ).get_as_text()
	var saveFilePath: String = filePath.replace(MODUL_CONSTANTS.FORMAT_CSV, MODUL_CONSTANTS.FORMAT_DATA)
	
	var encodedText: String = MODUL_DATA_COMPILER.encodeDataToString(loadFileData)
	saveTextFile(saveFilePath, encodedText)
