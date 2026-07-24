extends Panel

@export var world_min: Vector2 = Vector2(-256, -256)
@export var world_max: Vector2 = Vector2(256, 256)

@onready var icons_container: Control = $MinimapIcons

var unit_icons: Dictionary = {}

func world_to_minimap(world_pos: Vector3) -> Vector2:
	var t := Vector2(
		remap(world_pos.x, world_min.x, world_max.x, 0.0, size.x),
		remap(world_pos.z, world_min.y, world_max.y, 0.0, size.y)
	)
	return t

func remap(value: float, in_min: float, in_max: float, out_min: float, out_max: float) -> float:
	return out_min + (value - in_min) / (in_max - in_min) * (out_max - out_min)

func registerUnit(unit: Node3D, color: Color = Color.CYAN):
	var icon := ColorRect.new()
	icon.color = color
	icon.size = Vector2(4, 4)
	icons_container.add_child(icon)
	unit_icons[unit] = icon

func unregister_unit(unit: Node3D):
	if unit_icons.has(unit):
		unit_icons[unit].queue_free()
		unit_icons.erase(unit)

func _process(_delta):
	for unit in unit_icons.keys():
		if not is_instance_valid(unit):
			unregister_unit(unit)
			continue
		var icon: ColorRect = unit_icons[unit]
		icon.position = world_to_minimap(unit.global_position) - icon.size / 2
