class_name ResourceNode
extends Node3D

@export var resource_type: String = "wood"
@export var amount: int = 100

@onready var shape_node: CollisionShape3D = $StaticBody3D/CollisionShape3D

func _ready() -> void:
	add_to_group("Resources")
	add_to_group("Discoverable")

func get_interaction_range() -> float:
	var shape: Shape3D = shape_node.shape
	if shape is BoxShape3D:
		var size: Vector3 = (shape as BoxShape3D).size
		return Vector2(size.x, size.z).length() * 0.5 + 0.3
	return 2.0

func take(request: int) -> int:
	var taken: int = mini(request, amount)
	amount -= taken
	if amount <= 0:
		queue_free()
	return taken
