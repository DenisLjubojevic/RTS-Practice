extends Node3D

@onready var selection_circle = $SelectionCircle

var selected: bool = false:
	set(value):
		selected = value
		selection_circle.visible = value

func _ready() -> void:
	selection_circle.visible = false
