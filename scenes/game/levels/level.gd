class_name Level extends Node2D

@export var camera: Camera2D
@export var phantom_camera: PhantomCamera2D
@export var camera_target: NodePath
@export var hud: Hud
@export var show_hud: bool = true
@export var zoom: Vector2 = Vector2(2.0, 2.0)
@export var follow: bool = true
@export var build_level: MazeBuilder
@export var cave_shop: CaveShop
@export var build_dungeon: MazeDungeonBuilder

var last_camera_area: NodePath
var active_dungeon_index: int = 0
## PhantomCamera is not updating correctly after dungeon warp; drive Camera2D here until we leave (must run after PhantomCameraHost priority 300).
var _dungeon_direct_camera_follow: bool = false
## Blocks re-teleport spam (e.g. door Area2D) which was firing [signal dungeon_entered] repeatedly and baking nav every time.
var _dungeon_teleport_lock_until_msec: int = 0

var player_one: CharacterController
var player_two: CharacterController

var players: Array[CharacterController] = []
var spawn_enemies: bool = false

signal loaded
## Fired after the player warps into a dungeon and dungeon camera limits are applied (good for spawning).
signal dungeon_entered(dungeon_index: int)

func _ready() -> void:
	call_deferred("_after_ready")

func _after_ready():
	players = []
	if GameManager.game_state != GameManager.GAME_STATE.GAME_PLAY:
		GameManager.set_state(GameManager.GAME_STATE.GAME_PLAY)
		_spawn_players(true)
	elif GameManager.game_state == GameManager.GAME_STATE.GAME_PLAY:
		_spawn_players(false)
	spawn_enemies = true

func _on_player_level_changed(new_level: int) -> void:
	if not build_level:
		return
	print("Level._on_player_level_changed: new_level=", new_level)
	SpawnManager.free_group("enemy")
	build_level.level = new_level
	build_level.enable_area(new_level, true)

func _pick_random_spawn_point_in_first_layer(rng: RandomNumberGenerator, first_start_tile: Vector2i) -> Vector2:
	# Spawn relative to the shop template placed on the entry layer (layer index `1`).
	# If the shop record isn't available, fall back to the original "inside entrance block" logic.
	if not build_level:
		return Vector2.ZERO

	var entry_layer_index := 1
	var shop_layer_index := build_level.last_shop_layer_index
	if shop_layer_index >= 0 and shop_layer_index < build_level.tile_map_layers.size():
		var shop_layer := build_level.tile_map_layers[shop_layer_index]
		if shop_layer and shop_layer.tile_set:
			if build_level.last_shop_top_left_tile_in_layer.x >= 0:
				var shop_tile_size: Vector2 = shop_layer.tile_set.tile_size
				var shop_top_left := build_level.last_shop_top_left_tile_in_layer
				var shop_size := build_level.last_shop_size_in_tiles

				var bottom_mid := build_level.last_shop_bottom_mid_tile_in_layer
				var spawn_tile_x: int
				var spawn_tile_y: int
				if bottom_mid.x >= 0 and bottom_mid.y >= 0:
					# Bottom-middle column of the placed shop template.
					spawn_tile_x = bottom_mid.x
					# Bottom-middle row (exactly on the bottom-most template tile row).
					spawn_tile_y = bottom_mid.y
				else:
					# Fallback: center of the template's bounding box.
					spawn_tile_x = shop_top_left.x + int(floor(shop_size.x / 2.0))
					# Fallback: bottom-most template tile row.
					spawn_tile_y = shop_top_left.y + shop_size.y - 1

				# Clamp inside the layer tile bounds.
				var max_tile_x := build_level.grid_size.x * build_level.cell_size - 1
				var max_tile_y := build_level.grid_size.y * build_level.cell_size - 1
				spawn_tile_x = clamp(spawn_tile_x, 0, max_tile_x)
				spawn_tile_y = clamp(spawn_tile_y, 0, max_tile_y)

				# Try a couple nearby tiles (including above/below) to avoid spawning on walls.
				var wall_source_id: int = build_level.last_wall_source_id
				var chosen: bool = false

				# First try the exact bottom-middle-under tile position.
				var base_sid: int = shop_layer.get_cell_source_id(Vector2i(spawn_tile_x, spawn_tile_y))
				if wall_source_id == -1:
					if base_sid != -1:
						chosen = true
				else:
					if base_sid != -1 and base_sid != wall_source_id:
						chosen = true

				for _i in range(8):
					if chosen:
						break
					var cand_x: int = clamp(spawn_tile_x + rng.randi_range(-1, 1), 0, max_tile_x)
					var cand_y: int = int(clamp(
						spawn_tile_y + rng.randi_range(-1, 1),
						0,
						max_tile_y
					))

					if wall_source_id == -1:
						spawn_tile_x = cand_x
						spawn_tile_y = cand_y
						chosen = true
						break

					var sid: int = shop_layer.get_cell_source_id(Vector2i(cand_x, cand_y))
					if sid != -1 and sid != wall_source_id:
						spawn_tile_x = cand_x
						spawn_tile_y = cand_y
						chosen = true
						break

				if not chosen:
					# Keep the initially computed tile (still clamped).
					pass

				var shop_local_spawn := shop_layer.map_to_local(Vector2i(spawn_tile_x, spawn_tile_y)) + (shop_tile_size / 2.0)
				var shop_global_spawn := shop_layer.to_global(shop_local_spawn)
				return to_local(shop_global_spawn)

	# Fallback: `MazeBuilder.generate_maze()` returns the entrance start tile in tile-map
	# coordinates for layer index 1 (the first layer the player actually enters).
	if first_start_tile.x < 0 or first_start_tile.y < 0:
		return Vector2.ZERO
	if build_level.tile_map_layers.size() < 2:
		return Vector2.ZERO

	var layer := build_level.tile_map_layers[entry_layer_index]
	if not layer or not layer.tile_set:
		return Vector2.ZERO

	var tile_size: Vector2 = layer.tile_set.tile_size
	var cell_size_tiles: int = build_level.cell_size
	if cell_size_tiles <= 0:
		cell_size_tiles = 1

	var rx := rng.randi_range(0, cell_size_tiles - 1)
	var ry := rng.randi_range(0, cell_size_tiles - 1)
	var spawn_tile := first_start_tile + Vector2i(rx, ry)

	# Spawn at the center of the chosen tile, in this TileMapLayer's local space.
	var local_spawn := layer.map_to_local(spawn_tile) + (tile_size / 2.0)
	var global_spawn := layer.to_global(local_spawn)
	return to_local(global_spawn)

