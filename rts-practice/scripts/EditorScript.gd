@tool
extends EditorScript

const TILE_ID: int = 0             # your single grass tile
const SIZE: int = 180              # cells per side (144 / 0.8)
const MAX_LEVEL: int = 4           # highest hill, in layers above the ground
const HILL_START: float = 0.55     # noise above this becomes hill (higher = fewer hills)
const HILL_STEP: float = 0.08      # how much noise it takes to climb one level
const NOISE_FREQ: float = 0.025    # lower = wider hills
const SEED: int = 4242

# HQ locations, read from the scene (fix the names if yours differ)
const PLAYER_HQ_PATH: String = "Units/StartingTurtleHQ"
const ENEMY_HQ_PATH: String = "EnemyHq"
const FALLBACK_PLAYER: Vector2i = Vector2i(30, 30)     # used if a node isn't found
const FALLBACK_ENEMY: Vector2i = Vector2i(150, 150)

const FLAT_RADIUS: float = 15.0    # fully flat around each HQ, in cells (20 = 16 units)
const BLEND: float = 12.0          # distance over which hills fade back in
const EDGE_FLAT: float = 4.0       # flat strip along the map edge, in cells
const Y_ROTATIONS: Array[int] = [0, 10, 16, 22]

func _run() -> void:
	var root: Node = get_scene()
	var grid: GridMap = root.get_node("NavigationRegion3D/GridMap") as GridMap
	
	var centers: Array[Vector2i] = [
		_hq_cell(grid, root, PLAYER_HQ_PATH, FALLBACK_PLAYER),
		_hq_cell(grid, root, ENEMY_HQ_PATH, FALLBACK_ENEMY),
	]
	print("flat zones at cells: ", centers)
	
	var noise := FastNoiseLite.new()
	noise.seed = SEED
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = NOISE_FREQ
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	
	# 1. height per column
	var heights: Array = []
	for x in SIZE:
		var column: Array[int] = []
		for z in SIZE:
			var n: float = (noise.get_noise_2d(x, z) * 0.5 + 0.5) * _flat_mask(x, z, centers)
			var h: int = 0
			if n > HILL_START:
				h = clampi(1 + int((n - HILL_START) / HILL_STEP), 0, MAX_LEVEL)
			column.append(h)
		heights.append(column)
	
	# 2. make every slope climbable: neighbours differ by at most 1 level
	var offsets: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	var changed: bool = true
	var passes: int = 0
	while changed and passes < 30:
		changed = false
		passes += 1
		for x in SIZE:
			for z in SIZE:
				var h: int = heights[x][z]
				for o in offsets:
					var nx: int = x + o.x
					var nz: int = z + o.y
					if nx >= 0 and nx < SIZE and nz >= 0 and nz < SIZE:
						h = mini(h, heights[nx][nz] + 1)
				if h != heights[x][z]:
					heights[x][z] = h
					changed = true
	
	# 3. place cells: the top of every column, plus any side that is exposed
	grid.clear()
	var placed: int = 0
	for x in SIZE:
		for z in SIZE:
			var h: int = heights[x][z]
			var lowest: int = h
			for o in offsets:
				var nx: int = x + o.x
				var nz: int = z + o.y
				if nx >= 0 and nx < SIZE and nz >= 0 and nz < SIZE:
					lowest = mini(lowest, heights[nx][nz])
			for y in range(mini(lowest + 1, h), h + 1):
				var is_top: bool = (y == h)
				var orientation: int = Y_ROTATIONS[rng.randi() % 4] if is_top else 0
				grid.set_cell_item(Vector3i(x, y, z), TILE_ID, orientation)
				placed += 1
	print("terrain: ", placed, " cells, relaxed in ", passes, " passes")

func _hq_cell(grid: GridMap, root: Node, path: String, fallback: Vector2i) -> Vector2i:
	var node: Node3D = root.get_node_or_null(path) as Node3D
	if node == null:
		push_warning("HQ not found at '%s', using fallback %s" % [path, fallback])
		return fallback
	var cell: Vector3i = grid.local_to_map(grid.to_local(node.global_position))
	return Vector2i(cell.x, cell.z)

func _flat_mask(x: int, z: int, centers: Array[Vector2i]) -> float:
	var m: float = 1.0
	for c in centers:
		var d: float = Vector2(x, z).distance_to(Vector2(c))
		m = minf(m, smoothstep(FLAT_RADIUS, FLAT_RADIUS + BLEND, d))
	var edge: float = minf(minf(x, z), minf(SIZE - 1 - x, SIZE - 1 - z))
	return minf(m, smoothstep(EDGE_FLAT, EDGE_FLAT + 6.0, edge))
