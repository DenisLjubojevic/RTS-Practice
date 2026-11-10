@tool
extends Node3D

@export var near_mesh: Mesh                  # detailed 64 version
@export var far_mesh: Mesh                   # low-res 32 version
@export var near_material: Material
@export var far_material: Material

@export var map_size: Vector2 = Vector2(144, 144)
@export var tile_world_size: float = 16.0    # width of one tile in world units
@export var rows: int = 3
@export var detailed_rows: int = 1           # innermost rows that use near_mesh
@export var gap_from_map: float = 2.0
@export var ground_y: float = 0.0
@export var sink: float = 0.5
@export_range(0.0, 0.5) var height_variation: float = 0.0   # 0 = all tiles the same height
@export var chunk_size: float = 36.0
@export var seed_value: int = 12345

@export var rebuild: bool = false:
	set(value):
		if value and is_inside_tree():
			build()
		rebuild = false

func _ready() -> void:
	build()

func build() -> void:
	if not is_inside_tree():
		return
	for c in get_children():
		if c is MultiMeshInstance3D:
			c.queue_free()
	if near_mesh == null and far_mesh == null:
		return
	
	var meshes: Array[Mesh] = [near_mesh, far_mesh]
	if near_mesh == null:
		meshes[0] = far_mesh
	if far_mesh == null:
		meshes[1] = near_mesh
	var materials: Array[Material] = [near_material, far_material]
	
	var norms: Array[float] = []
	var offsets: Array[Vector3] = []
	for m in meshes:
		var aabb: AABB = m.get_aabb()
		norms.append(tile_world_size / maxf(maxf(aabb.size.x, aabb.size.z), 0.001))
		offsets.append(Vector3(
			-(aabb.position.x + aabb.size.x * 0.5),
			-aabb.position.y,
			-(aabb.position.z + aabb.size.z * 0.5)))
	
	var cell: float = tile_world_size
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	
	var points: Array[Vector3] = []
	var point_rows: Array[int] = []
	var point_fit: Array[float] = []
	
	for r in rows:
		var d: float = gap_from_map + cell * (r + 0.5)
		var x0: float = -d
		var x1: float = map_size.x + d
		var z0: float = -d
		var z1: float = map_size.y + d
		
		var count_x: int = maxi(1, roundi((x1 - x0) / cell))
		var fit_x: float = clampf(((x1 - x0) / count_x) / cell, 0.9, 1.1)
		for i in count_x + 1:
			var x: float = lerpf(x0, x1, float(i) / count_x)
			points.append(Vector3(x, 0.0, z0))
			point_rows.append(r)
			point_fit.append(fit_x)
			points.append(Vector3(x, 0.0, z1))
			point_rows.append(r)
			point_fit.append(fit_x)
		
		var count_z: int = maxi(1, roundi((z1 - z0) / cell))
		var fit_z: float = clampf(((z1 - z0) / count_z) / cell, 0.9, 1.1)
		for i in range(1, count_z):
			var z: float = lerpf(z0, z1, float(i) / count_z)
			points.append(Vector3(x0, 0.0, z))
			point_rows.append(r)
			point_fit.append(fit_z)
			points.append(Vector3(x1, 0.0, z))
			point_rows.append(r)
			point_fit.append(fit_z)
	
	var groups: Dictionary = {}   # Vector3i(chunk_x, chunk_z, kind) -> Array of Transform3D
	for i in points.size():
		var p: Vector3 = points[i]
		var kind: int = 0 if point_rows[i] < detailed_rows else 1
		var angle: float = rng.randi_range(0, 3) * PI * 0.5
		var s: float = norms[kind] * point_fit[i]
		var sy: float = s * (1.0 + rng.randf_range(-height_variation, height_variation))
		var basis: Basis = Basis(Vector3.UP, angle) * Basis.from_scale(Vector3(s, sy, s))
		var origin: Vector3 = p + Vector3(0.0, ground_y - sink, 0.0) + basis * offsets[kind]
		
		var key := Vector3i(floori(p.x / chunk_size), floori(p.z / chunk_size), kind)
		if not groups.has(key):
			groups[key] = []
		groups[key].append(Transform3D(basis, origin))
	
	var counts: Array[int] = [0, 0]
	for key in groups.keys():
		var list: Array = groups[key]
		var kind: int = key.z
		counts[kind] += list.size()
		
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = meshes[kind]
		mm.instance_count = list.size()
		for i in list.size():
			mm.set_instance_transform(i, list[i])
		
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if materials[kind] != null:
			mmi.material_override = materials[kind]
		add_child(mmi)
	
	var tris_near: int = int(meshes[0].get_faces().size() / 3.0)
	var tris_far: int = int(meshes[1].get_faces().size() / 3.0)
	print("border: ", counts[0], " near + ", counts[1], " far = ",
		counts[0] * tris_near + counts[1] * tris_far, " triangles (before culling)")