func _spawn_at_blackboard_spawn(player: CharacterController) -> void:
	if not player or not player.blackboard:
		return
	player.spawn(player.blackboard.last_spawn_point)
		
func _spawn_players(reset_player = false):
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Time.get_ticks_msec()) ^ randi()

	var first_start_tile: Vector2i = Vector2i(-1, -1)
	var player_one_pos := Vector2.ZERO
	var player_two_pos := Vector2.ZERO

	# Only regenerate/select a new entry spawn when doing a full level reset.
	if reset_player and build_level:
		first_start_tile = build_level.generate_maze()
		player_one_pos = _pick_random_spawn_point_in_first_layer(rng, first_start_tile)
		player_two_pos = _pick_random_spawn_point_in_first_layer(rng, first_start_tile)

	# Spawn immediately (CharacterController.spawn is called by SpawnManager),
	# then we override position after blackboard restore if needed.
	player_one = SpawnManager.spawn("link", player_one_pos, self )
	player_one.died.connect(_on_player_died)
	if player_one and player_one.blackboard:
		player_one.blackboard.level_changed.connect(_on_player_level_changed)
		# Ensure navigation uses the player's current level immediately.
		_on_player_level_changed(player_one.blackboard.level)
	if reset_player:
		if player_one.blackboard:
			player_one.blackboard.last_spawn_point = player_one_pos
			player_one.blackboard.full_reset()
	else:
		if player_one.blackboard:
			player_one.blackboard.restore()
			_spawn_at_blackboard_spawn(player_one)
	if hud:
		hud.setup_player_ui(player_one)
	player_one.controls.set_device_index(0)
	players.append(player_one)
	
	if GameManager.how_many_players == 2 or GameManager.how_many_players == 3:
		player_two = SpawnManager.spawn("link", player_two_pos, self )
		player_two.died.connect(_on_player_died)
		if player_two and player_two.blackboard:
			player_two.blackboard.level_changed.connect(_on_player_level_changed)
		if reset_player:
			if player_two.blackboard:
				player_two.blackboard.last_spawn_point = player_two_pos
				player_two.blackboard.full_reset()
		else:
			if player_two.blackboard:
				player_two.blackboard.restore()
				_spawn_at_blackboard_spawn(player_two)
		if hud:
			hud.setup_player_ui(player_two)
		if GameManager.how_many_players == 3:
			player_two.controls.set_device_index(0)
		else:
			player_two.controls.set_device_index(1)
		players.append(player_two)
	call_deferred("_set_camera")
	
	if show_hud:
		hud.show_hud()
		
	call_deferred("_loaded")
	
func _loaded():
	loaded.emit()
	
func _set_camera():
	if follow:
		if players.size() == 1:
			phantom_camera.follow_mode = PhantomCamera2D.FollowMode.FRAMED
			phantom_camera.follow_target = players[0]
			phantom_camera.dead_zone_width = 0.15
			phantom_camera.dead_zone_height = 0.15
			phantom_camera.zoom = zoom
		elif players.size() == 2:
			phantom_camera.follow_mode = PhantomCamera2D.FollowMode.GROUP
			phantom_camera.follow_targets = [players[0], players[1]]
			phantom_camera.follow_target = null
		phantom_camera.teleport_position()
	camera.make_current()

