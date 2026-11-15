extends Node3D

@export var map_size: Vector2 = Vector2(144, 144)
@export var thickness: float = 40.0
@export var height: float = 30.0
@export var wall_color: Color = Color(0.337, 0.051, 0.064, 1.0)

func _ready() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = wall_color
	
	var w: float = map_size.x
	var d: float = map_size.y
	var t: float = thickness
	var y: float = height * 0.5 - 2.0
	
	# [center, size]
	var walls: Array = [
		[Vector3(-t * 0.5, y, d * 0.5),         Vector3(t, height, d + t * 2.0)],
		[Vector3(w + t * 0.5, y, d * 0.5),      Vector3(t, height, d + t * 2.0)],
		[Vector3(w * 0.5, y, -t * 0.5),         Vector3(w, height, t)],
		[Vector3(w * 0.5, y, d + t * 0.5),      Vector3(w, height, t)],
	]
	
	for wall in walls:
		var mesh := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = wall[1]
		mesh.mesh = box
		mesh.material_override = mat
		mesh.position = wall[0]
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mesh)
