class_name EntitySpawner extends Node2D

@export var entity_name: String = "octorok"
@export var entity_blue_name: String = "octorok_blue"
@export_range(0.0, 1.0) var entity_blue_chance: float = 0.2 ## Probability of spawning blue instead of regular
@export var spawn_interval: float = 3.0 ## Seconds between spawn attempts
@export var spawn_limit: int = 0 ## Max spawns; 0 means unlimited.
@export var navigation_region: NavigationRegion2D
@export var group_name: String = "enemy"

var _spawn_timer: Timer
var finished = false
var level
var spawned_count: int = 0

func _ready() -> void:
	level = get_tree().root.get_node("Overworld")
	level.loaded.connect(_on_level_loaded)
	
	_spawn_timer = Timer.new()
	_spawn_timer.name = "SpawnTimer"
	_spawn_timer.one_shot = false
	_spawn_timer.autostart = false
	_spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(_spawn_timer)
	
func _on_level_loaded():
	if finished:
		return

	_spawn_timer.wait_time = spawn_interval

	# For a 0 interval, preserve the previous "spawn once" behavior.
	if spawn_interval == 0.0:
		_spawn_once()
		finished = true
		_spawn_timer.stop()
		return

	_spawn_timer.start()

func _on_spawn_timer_timeout() -> void:
	if finished:
		return
	_spawn_once()

func _spawn_once() -> void:
	if finished or not level.spawn_enemies:
		return

	if not navigation_region or navigation_region.process_mode == PROCESS_MODE_DISABLED:
		return

	if spawn_limit > 0 and spawned_count >= spawn_limit:
		finished = true
		if _spawn_timer != null:
			_spawn_timer.stop()
		return

	var pos := _pick_point_on_camera_edge()

	# If the chosen point accidentally lands inside the camera,
	# skip this tick and try again on the next timer.
	var cam_rect := _get_camera_world_rect()
	if cam_rect.has_point(pos):
		return
	var snapped_pos := _snap_to_navigation(pos)
	# Snap to a 16x16 grid so spawned entities align to the world tiles.
	# (Assumes tile/grid origin is aligned to world origin.)
	snapped_pos = snapped_pos.snapped(Vector2(16.0, 16.0))

	# Only spawn if the *final* (grid-snapped) position is still on/near the nav.
	# Quantizing can move us off the nav mesh slightly, so re-check after snapping.
	const NAV_CONTAIN_TOLERANCE := 8.0
	var closest_for_grid := _snap_to_navigation(snapped_pos)
	if closest_for_grid.distance_to(snapped_pos) > NAV_CONTAIN_TOLERANCE:
		return

	var name_to_spawn := entity_name
	if entity_blue_name != "" and randf() < entity_blue_chance:
		name_to_spawn = entity_blue_name

	var entity = SpawnManager.spawn(name_to_spawn, snapped_pos, level, group_name)
	if entity:
		spawned_count += 1

func _pick_point_on_camera_edge() -> Vector2:
	var rect := _get_camera_world_rect()
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return global_position

	# Pick one random edge, then a random position along that edge.
	# Spawn slightly outside the camera bounds, then we snap to navigation.
	const OUTSIDE_OFFSET := 16.0
	var side := randi() % 4
	match side:
		0: # left
			return Vector2(rect.position.x - OUTSIDE_OFFSET, randf_range(rect.position.y, rect.end.y))
		1: # right
			return Vector2(rect.end.x + OUTSIDE_OFFSET, randf_range(rect.position.y, rect.end.y))
		2: # top
			return Vector2(randf_range(rect.position.x, rect.end.x), rect.position.y - OUTSIDE_OFFSET)
		_: # bottom
			return Vector2(randf_range(rect.position.x, rect.end.x), rect.end.y + OUTSIDE_OFFSET)

func _get_camera_world_rect() -> Rect2:
	# Use the viewport's currently visible rect (driven by the active camera),
	# then convert it into world coordinates.
	return _get_visible_world_rect()

func _get_visible_world_rect() -> Rect2:
	# Fallback: approximate world bounds based on current viewport.
	var viewport := get_viewport()
	var visible_rect := viewport.get_visible_rect()
	var world_rect: Rect2 = viewport.get_canvas_transform().affine_inverse() * visible_rect
	return world_rect

func _snap_to_navigation(global_pos: Vector2) -> Vector2:
	if navigation_region == null:
		return global_pos

	# Prefer snapping via NavigationServer (works off the nav map/RID).
	var map_rid: RID
	if navigation_region.has_method("get_navigation_map"):
		map_rid = navigation_region.get_navigation_map()

	if map_rid.is_valid() and ClassDB.class_has_method("NavigationServer2D", "map_get_closest_point"):
		return NavigationServer2D.map_get_closest_point(map_rid, global_pos)

	# Fallback: snap to the nav polygon (local space).
	var poly := navigation_region.navigation_polygon
	if poly == null:
		return global_pos
	if not poly.has_method("get_closest_point"):
		return global_pos

	var local_pos := navigation_region.to_local(global_pos)
	var closest_local := poly.get_closest_point(local_pos) as Vector2
	return navigation_region.to_global(closest_local)
