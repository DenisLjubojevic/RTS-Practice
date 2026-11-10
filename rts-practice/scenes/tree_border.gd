@tool
extends Node3D

@export var tree_mesh: Mesh
@export var tree_material: Material
@export var map_size: Vector2 = Vector2(144, 144)
@export var depth: float = 12.0
@export var spacing: float = 2.5
@export var edge_wobble: float = 4.0
@export var target_height: float = 4.0
@export var scale_min: float = 0.9
@export var scale_max: float = 1.3
@export var ground_y: float = 0.2
@export var sink: float = 0.1
@export var chunk_size: float = 36.0
@export var seed_value: int = 7

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
	if tree_mesh == null:
		push_warning("TreeBorder: assign the .obj to Tree Mesh")
		return
	
	var aabb: AABB = tree_mesh.get_aabb()
	print("tree mesh size: ", aabb.size)
	var norm: float = 1.0
	if target_height > 0.0 and aabb.size.y > 0.0:
		norm = target_height / aabb.size.y
	var pivot := Vector3(
		-(aabb.position.x + aabb.size.x * 0.5),
		-aabb.position.y,
		-(aabb.position.z + aabb.size.z * 0.5))
	
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var noise := FastNoiseLite.new()
	noise.seed = seed_value
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.06
	
	var groups: Dictionary = {}
	var total: int = 0
	var x: float = -depth
	while x <= map_size.x + depth:
		var z: float = -depth
		while z <= map_size.y + depth:
			var p := Vector2(
				x + rng.randf_range(-0.4, 0.4) * spacing,
				z + rng.randf_range(-0.4, 0.4) * spacing)
			z += spacing
			
			var out_dist: float = maxf(maxf(-p.x, p.x - map_size.x), maxf(-p.y, p.y - map_size.y))
			var inner: float = (noise.get_noise_2d(p.x, p.y) * 0.5 + 0.5) * edge_wobble
			if out_dist < inner or out_dist > depth:
				continue
			
			var s: float = norm * rng.randf_range(scale_min, scale_max)
			var b: Basis = Basis.from_scale(Vector3(s, s, s))
			var origin := Vector3(p.x, ground_y - sink, p.y) + b * pivot
			
			var key := Vector2i(floori(p.x / chunk_size), floori(p.y / chunk_size))
			if not groups.has(key):
				groups[key] = []
			groups[key].append(Transform3D(b, origin))
			total += 1
		x += spacing
	
	for key in groups.keys():
		var list: Array = groups[key]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = tree_mesh
		mm.instance_count = list.size()
		for i in list.size():
			mm.set_instance_transform(i, list[i])
		
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if tree_material != null:
			mmi.material_override = tree_material
		add_child(mmi)
	
	var tris: int = int(tree_mesh.get_faces().size() / 3.0)
	print("tree border: ", total, " trees x ", tris, " tris = ", total * tris)
