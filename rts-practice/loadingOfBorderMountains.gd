@tool
extends Node3D

@export var tile_mesh: Mesh
@export var map_size: Vector2 = Vector2(144, 144)
@export var base_scale: float = 1.5
@export var rows: int = 2 
@export var height_gain: float = 1.0
@export var gap_from_map: float = 2.0
@export_range(0.3, 1.0) var overlap: float = 0.7
@export var ground_y: float = 0.0
@export var sink: float = 0.5
@export_range(0.0, 0.5) var scale_variation: float = 0.25
@export var seed_value: int = 12345
@export_tool_button("Rebuild") var rebuild_button = build
@export var chunk_size: float = 36.0

var _chunks: Array[MultiMeshInstance3D] = []

func _ready() -> void:
	build()

func build() -> void:
	if not is_inside_tree():
		return
	for c in _chunks:
		if is_instance_valid(c):
			c.queue_free()
	_chunks.clear()
	if tile_mesh == null:
		return
	
	var aabb: AABB = tile_mesh.get_aabb()
	var footprint: float = maxf(aabb.size.x, aabb.size.z) * base_scale
	var step: float = footprint * overlap
	var center_offset := Vector3(
		-(aabb.position.x + aabb.size.x * 0.5), 0.0,
		-(aabb.position.z + aabb.size.z * 0.5))
	
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	
	var points: Array[Vector3] = []
	for r in rows:
		var d: float = gap_from_map + footprint * 0.5 + r * step
		var x0: float = -d
		var x1: float = map_size.x + d
		var z0: float = -d
		var z1: float = map_size.y + d
		
		var count_x: int = ceili((x1 - x0) / step)
		for i in count_x + 1:
			var x: float = lerpf(x0, x1, float(i) / count_x)
			points.append(Vector3(x, 0.0, z0))
			points.append(Vector3(x, 0.0, z1))
		
		var count_z: int = ceili((z1 - z0) / step)
		for i in range(1, count_z):
			var z: float = lerpf(z0, z1, float(i) / count_z)
			points.append(Vector3(x0, 0.0, z))
			points.append(Vector3(x1, 0.0, z))
	
	var groups: Dictionary = {}   # Vector2i -> Array[Transform3D]
	for i in points.size():
		var p: Vector3 = points[i]
		var angle: float = rng.randi_range(0, 3) * PI * 0.5
		var s: float = base_scale * (1.0 + rng.randf_range(-scale_variation, scale_variation))
		var out_dist: float = maxf(maxf(-p.x, p.x - map_size.x), maxf(-p.z, p.z - map_size.y))
		var t: float = clampf((out_dist - gap_from_map) / maxf(step * rows, 0.001), 0.0, 1.0)
		var sy: float = s * rng.randf_range(0.9, 1.3) * (1.0 + height_gain * t)
		var basis: Basis = Basis(Vector3.UP, angle) * Basis.from_scale(Vector3(s, sy, s))
		var jitter := Vector3(
			rng.randf_range(-0.2, 0.2) * step, 0.0,
			rng.randf_range(-0.2, 0.2) * step)
		var origin: Vector3 = p + jitter + Vector3(0.0, ground_y - sink, 0.0) + basis * center_offset
		
		var key := Vector2i(floori(p.x / chunk_size), floori(p.z / chunk_size))
		if not groups.has(key):
			groups[key] = []
		groups[key].append(Transform3D(basis, origin))
	
	for key in groups.keys():
		var list: Array = groups[key]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = tile_mesh
		mm.instance_count = list.size()
		for i in list.size():
			mm.set_instance_transform(i, list[i])
		
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mmi)
		_chunks.append(mmi)
	
	var tris: int = int(tile_mesh.get_faces().size() / 3.0)
	print("border: ", points.size(), " instances in ", _chunks.size(), " chunks, ", tris, " tris each")
