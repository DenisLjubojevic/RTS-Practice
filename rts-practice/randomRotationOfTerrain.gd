@tool
extends EditorScript

const TILE_ID: int = 0   # set this to your grass tile's id in tile_library
const Y_ROTATIONS: Array[int] = [0, 10, 16, 22]

func _run() -> void:
	var grid: GridMap = get_scene().get_node("NavigationRegion3D/GridMap") as GridMap
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	var changed: int = 0
	for c in grid.get_used_cells():
		if grid.get_cell_item(c) != TILE_ID:
			continue
		grid.set_cell_item(c, TILE_ID, Y_ROTATIONS[rng.randi() % 4])
		changed += 1
	print("rotated ", changed, " cells")
