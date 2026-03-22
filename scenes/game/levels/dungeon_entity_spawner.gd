class_name DungeonEntitySpawner extends Node2D

@export var entity_name: String = "octorok"
@export var entity_blue_name: String = "octorok_blue"
@export_range(0.0, 1.0) var entity_blue_chance: float = 0.2
@export var spawn_count: int = 8
@export var navigation_region: NavigationRegion2D
@export var group_name: String = "enemy"
## If negative, spawns whenever any dungeon is entered; otherwise only for this index.
@export var dungeon_index: int = -1
@export var bounds_inner_margin: float = 32.0
@export var nav_snap_tolerance: float = 96.0

var level: Level
var spawned_count: int = 0
var _pending_dungeon_index: int = 0

func _ready() -> void:
	level = get_tree().root.get_node("Overworld") as Level
	if level:
		level.dungeon_entered.connect(_on_dungeon_entered)


func _on_dungeon_entered(entered_index: int) -> void:
	if not level or not level.build_dungeon:
		return
	if dungeon_index >= 0 and entered_index != dungeon_index:
		return
	spawned_count = 0
	_pending_dungeon_index = entered_index
	# Run after this frame so camera limits / transforms match the dungeon instance.
	call_deferred("_spawn_batch")


func _spawn_batch() -> void:
	if spawn_count <= 0:
		return
	if not navigation_region or navigation_region.process_mode == PROCESS_MODE_DISABLED:
		return
	if not level.build_dungeon:
		return

	const MAX_TRIES_PER_SPAWN := 64
	var spawned := 0
	while spawned < spawn_count:
		var placed := false
		for _t in MAX_TRIES_PER_SPAWN:
			if _try_spawn_one():
				placed = true
				break
		if not placed:
			break
		spawned += 1


func _try_spawn_one() -> bool:
	var bounds: Rect2 = level.build_dungeon.get_dungeon_bounds_global_rect(_pending_dungeon_index)
	var p: Vector2
	if bounds.size.x > 8.0 and bounds.size.y > 8.0:
		var m: float = bounds_inner_margin
		var inner := Rect2(bounds.position + Vector2(m, m), bounds.size - Vector2(m * 2.0, m * 2.0))
		if inner.size.x < 16.0 or inner.size.y < 16.0:
			inner = bounds
		p = Vector2(
			randf_range(inner.position.x, inner.end.x),
			randf_range(inner.position.y, inner.end.y)
		)
	else:
		p = _pick_point_on_camera_edge()
		var cam_rect := _get_camera_world_rect()
		if cam_rect.has_point(p):
			return false

	var snapped_pos := _snap_to_navigation(p)
	if snapped_pos.distance_to(p) > nav_snap_tolerance:
		return false
	snapped_pos = snapped_pos.snapped(Vector2(16.0, 16.0))
	if _snap_to_navigation(snapped_pos).distance_to(snapped_pos) > nav_snap_tolerance:
		return false

	var name_to_spawn := entity_name
	if entity_blue_name != "" and randf() < entity_blue_chance:
		name_to_spawn = entity_blue_name

	var pos_in_level: Vector2 = level.to_local(snapped_pos)
	var entity = SpawnManager.spawn(name_to_spawn, pos_in_level, level, group_name)
	if entity:
		spawned_count += 1
		return true
	return false


func _pick_point_on_camera_edge() -> Vector2:
	var rect := _get_camera_world_rect()
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return global_position
	const OUTSIDE_OFFSET := 16.0
	var side := randi() % 4
	match side:
		0:
			return Vector2(rect.position.x - OUTSIDE_OFFSET, randf_range(rect.position.y, rect.end.y))
		1:
			return Vector2(rect.end.x + OUTSIDE_OFFSET, randf_range(rect.position.y, rect.end.y))
		2:
			return Vector2(randf_range(rect.position.x, rect.end.x), rect.position.y - OUTSIDE_OFFSET)
		_:
			return Vector2(randf_range(rect.position.x, rect.end.x), rect.end.y + OUTSIDE_OFFSET)


func _get_camera_world_rect() -> Rect2:
	var viewport := get_viewport()
	var visible_rect := viewport.get_visible_rect()
	return viewport.get_canvas_transform().affine_inverse() * visible_rect


func _snap_to_navigation(global_pos: Vector2) -> Vector2:
	if navigation_region == null:
		return global_pos
	var map_rid: RID
	if navigation_region.has_method("get_navigation_map"):
		map_rid = navigation_region.get_navigation_map()
	if map_rid.is_valid() and ClassDB.class_has_method("NavigationServer2D", "map_get_closest_point"):
		return NavigationServer2D.map_get_closest_point(map_rid, global_pos)
	var poly := navigation_region.navigation_polygon
	if poly == null:
		return global_pos
	if not poly.has_method("get_closest_point"):
		return global_pos
	var local_pos := navigation_region.to_local(global_pos)
	var closest_local := poly.get_closest_point(local_pos) as Vector2
	return navigation_region.to_global(closest_local)
