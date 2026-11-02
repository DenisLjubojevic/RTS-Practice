extends Node3D

var world_size: Vector2i = Vector2i(144, 144)

@onready var FOW: Control = $FogOfWarTexture

const FOG_SHADER: Shader = preload("res://shaders/fow_terrain.gdshader")
@onready var terrain: GridMap = $NavigationRegion3D/GridMap
var fog_material: ShaderMaterial

var dissolve_sprite: Texture2D = preload("res://image/fow_circle.png")
var dim_overlay: StandardMaterial3D
var remembered: Dictionary = {}

func _ready() -> void:
	dim_overlay = StandardMaterial3D.new()
	dim_overlay.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dim_overlay.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dim_overlay.albedo_color = Color(0, 0, 0, 0.8)
	
	FOW.new_fog_of_war(Rect2(Vector2.ZERO, world_size))
	
	fog_material = ShaderMaterial.new()
	fog_material.shader = FOG_SHADER
	fog_material.set_shader_parameter("memory_texture", FOW.fog_of_war_main_texture)
	fog_material.set_shader_parameter("visible_texture", FOW.fog_of_war_current_texture)
	fog_material.set_shader_parameter("map_size", Vector2(world_size))
	fog_material.set_shader_parameter("explored_brightness", 0.4)
	apply_fog_to_terrain()
	
	for unit in get_tree().get_nodes_in_group("Units"):
		register_unit(unit)
	
	for existing_building in get_tree().get_nodes_in_group("Buildings"):
		add_to_fow(existing_building, 64)
	
	for obj in get_tree().get_nodes_in_group("Discoverable"):
		obj.hide()
	
	FOW.fow_updated.connect(reveal_discovered)
	
	for dynamic_object in $dynamic_objects.get_children():
		dynamic_object.hide()

func apply_fog_to_terrain() -> void:
	var library: MeshLibrary = terrain.mesh_library
	for id in library.get_item_list():
		var mesh: Mesh = library.get_item_mesh(id)
		if mesh == null:
			continue
		for s in mesh.get_surface_count():
			var mat: Material = mesh.surface_get_material(s)
			if mat == null:
				push_warning("tile %d surface %d has no material, fog not applied" % [id, s])
				continue
			mat.next_pass = fog_material

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
			remembered[obj] = false
	
	for obj in remembered:
		if not is_instance_valid(obj):
			remembered.erase(obj)
			continue
		var dim: bool = not is_position_visible_now(obj.global_position)
		if remembered[obj] == dim:
			continue
		remembered[obj] = dim
		for mesh in obj.find_children("*", "MeshInstance3D", true, false):
			(mesh as MeshInstance3D).material_overlay = dim_overlay if dim else null
