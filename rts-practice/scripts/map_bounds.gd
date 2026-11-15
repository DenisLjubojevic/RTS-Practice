extends Node3D

@export var map_size: Vector2 = Vector2(144, 144)
@export var wall_height: float = 8.0
@export var thickness: float = 2.0
@export var inset: float = 0.0

func _ready() -> void:
	var w: float = map_size.x
	var d: float = map_size.y
	var t: float = thickness
	var h: float = wall_height
	
	var walls: Array = [
		[Vector3(w * 0.5, h * 0.5, -t * 0.5 + inset), Vector3(w + t * 2.0, h, t)],
		[Vector3(w * 0.5, h * 0.5, d + t * 0.5 - inset), Vector3(w + t * 2.0, h, t)],
		[Vector3(-t * 0.5 + inset, h * 0.5, d * 0.5), Vector3(t, h, d)],
		[Vector3(w + t * 0.5 - inset, h * 0.5, d * 0.5), Vector3(t, h, d)],
	]
	
	for wall in walls:
		var body := StaticBody3D.new()
		body.collision_layer = 1 << 6
		body.collision_mask = 0
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = wall[1]
		shape.shape = box
		body.add_child(shape)
		body.position = wall[0]
		add_child(body)
