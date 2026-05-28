extends Control

signal fow_updated

@onready var fog_of_war_camera: Camera2D = $SubViewportContainer/SubViewport/fowCamera
@onready var fog_of_war_viewport: SubViewport = $SubViewportContainer/SubViewport
@onready var fog_of_war_sprite: Sprite2D = $SubViewportContainer/SubViewport/fowTexture
@onready var fog_of_war_units: Node2D = $SubViewportContainer/SubViewport/fowUnits
@onready var fog_of_war_timer: Timer = $Timer

var fog_of_war_stored: Array
var fog_of_war_main_image: Image
var fog_of_war_current_image: Image
var fog_of_war_main_texture: ImageTexture
var fog_of_war_viewport_texture: ImageTexture

var fog_of_war_units_data: Dictionary = {}

var map_rect: Rect2

func _ready() -> void:
	fog_of_war_sprite.centered = false
	fog_of_war_timer.timeout.connect(fog_of_war_tick_loop)
	fog_of_war_timer.start()

func fog_of_war_tick_loop() -> void:
	fog_of_war_current_image.fill(Color(0.0, 0.0, 0.0, 1.0))
	
	fog_of_war_units_data_process()
	fog_of_war_dissolve_all_units()
	
	fog_of_war_viewport_texture = ImageTexture.create_from_image(
		fog_of_war_viewport.get_texture().get_image()
	)
	
	emit_signal("fow_updated")

func new_fog_of_war(new_map_rect: Rect2) -> void:
	map_rect = new_map_rect
	
	fog_of_war_viewport.size = map_rect.size
	(fog_of_war_viewport.get_parent() as SubViewportContainer).size = map_rect.size
	
	fog_of_war_camera.position = Vector2.ZERO + map_rect.size * 0.5
	
	fog_of_war_main_image = Image.create(
		int(map_rect.size.x),
		int(map_rect.size.y),
		false,Image.FORMAT_RGBA8
	)
	fog_of_war_main_image.fill(Color(0.0, 0.0, 0.0, 1.0))
	
	fog_of_war_current_image = Image.create(
		int(map_rect.size.x),
		int(map_rect.size.y),
		false, Image.FORMAT_RGBA8
	)
	fog_of_war_current_image.fill(Color(0.0, 0.0, 0.0, 1.0))
	
	update_texture()

func update_texture() -> void:
	fog_of_war_main_texture = ImageTexture.create_from_image(fog_of_war_main_image)
	fog_of_war_sprite.set_texture(fog_of_war_main_texture)

func fog_of_war_dissolve(dissolve_position: Vector2, dissolve_image: Image) -> void:
	var dissolve_image_used_rect: Rect2 = dissolve_image.get_used_rect()
	dissolve_position -= dissolve_image_used_rect.size * 0.50
	
	fog_of_war_main_image.blend_rect(dissolve_image, dissolve_image_used_rect, dissolve_position)
	
	fog_of_war_current_image.blend_rect(dissolve_image, dissolve_image_used_rect, dissolve_position)
	
	update_texture()

func fog_of_war_units_data_process() -> void:
	# { units_id: [node_tracking, sprite_node] }
	
	for unit_id in fog_of_war_units_data.keys():
		var unit_data: Array = (fog_of_war_units_data[unit_id] as Array)
		
		var world_pos = (unit_data[0] as Node3D).global_position
		
		var position_to_2D: Vector2 = Vector2(
			(unit_data[0] as Node3D).global_position.x,
			(unit_data[0] as Node3D).global_position.z
		)
		
		(unit_data[1] as Sprite2D).set_position(position_to_2D)

func fog_of_war_dissolve_all_units() -> void:
	for fow_sprite in fog_of_war_units.get_children():
		var fow_sprite_image: Image = (fow_sprite as Sprite2D).get_texture().get_image()
		var dissolve_position: Vector2 = (fow_sprite as Sprite2D).position
		
		fog_of_war_current_image.blend_rect(
			fow_sprite_image, 
			fow_sprite_image.get_used_rect(), 
			dissolve_position - fow_sprite_image.get_used_rect().size * 0.5
		)
		
		var sprite_stored_position_size: Vector3i = Vector3i(
			(fow_sprite as Sprite2D).position.x,
			(fow_sprite as Sprite2D).position.y,
			(fow_sprite as Sprite2D).get_texture().get_size().x
		)
		if !sprite_stored_position_size in fog_of_war_stored:
			fog_of_war_dissolve(dissolve_position, fow_sprite_image)
			fog_of_war_stored.append(sprite_stored_position_size)
