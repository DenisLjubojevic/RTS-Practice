extends Node3D

var world_size: Vector2i = Vector2i(142, 142) # IN meters / pixels

@onready var FOW: Control = $FogOfWarTexture
@onready var worldmap_mesh: MeshInstance3D = $fowMesh

var dissolve_sprite: Texture2D = preload("res://image/fow_circle.png")
var dim_overlay: StandardMaterial3D
var remembered: Array = []

func _ready() -> void:
	dim_overlay = StandardMaterial3D.new()
	dim_overlay.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dim_overlay.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dim_overlay.albedo_color = Color(0, 0, 0, 0.8)
	
	FOW.new_fog_of_war(Rect2(Vector2.ZERO, world_size))
	
	var fow_matterial: ShaderMaterial = worldmap_mesh.get_material_override() as ShaderMaterial
	fow_matterial.set_shader_parameter("memory_texture", FOW.fog_of_war_main_texture)
	fow_matterial.set_shader_parameter("visible_texture", FOW.fog_of_war_current_texture)
	
	for unit in get_tree().get_nodes_in_group("Units"):
		register_unit(unit)
	
	for existing_building in get_tree().get_nodes_in_group("Buildings"):
		add_to_fow(existing_building, 64)
	
	for obj in get_tree().get_nodes_in_group("Discoverable"):
		obj.hide()
	
	FOW.fow_updated.connect(reveal_discovered)
	
	for dynamic_object in $dynamic_objects.get_children():
		dynamic_object.hide()

func register_unit(unit: Node3D, vision_size: int = 32) -> void:
	add_to_fow(unit, vision_size)
	
	var vision_area: Area3D = unit.get_node("VisionArea3D")
	vision_area.body_entered.connect(
		func(body: Node3D) -> void:
			var dynamic_object = body.get_parent()
			if dynamic_object and dynamic_object.has_method("show"):
				dynamic_object.show()
	)

func add_to_fow(fow_node: Node3D, vision_size: int = 32) -> void:
	var circle: Image = dissolve_sprite.get_image()
	circle.convert(Image.FORMAT_RGBA8)
	circle.resize(vision_size, vision_size)
	FOW.fog_of_war_units_data[fow_node.get_instance_id()] = [fow_node, circle]

func _pixel_value(image: Image, world_pos: Vector3) -> float:
	if image == null: return 0.0
	
	var x: int = clampi(int(world_pos.x), 0, image.get_width() - 1)
	var y: int = clampi(int(world_pos.z), 0, image.get_height() - 1)
	return image.get_pixel(x, y).r

func is_position_visible_in_fow(world_pos: Vector3) -> bool:
	return _pixel_value(FOW.fog_of_war_main_image, world_pos) > 0.3

func is_position_visible_now(world_pos: Vector3) -> bool:
	return _pixel_value(FOW.fog_of_war_current_image, world_pos) > 0.3

func reveal_discovered() -> void:
	for obj in get_tree().get_nodes_in_group("Discoverable"):
		if is_position_visible_now(obj.global_position):
			obj.show()
			obj.remove_from_group("Discoverable")
			remembered.append(obj)
	
	remembered = remembered.filter(func(o): return is_instance_valid(o))
	
	for obj in remembered:
		var seen_now: bool = is_position_visible_now(obj.global_position)
		for mesh in obj.find_children("*", "MeshInstance3D", true, false):
			(mesh as MeshInstance3D).material_overlay = null if seen_now else dim_overlay 
