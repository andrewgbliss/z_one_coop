class_name EntitySpawner extends Node2D

@export var entity_name: String = "octorok"
@export var entity_blue_name: String = "octorok_blue"
@export_range(0.0, 1.0) var entity_blue_chance: float = 0.2 ## Probability of spawning blue instead of regular
@export var spawn_radius: float = 256.0 ## Only spawn when a player is within this distance of the spawner
@export var spawn_interval: float = 3.0 ## Seconds between spawn attempts
@export var spawn_margin: float = 32.0 ## Minimum distance from spawn point
@export var viewport_margin: float = 32.0 ## Spawn at least this far outside visible viewport (so they don't magically appear)
@export var dont_spawn_on_tiles: Array[TileMapLayer] = [] ## TileMapLayers to treat as blocked; spawn position is skipped if inside any tile
@export var player_group: StringName = &"player"
@export var level: Level

var _spawn_timer: float = 0.0
var finished = false
var players = []

func _ready() -> void:
	level.loaded.connect(_on_level_loaded)
	
func _on_level_loaded():
	players = get_tree().get_nodes_in_group(player_group)

func _process(delta: float) -> void:
	if finished:
		return
	var player := _get_player_in_range()
	if player == null:
		return
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = spawn_interval
		_try_spawn_near_player(player.global_position)


func _get_player_in_range() -> Node2D:
	var spawner_pos := global_position
	for node in players:
		if node is Node2D:
			var player_pos := (node as Node2D).global_position
			if spawner_pos.distance_to(player_pos) <= spawn_radius:
				return node as Node2D
	return null


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


func _try_spawn_near_player(player_global: Vector2) -> void:
	var parent := get_parent()
	const max_attempts := 30
	for _attempt in max_attempts:
		var angle := randf() * TAU
		var dist := randf_range(spawn_margin, spawn_radius)
		var offset := Vector2.from_angle(angle) * dist
		var global_pos := player_global + offset
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
