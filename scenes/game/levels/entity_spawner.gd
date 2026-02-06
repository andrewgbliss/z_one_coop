class_name EntitySpawner
extends Node2D

@onready var navigation_region: NavigationRegion2D = _get_navigation_region_child()

@export var entity_name: String = "octorok"
@export var entity_blue_name: String = "octorok_blue"
@export_range(0.0, 1.0) var entity_blue_chance: float = 0.2 ## Probability of spawning blue instead of regular
@export var spawn_radius: float = 256.0 ## Only spawn within this radius of the player
@export var spawn_interval: float = 3.0 ## Seconds between spawn attempts
@export var spawn_margin: float = 32.0 ## Minimum distance from nav polygon edges
@export var viewport_margin: float = 32.0 ## Spawn at least this far outside visible viewport (so they don't magically appear)
@export var dont_spawn_on_tiles: Array[TileMapLayer] = [] ## TileMapLayers to treat as blocked; spawn position is skipped if inside any tile
@export var player_group: StringName = &"player"

var _spawn_timer: float = 0.0
var _walkable_polygons: Array[PackedVector2Array] = []
var finished = false

func _get_navigation_region_child() -> NavigationRegion2D:
	for child in get_children():
		if child is NavigationRegion2D:
			return child as NavigationRegion2D
	push_error("EntitySpawner: no NavigationRegion2D child found")
	return null


func _ready() -> void:
	if navigation_region == null:
		return
	var nav_poly := navigation_region.navigation_polygon
	if nav_poly == null:
		return
	_build_walkable_polygons(nav_poly)


func _build_walkable_polygons(nav_poly: NavigationPolygon) -> void:
	_walkable_polygons.clear()
	var verts := nav_poly.vertices
	for poly_indices in nav_poly.polygons:
		var points: PackedVector2Array = []
		for idx in poly_indices:
			if idx < verts.size():
				points.append(verts[idx])
		if points.size() >= 3:
			_walkable_polygons.append(points)


func _process(delta: float) -> void:
	if finished:
		return
	if _walkable_polygons.is_empty():
		return
	var player := _get_player()
	if player == null:
		return
	var player_local := navigation_region.to_local(player.global_position)
	if not _is_point_in_nav_region(player_local):
		return
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = spawn_interval
		_try_spawn_near_player(player_local)


func _get_player() -> Node2D:
	var nodes := get_tree().get_nodes_in_group(player_group)
	for node in nodes:
		if node is Node2D:
			return node as Node2D
	return null


func _is_point_in_nav_region(local_point: Vector2) -> bool:
	for poly in _walkable_polygons:
		if Geometry2D.is_point_in_polygon(local_point, poly):
			return true
	return false


func _is_position_on_forbidden_tile(global_pos: Vector2) -> bool:
	for layer in dont_spawn_on_tiles:
		if layer == null:
			continue
		var local_pos: Vector2 = layer.to_local(global_pos)
		var cell := layer.local_to_map(local_pos)
		if layer.get_cell_tile_data(cell) != null:
			return true
	return false


func _get_visible_world_rect() -> Rect2:
	var viewport := get_viewport()
	var visible_rect := viewport.get_visible_rect()
	var world_rect: Rect2 = viewport.get_canvas_transform().affine_inverse() * visible_rect
	world_rect = world_rect.grow(viewport_margin)
	return world_rect


func _is_outside_viewport(global_pos: Vector2) -> bool:
	return not _get_visible_world_rect().has_point(global_pos)


func _try_spawn_near_player(player_local: Vector2) -> void:
	var parent := get_parent()
	const max_attempts := 30
	for _attempt in max_attempts:
		var angle := randf() * TAU
		var dist := randf_range(spawn_margin, spawn_radius)
		var offset := Vector2.from_angle(angle) * dist
		var local_pos := player_local + offset
		if not _is_point_in_nav_region(local_pos):
			continue
		var global_pos := navigation_region.global_transform * local_pos
		if _is_position_on_forbidden_tile(global_pos):
			continue
		if not _is_outside_viewport(global_pos):
			continue
		var name_to_spawn := entity_name
		if entity_blue_name != "" and randf() < entity_blue_chance:
			name_to_spawn = entity_blue_name
		SpawnManager.spawn(name_to_spawn, global_pos, parent)
		if spawn_interval == 0.0:
			finished = true
		return
