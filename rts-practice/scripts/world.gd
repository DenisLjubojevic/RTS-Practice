extends Node3D

var world_size: Vector2i = Vector2i(71.2, 71.2) # IN meters / pixels

@onready var FOW: Control = $FogOfWarTexture
@onready var worldmap_mesh: MeshInstance3D = $fowMesh
@onready var unit: CharacterBody3D = $Units/testUnit

var dissolve_sprite: Texture2D = preload("res://image/fow_circle.png")

func _ready() -> void:
	FOW.new_fog_of_war(Rect2(Vector2.ZERO, world_size))
	
	for unit in get_tree().get_nodes_in_group("Units"):
		add_to_fow(unit)
		var vision_area: Area3D = unit.get_node("VisionArea3D")
		vision_area.body_entered.connect(
			func(body: Node3D) -> void:
				var dynamic_object = body.get_parent()
				if dynamic_object and dynamic_object.has_method("show"):
					dynamic_object.show()
		)
	
	FOW.fow_updated.connect(
		func() -> void:
			(worldmap_mesh.get_material_override() as ShaderMaterial).set_shader_parameter(
				"source_texture_fow", FOW.fog_of_war_viewport_texture
			)
	)
	
	for dynamic_object in $dynamic_objects.get_children():
		dynamic_object.hide()

func is_position_visible_in_fow(world_pos: Vector3) -> bool:
	if FOW.fog_of_war_main_image == null: return false
	var pixel_x = clamp(int(world_pos.x), 0, FOW.fog_of_war_main_image.get_width() - 1)
	var pixel_y = clamp(int(world_pos.z), 0, FOW.fog_of_war_main_image.get_height() - 1)
	return FOW.fog_of_war_main_image.get_pixel(pixel_x, pixel_y).r > 0.4

func add_to_fow(fow_node: Node3D, vision_size: int = 32) -> void:
	var new_sprite: Sprite2D = Sprite2D.new()
	new_sprite.set_texture(get_new_dissolve_image_texture(vision_size))
	FOW.fog_of_war_units.add_child(new_sprite)
	
	FOW.fog_of_war_units_data[fow_node.get_instance_id()] = [fow_node, new_sprite]

func get_new_dissolve_image_texture(size: int) -> ImageTexture:
	var dissolve_image: Image = (dissolve_sprite.get_image() as Image)
	dissolve_image.resize(size, size)
	return ImageTexture.create_from_image(dissolve_image)
