class_name EntitySpawner
extends Node2D

@onready var navigation_region: NavigationRegion2D = _get_navigation_region_child()

@export var spawn_count: int = 100
@export var entity_name: String = "octorok"
@export var spawn_margin: float = 32.0


func _get_navigation_region_child() -> NavigationRegion2D:
	for child in get_children():
		if child is NavigationRegion2D:
			return child as NavigationRegion2D
	push_error("EntitySpawner: no NavigationRegion2D child found")
	return null


func _ready() -> void:
	call_deferred("spawn")


func spawn() -> void:
	if navigation_region == null:
		return
	var nav_poly := navigation_region.navigation_polygon
	if nav_poly == null or nav_poly.outlines.is_empty():
		return
	var outline: PackedVector2Array = nav_poly.outlines[0]
	var region_rect := _get_polygon_rect(outline)
	var parent := get_parent()
	const max_attempts := 50
	var min_x := region_rect.position.x + spawn_margin
	var max_x := region_rect.end.x - spawn_margin
	var min_y := region_rect.position.y + spawn_margin
	var max_y := region_rect.end.y - spawn_margin
	if min_x >= max_x:
		min_x = region_rect.position.x
		max_x = region_rect.end.x
	if min_y >= max_y:
		min_y = region_rect.position.y
		max_y = region_rect.end.y
	for i in spawn_count:
		var local_pos: Vector2
		var attempts := 0
		while attempts < max_attempts:
			local_pos = Vector2(randf_range(min_x, max_x), randf_range(min_y, max_y))
			if Geometry2D.is_point_in_polygon(local_pos, outline):
				break
			attempts += 1
		if attempts >= max_attempts:
			continue
		var global_pos := navigation_region.global_transform * local_pos
		SpawnManager.spawn(entity_name, global_pos, parent)


func _get_polygon_rect(polygon: PackedVector2Array) -> Rect2:
	if polygon.is_empty():
		return Rect2()
	var min_p := polygon[0]
	var max_p := polygon[0]
	for i in range(1, polygon.size()):
		min_p = min_p.min(polygon[i])
		max_p = max_p.max(polygon[i])
	return Rect2(min_p, max_p - min_p)
