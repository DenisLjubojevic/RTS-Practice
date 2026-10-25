extends Control

signal fow_updated

@onready var fog_of_war_timer: Timer = $Timer

var fog_of_war_main_image: Image
var fog_of_war_current_image: Image
var fog_of_war_main_texture: ImageTexture
var fog_of_war_current_texture: ImageTexture

var fog_of_war_units_data: Dictionary = {}  # { id: [node, circle_image] }
var map_rect: Rect2

func _ready() -> void:
	fog_of_war_timer.timeout.connect(fog_of_war_thick_loop)
	fog_of_war_timer.start()

func new_fog_of_war(new_map_rect: Rect2) -> void:
	map_rect = new_map_rect
	var size: Vector2i = Vector2i(map_rect.size)
	
	fog_of_war_main_image = Image.create(size.x,size.y, false, Image.FORMAT_RGBA8)
	fog_of_war_main_image.fill(Color(0, 0, 0, 1))
	fog_of_war_current_image = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	fog_of_war_current_image.fill(Color(0, 0, 0, 1))
	
	fog_of_war_main_texture = ImageTexture.create_from_image(fog_of_war_main_image)
	fog_of_war_current_texture = ImageTexture.create_from_image(fog_of_war_current_image)

func fog_of_war_thick_loop() -> void:
	if fog_of_war_main_image == null:
		fog_of_war_timer.start()
		return
	
	fog_of_war_current_image.fill(Color(0, 0, 0, 1))
	for unit_id in fog_of_war_units_data.keys():
		var data: Array = fog_of_war_units_data[unit_id]
		var node = data[0]
		if not is_instance_valid(node):
			fog_of_war_units_data.erase(unit_id)
			continue
		
		var circle: Image = data[1]
		var center: Vector2i = Vector2i(int(node.global_position.x), int(node.global_position.z))
		var top_left: Vector2i = center - circle.get_size() / 2
		
		fog_of_war_main_image.blend_rect(circle, circle.get_used_rect(), top_left)
		fog_of_war_current_image.blend_rect(circle, circle.get_used_rect(), top_left)
	
	fog_of_war_main_texture.update(fog_of_war_main_image)
	fog_of_war_current_texture.update(fog_of_war_current_image)
	emit_signal("fow_updated")
	fog_of_war_timer.start()
