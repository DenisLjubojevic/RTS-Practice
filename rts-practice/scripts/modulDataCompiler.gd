extends RefCounted
# Modul data compiler
# -----------------------------------------------------------------------------
# Handle all our data building
# -----------------------------------------------------------------------------

const MODUL_CONSTANTS = preload("res://scripts/modulConstants.gd")
const MODUL_FILE_MANAGER = preload("res://scripts/modulFileManager.gd")

static func encodeDataToString(text: String) -> String:
	return Marshalls.utf8_to_base64(text)

static func decodeDataToString(text: String) -> String:
	return Marshalls.base64_to_utf8(text)

static func compileCSVDataFiles() -> void:
	for file in DirAccess.get_files_at(MODUL_CONSTANTS.PATH_FOLDER_DATA):
		if file.ends_with(MODUL_CONSTANTS.FORMAT_CSV):
			MODUL_FILE_MANAGER.encodeDataFile(MODUL_CONSTANTS.PATH_FOLDER_DATA + file)

static func buildDataDictionary(dictionary: Dictionary) -> void:
	var dictNames: Array = dictionary.keys()
	
	var i: int = 0
	for dict in dictNames:
		for file in DirAccess.get_files_at(MODUL_CONSTANTS.PATH_FOLDER_DATA):
			if file.count(dict) and file.ends_with(MODUL_CONSTANTS.FORMAT_DATA):
				var encodedData: String = MODUL_FILE_MANAGER.loadTextFile(MODUL_CONSTANTS.PATH_FOLDER_DATA + file)
				var decodedData: String = decodeDataToString(encodedData)
				var allCsvLines: PackedStringArray = decodedData.split("\r\n")
				dictionary[dictNames[i]] = dataParseCSV(allCsvLines)
		i += 1

static func dataParseCSV(allCSVLines: PackedStringArray) -> Dictionary:
	var storedCSVDictionary: Dictionary = {}
	if allCSVLines.size() > 1:
		var csvHeaderProcessed: bool = false
		var csvLineHeaders: Array = []
		for csvLine in allCSVLines:
			if !csvLine.is_empty():
				var firstCell: String = csvLine[0]
				if (!firstCell.begins_with("#") and 
					firstCell != ";" and
					firstCell != ""):
						#PROCESS HEADER
						var csvSplitedData: PackedStringArray = csvLine.split(";")
						if !csvHeaderProcessed:
							var i:int = 0
							for header in csvSplitedData:
								csvLineHeaders.append(str_to_var(csvSplitedData[i]))
								i += 1
							csvHeaderProcessed = true
						else: #PROCESS REST OF CSV
							var entityID = str_to_var(csvSplitedData[0])
							var csvInt = 0
							for csvData in csvSplitedData:
								if !storedCSVDictionary.keys().has(entityID):
									storedCSVDictionary[entityID] = {}
								storedCSVDictionary[entityID][csvLineHeaders[csvInt]] = str_to_var(csvData)
								csvInt += 1
	return storedCSVDictionary