func change_camera_area(area: Area2D):
	var shape: Node = area.get_child(0)
	if shape:
		phantom_camera.limit_target = phantom_camera.get_path_to(shape)
	_set_camera()

func _on_player_died(pos: Vector2):
	var temp: Array[CharacterController] = []
	for player in players:
		if player.is_alive:
			temp.append(player)
	players = temp
	_set_camera()
	if players.size() == 0:
		hud.show_game_over(pos)

func _set_cave_shop_camera():
	var col: Node = cave_shop.camera_area.get_node("CollisionShape2D")
	phantom_camera.limit_target = phantom_camera.get_path_to(col)

func teleport_to_cave(pos: Vector2):
	spawn_enemies = false
	player_one.blackboard.last_spawn_point = pos
	player_one.global_position = cave_shop.door_one.global_position + Vector2(0, -32)
	if player_two:
		player_two.blackboard.last_spawn_point = pos
		player_two.global_position = cave_shop.door_two.global_position + Vector2(0, -32)
	last_camera_area = phantom_camera.limit_target
	_set_cave_shop_camera()

func teleport_back_to_pos():
	_dungeon_teleport_lock_until_msec = 0
	_dungeon_direct_camera_follow = false
	process_physics_priority = 0
	spawn_enemies = true
	player_one.global_position = player_one.blackboard.last_spawn_point + Vector2(0, 16)
	if player_two:
		player_two.global_position = player_two.blackboard.last_spawn_point + Vector2(0, 16)
	if last_camera_area:
		phantom_camera.limit_target = last_camera_area
	_set_camera()

func teleport_to_dungeon(pos: Vector2, dungeon_index: int = -1):
	if not build_dungeon:
		return
	var now: int = Time.get_ticks_msec()
	if now < _dungeon_teleport_lock_until_msec:
		return
	_dungeon_teleport_lock_until_msec = now + 500
	spawn_enemies = false
	var idx: int = dungeon_index
	if idx < 0 and player_one and player_one.blackboard:
		idx = player_one.blackboard.level
	var max_i: int = maxi(0, build_dungeon.get_dungeon_layer_count() - 1)
	active_dungeon_index = clampi(idx, 0, max_i)
	player_one.blackboard.last_spawn_point = pos
	var spawns: Array = build_dungeon.get_entrance_spawn_global_positions(active_dungeon_index)
	if spawns.size() >= 1:
		player_one.global_position = spawns[0]
	if player_two:
		player_two.blackboard.last_spawn_point = pos
		if spawns.size() >= 2:
			player_two.global_position = spawns[1]
		elif spawns.size() >= 1:
			player_two.global_position = spawns[0]
	last_camera_area = phantom_camera.limit_target
	# Must not add Area2D / change collision during body_entered (physics query flush).
	call_deferred("_dungeon_teleport_finish_deferred")

func _dungeon_teleport_finish_deferred() -> void:
	if build_dungeon:
		var limit_col: CollisionShape2D = build_dungeon.get_dungeon_camera_collision_shape(active_dungeon_index)
		if limit_col:
			phantom_camera.limit_target = phantom_camera.get_path_to(limit_col)
	if follow and not players.is_empty() and is_instance_valid(camera):
		if is_instance_valid(phantom_camera):
			phantom_camera.update_limit_all_sides()
		_dungeon_direct_camera_follow = true
		process_physics_priority = 400
		_apply_dungeon_camera_to_players()
		if is_instance_valid(camera):
			camera.make_current()
	# One synchronous bake per warp (shared by all dungeon spawners). Avoids each listener rebaking + async pile-ups.
	if build_dungeon and build_dungeon.navigation_region:
		build_dungeon.navigation_region.bake_navigation_polygon()
	dungeon_entered.emit(active_dungeon_index)

func _apply_dungeon_camera_to_players() -> void:
	if not is_instance_valid(camera) or players.is_empty():
		return
	var target: Vector2
	if players.size() == 1:
		target = players[0].global_position
	else:
		target = (players[0].global_position + players[1].global_position) * 0.5
	camera.zoom = zoom
	if camera.limit_enabled:
		var half_ext: Vector2 = get_viewport().get_visible_rect().size / (zoom * 2.0)
		var lx: float = camera.limit_left + half_ext.x
		var rx: float = camera.limit_right - half_ext.x
		var ty: float = camera.limit_top + half_ext.y
		var by: float = camera.limit_bottom - half_ext.y
		if lx <= rx and ty <= by:
			target.x = clampf(target.x, lx, rx)
			target.y = clampf(target.y, ty, by)
	camera.global_position = target
	if is_instance_valid(phantom_camera):
		phantom_camera.global_position = target

func _physics_process(_delta: float) -> void:
	if not _dungeon_direct_camera_follow or not follow or players.is_empty():
		return
	if not is_instance_valid(camera):
		return
	_apply_dungeon_camera_to_players()
