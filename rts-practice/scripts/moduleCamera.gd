extends RefCounted

# Holds camera operations

static func getVerctor3FromCameraRaycast(camera: Camera3D, camera2DCords: Vector2) -> Vector3:
	var rayFrom: Vector3 = camera.project_ray_origin(camera2DCords)
	var rayTo: Vector3 = rayFrom + camera.project_ray_normal(camera2DCords) * 1000.0
	var rayParameters: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(rayFrom, rayTo)
	
	var result: Dictionary = camera.get_world_3d().get_direct_space_state().intersect_ray(rayParameters)
	
	if result: return result.position
	else: return Vector3.ZERO
