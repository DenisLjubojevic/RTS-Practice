@tool
extends Node3D

@export var tree_scene: PackedScene       # drag Tree.tscn here
@export var radius: float = 8.0
@export var count: int = 25
@export var min_spacing: float = 1.8
@export var scale_min: float = 0.95
@export var scale_max: float = 1.1
@export var seed_value: int = 1

@export var rebuild: bool = false:
	set(value):
		if value and is_inside_tree():
			build()
		rebuild = false

func build() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	if tree_scene == null:
		return
	
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var placed: Array[Vector2] = []
	var attempts: int = 0
	
	while placed.size() < count and attempts < count * 30:
		attempts += 1
		var angle: float = rng.randf() * TAU
		var r: float = radius * sqrt(rng.randf())
		var p := Vector2(cos(angle), sin(angle)) * r
		
		var too_close: bool = false
		for q in placed:
			if q.distance_to(p) < min_spacing:
				too_close = true
				break
		if too_close:
			continue
		placed.append(p)
		
		var tree := tree_scene.instantiate() as Node3D
		add_child(tree)
		if Engine.is_editor_hint():
			tree.owner = get_tree().edited_scene_root
		tree.position = Vector3(p.x, 0.0, p.y)
		tree.scale = Vector3.ONE * rng.randf_range(scale_min, scale_max)
