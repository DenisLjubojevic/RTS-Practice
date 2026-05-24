extends Node3D

@onready var unitData: Dictionary = {}

@onready var area: Area3D = $Area3D
@onready var areaCollisionShape: CollisionShape3D = $Area3D/CollisionShape3D
@onready var model: MeshInstance3D = $buildingPreview

# setting color of shader to green
func model_green() -> void:
	model.set("instance_shader_parameters/insatance_color_1", Color("26c93173"))

# setting color of shader to red
func model_red() -> void:
	model.set("instance_shader_parameters/insatance_color_1", Color("c9262673"))

func enableArea() -> void:
	areaCollisionShape.disabled = false

func disableArea() -> void:
	areaCollisionShape.disabled = true

func placementCheck(units: Dictionary, is_fow_visible: bool) -> bool:
	model_red()
	
	if area.has_overlapping_bodies():
		return false
	
	if not is_fow_visible:
		return false
	
	var areaColShape: BoxShape3D = areaCollisionShape.shape
	var areaSize: Vector3 = areaColShape.size * 0.5
	var buildingPos: Vector3 = areaCollisionShape.global_transform.origin
	
	for unit in units.values():
		if not is_instance_valid(unit): continue
		var unitPos: Vector3 = unit.global_position
		
		var dx: float = abs(unitPos.x - buildingPos.x)
		var dz: float = abs(unitPos.z - buildingPos.z)
		
		if dx < areaSize.x + 0.3 and dz < areaSize.z + 0.3:
			return false
	
	var pointToCheck: Array = [
		areaCollisionShape.global_transform.origin + Vector3(areaSize.x, -areaSize.y, areaSize.z),
		areaCollisionShape.global_transform.origin + Vector3(areaSize.x, -areaSize.y, -areaSize.z),
		areaCollisionShape.global_transform.origin + Vector3(-areaSize.x, -areaSize.y, -areaSize.z),
		areaCollisionShape.global_transform.origin + Vector3(-areaSize.x, -areaSize.y, areaSize.z)
	]
	
	var y_distances: Array = []
	
	var i: int = 0
	for point in pointToCheck:
		var ray_from: Vector3 = pointToCheck[i]
		var ray_to: Vector3 = ray_from + Vector3(0, -20.0, 0)
		var ray_param: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(ray_from, ray_to)
		ray_param.collision_mask = 0b10
		
		var raycasted_result: Variant = get_world_3d().get_direct_space_state().intersect_ray(ray_param)
		if raycasted_result:
			var y_distance: float = ray_from.y - raycasted_result.position.y
			y_distances.append(y_distance)
		else:
			return false
		i += 1
	
	for y_distance in y_distances:
		if y_distance > 1:
			return false
	
	model_green()
	return true
