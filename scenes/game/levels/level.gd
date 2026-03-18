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

var last_camera_area: NodePath

var player_one: CharacterController
var player_two: CharacterController

var players: Array[CharacterController] = []

signal loaded

func _ready() -> void:
	call_deferred("_after_ready")

func _after_ready():
	players = []
	if GameManager.game_state != GameManager.GAME_STATE.GAME_PLAY:
		GameManager.set_state(GameManager.GAME_STATE.GAME_PLAY)
		_spawn_players(true)
	elif GameManager.game_state == GameManager.GAME_STATE.GAME_PLAY:
		_spawn_players(false)

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
	phantom_camera.limit_target = area.get_child(0).get_path()
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
	phantom_camera.limit_target = cave_shop.camera_area.get_node("CollisionShape2D").get_path()

func teleport_to_cave(pos: Vector2):
	player_one.blackboard.last_spawn_point = pos
	player_one.global_position = cave_shop.door_one.global_position + Vector2(0, -32)
	if player_two:
		player_two.blackboard.last_spawn_point = pos
		player_two.global_position = cave_shop.door_two.global_position + Vector2(0, -32)
	last_camera_area = phantom_camera.limit_target
	_set_cave_shop_camera()

func teleport_back_to_pos():
	player_one.global_position = player_one.blackboard.last_spawn_point + Vector2(0, 16)
	if player_two:
		player_two.global_position = player_two.blackboard.last_spawn_point + Vector2(0, 16)
	if last_camera_area:
		phantom_camera.limit_target = last_camera_area
	_set_camera()
