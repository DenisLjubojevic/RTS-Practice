extends RefCounted
# Modul file manager
# -----------------------------------------------------------------------------
# Handle file operations
# -----------------------------------------------------------------------------

static func PrintFile(filepath: String) -> void:
	var text: String = FileAccess.open(filepath, FileAccess.READ).get_as_text()
	print("Contains: \n" + text)

static func PrintAllFilesInFolder(filepathFolder: String) -> void:
	for file in DirAccess.get_files_at(filepathFolder):
		print("Loading data: " + file)
		PrintFile(filepathFolder + file)
