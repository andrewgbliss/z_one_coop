@tool
class_name MazeDungeonBuilder extends Node2D

const _DIR_N := 0
const _DIR_E := 1
const _DIR_S := 2
const _DIR_W := 3
const _DIR_VEC: Array[Vector2i] = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]

## 16×11 tiles per room (indices 0..15, 0..10).
@export var width: int = 16
@export var height: int = 11
## Entrance / block / boss / triforce templates are shifted this many tiles right/down (base fills the full room).
@export var interior_tile_offset: Vector2i = Vector2i(2, 2)

## If set, each entry gets its own procedural dungeon packed along X in tile space. If empty, [output_tile_layer] is used.
@export var output_tile_layers: Array[TileMapLayerAdvanced] = []
@export var output_tile_layer: TileMapLayerAdvanced
## Baked once after all instances are painted (deferred so tile navigation geometry is committed).
@export var navigation_region: NavigationRegion2D
## Optional one region per output layer; when non-empty and same size as outputs, bake after each instance.
@export var navigation_regions: Array[NavigationRegion2D] = []
## Horizontal gap between dungeon instances, in tiles (along +X).
@export var dungeon_instance_gap_tiles: int = 8
## Pixels padded outside the painted tile bounds on each side for [DungeonCameraArea2D] / Phantom limits.
@export var dungeon_camera_margin_pixels: Vector2 = Vector2(48, 48)

@export var base_tile_layer: TileMapLayerAdvanced
@export var entrance_tile_layer: TileMapLayerAdvanced
@export var block_tile_layers: Array[TileMapLayerAdvanced] = []
## Entrance + maze rooms + boss + triforce. Maze room count is num_rooms - 3 (minimum 0 when num_rooms == 3).
@export_range(3, 512) var num_rooms: int = 8
@export var boss_tile_layer: TileMapLayerAdvanced
@export var triforce_tile_layer: TileMapLayerAdvanced

@export var left_wall_tile_layers: Array[TileMapLayerAdvanced] = []
@export var right_wall_tile_layers: Array[TileMapLayerAdvanced] = []
@export var up_wall_tile_layers: Array[TileMapLayerAdvanced] = []
@export var down_wall_tile_layers: Array[TileMapLayerAdvanced] = []
## Template layer for the entrance room's south edge (overworld exit). When set, used instead of [member down_wall_tile_layers] index 0 for room 0 only.
@export var entrance_door_tiles: TileMapLayerAdvanced

## Template anchors in room tile space (see authored wall/door strips).
@export var wall_up_start_index: Vector2i = Vector2i(6, 0)
@export var wall_down_start_index: Vector2i = Vector2i(6, 9)
@export var wall_left_start_index: Vector2i = Vector2i(0, 4)
@export var wall_right_start_index: Vector2i = Vector2i(14, 4)
## Retries if boss/triforce cannot be placed after a random maze core.
@export var placement_max_attempts: int = 2000

@export_tool_button("Generate Maze", "Callable")
var generate_maze_action = generate_maze

@export_tool_button("Clear Terrain", "Callable")
var clear_terrain_action = clear_generated


## Tile-space origin used for each output layer last [method generate_maze] (index = dungeon index).
var _instance_origins: Array[Vector2i] = []
## Tile-space AABB covering every room in that instance (for PhantomCamera limits). Empty [Rect2i] if unset.
var _dungeon_camera_tile_bounds: Array[Rect2i] = []
## Maze graph cell for the boss room per instance (same index as output layers). [Vector2i.ZERO] if generation failed or unset.
var _boss_room_maze_cells: Array[Vector2i] = []


func get_dungeon_layer_count() -> int:
	return _resolve_output_layers().size()


func get_entrance_spawn_global_positions(dungeon_index: int) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var layers: Array[TileMapLayerAdvanced] = _resolve_output_layers()
	if dungeon_index < 0 or dungeon_index >= layers.size():
		out.append(global_position)
		out.append(global_position)
		return out
	var layer: TileMapLayerAdvanced = layers[dungeon_index]
	if not layer or not layer.tile_set:
		out.append(global_position)
		out.append(global_position)
		return out
	_ensure_instance_origins_through(dungeon_index)
	var io: Vector2i = _instance_origins[dungeon_index]
	var south_tile := Vector2i(io.x + width / 2, io.y + height - 1)
	var tile_size: Vector2 = layer.tile_set.tile_size
	var base_local: Vector2 = layer.map_to_local(south_tile) + tile_size / 2.0
	var base_global: Vector2 = layer.to_global(base_local)
	var spread: float = tile_size.x * 1.5
	var up: Vector2 = Vector2(0, -32)
	out.append(base_global + Vector2(-spread, 0) + up)
	out.append(base_global + Vector2(spread, 0) + up)
	return out


## World position at the center of the boss room tiles for [param dungeon_index] (boss is always room index [code]num_rooms - 2[/code] in the layout).
## Without [method generate_maze], maze metadata is missing: infers boss room as one room west of painted triforce tiles on the output layer.
func get_boss_room_spawn_global_position(dungeon_index: int) -> Vector2:
	var resolved: Array[TileMapLayerAdvanced] = _resolve_output_layers()
	if dungeon_index < 0 or dungeon_index >= resolved.size():
		return global_position
	var layer: TileMapLayerAdvanced = resolved[dungeon_index]
	if not layer or not layer.tile_set:
		return global_position
	_ensure_instance_origins_through(dungeon_index)
	var io: Vector2i = _instance_origins[dungeon_index]
	var maze_cell: Vector2i = Vector2i.ZERO
	var have_cell: bool = dungeon_index < _boss_room_maze_cells.size()
	if have_cell:
		maze_cell = _boss_room_maze_cells[dungeon_index]
	if have_cell and maze_cell != Vector2i.ZERO:
		var room_tile_origin: Vector2i = _room_tile_origin(maze_cell, io)
		var tile_size: Vector2 = layer.tile_set.tile_size
		var room_top_left_local: Vector2 = layer.map_to_local(room_tile_origin)
		var room_size_px: Vector2 = Vector2(float(width) * tile_size.x, float(height) * tile_size.y)
		var local_center: Vector2 = room_top_left_local + room_size_px * 0.5
		return layer.to_global(local_center)
	var from_boss: Vector2 = _template_interior_centroid_global(layer, boss_tile_layer, dungeon_index, io)
	if is_finite(from_boss.x):
		return from_boss
	return _boss_spawn_global_from_triforce_on_layer(layer, dungeon_index, io)


## Axis-aligned world rect of the dungeon instance (from Phantom camera limit collision). Used for spawning inside the active dungeon.
func get_dungeon_bounds_global_rect(dungeon_index: int) -> Rect2:
	var col: CollisionShape2D = get_dungeon_camera_collision_shape(dungeon_index)
	if col == null or col.shape == null:
		return Rect2()
	var rs: RectangleShape2D = col.shape as RectangleShape2D
	if rs == null:
		return Rect2()
	var xf: Transform2D = col.global_transform
	var hs: Vector2 = rs.size * 0.5
	var corners: Array[Vector2] = [
		xf * Vector2(-hs.x, -hs.y),
		xf * Vector2(hs.x, -hs.y),
		xf * Vector2(-hs.x, hs.y),
		xf * Vector2(hs.x, hs.y),
	]
	var mn: Vector2 = corners[0]
	var mx: Vector2 = corners[0]
	for p in corners:
		mn = mn.min(p)
		mx = mx.max(p)
	return Rect2(mn, mx - mn)


func _dungeon_instance_tile_x_range(dungeon_index: int, io: Vector2i) -> Vector2i:
	var stride: int = _dungeon_stride_tiles()
	var min_tx: int = io.x
	var max_tx: int = io.x + stride
	if dungeon_index < _dungeon_camera_tile_bounds.size():
		var b: Rect2i = _dungeon_camera_tile_bounds[dungeon_index]
		if b.size.x > 0 and b.size.y > 0:
			min_tx = b.position.x
			max_tx = b.position.x + b.size.x
	return Vector2i(min_tx, max_tx)


func _template_interior_centroid_global(
	output: TileMapLayerAdvanced,
	template: TileMapLayerAdvanced,
	dungeon_index: int,
	io: Vector2i
) -> Vector2:
	var invalid: Vector2 = Vector2(INF, INF)
	if template == null or output == null or not output.tile_set:
		return invalid
	var tpl_used: Array[Vector2i] = template.get_used_cells()
	if tpl_used.is_empty():
		return invalid
	var sigs: Array[Dictionary] = []
	for c in tpl_used:
		var sid: int = template.get_cell_source_id(c)
		if sid < 0:
			continue
		sigs.append({"sid": sid, "ac": template.get_cell_atlas_coords(c)})
	if sigs.is_empty():
		return invalid
	var xr: Vector2i = _dungeon_instance_tile_x_range(dungeon_index, io)
	var ts: Vector2 = output.tile_set.tile_size
	var sum := Vector2.ZERO
	var count := 0
	for lc in output.get_used_cells():
		if lc.x < xr.x or lc.x >= xr.y:
			continue
		var sid2: int = output.get_cell_source_id(lc)
		if sid2 < 0:
			continue
		var ac2: Vector2i = output.get_cell_atlas_coords(lc)
		for s in sigs:
			if s.sid == sid2 and s.ac == ac2:
				sum += output.map_to_local(lc) + ts * 0.5
				count += 1
				break
	if count == 0:
		return invalid
	return output.to_global(sum / float(count))


func _boss_spawn_global_from_triforce_on_layer(layer: TileMapLayerAdvanced, dungeon_index: int, io: Vector2i) -> Vector2:
	var ts: Vector2 = layer.tile_set.tile_size
	var xr: Vector2i = _dungeon_instance_tile_x_range(dungeon_index, io)
	var min_tx: int = xr.x
	var max_tx: int = xr.y
	if not triforce_tile_layer:
		var room_top_left_local: Vector2 = layer.map_to_local(io)
		var room_size_px: Vector2 = Vector2(float(width) * ts.x, float(height) * ts.y)
		return layer.to_global(room_top_left_local + room_size_px * 0.5)
	var tf_used: Array[Vector2i] = triforce_tile_layer.get_used_cells()
	if tf_used.is_empty():
		var rtl: Vector2 = layer.map_to_local(io)
		var rsp: Vector2 = Vector2(float(width) * ts.x, float(height) * ts.y)
		return layer.to_global(rtl + rsp * 0.5)
	var sigs: Array[Dictionary] = []
	for c in tf_used:
		var sid: int = triforce_tile_layer.get_cell_source_id(c)
		if sid < 0:
			continue
		sigs.append({"sid": sid, "ac": triforce_tile_layer.get_cell_atlas_coords(c)})
	if sigs.is_empty():
		var rtl2: Vector2 = layer.map_to_local(io)
		var rsp2: Vector2 = Vector2(float(width) * ts.x, float(height) * ts.y)
		return layer.to_global(rtl2 + rsp2 * 0.5)
	var sum := Vector2.ZERO
	var count := 0
	for lc in layer.get_used_cells():
		if lc.x < min_tx or lc.x >= max_tx:
			continue
		var sid2: int = layer.get_cell_source_id(lc)
		if sid2 < 0:
			continue
		var ac2: Vector2i = layer.get_cell_atlas_coords(lc)
		for s in sigs:
			if s.sid == sid2 and s.ac == ac2:
				sum += layer.map_to_local(lc) + ts * 0.5
				count += 1
				break
	if count == 0:
		var rtl3: Vector2 = layer.map_to_local(io)
		var rsp3: Vector2 = Vector2(float(width) * ts.x, float(height) * ts.y)
		return layer.to_global(rtl3 + rsp3 * 0.5)
	var triforce_center_local: Vector2 = sum / float(count)
	var boss_center_local: Vector2 = triforce_center_local + Vector2(-float(width) * ts.x, 0.0)
	return layer.to_global(boss_center_local)


## Collision shape used as [PhantomCamera2D.limit_target] (full dungeon bounds for this instance).
func get_dungeon_camera_collision_shape(dungeon_index: int) -> CollisionShape2D:
	var resolved: Array[TileMapLayerAdvanced] = _resolve_output_layers()
	if dungeon_index < 0 or dungeon_index >= resolved.size():
		return null
	var layer: TileMapLayerAdvanced = resolved[dungeon_index]
	if not layer:
		return null
	_ensure_instance_origins_through(dungeon_index)
	if layer.tile_set:
		_ensure_and_fit_dungeon_camera(layer, dungeon_index)
	var cam: Node = layer.get_node_or_null("DungeonCameraArea2D")
	if not cam:
		return null
	return cam.get_node_or_null("CollisionShape2D") as CollisionShape2D


## Prefer [method get_dungeon_camera_collision_shape] + [method Node.get_path_to] from the [PhantomCamera2D]; root-relative [method Node.get_path] does not resolve on the PCam node.
func get_dungeon_camera_collision_path(dungeon_index: int) -> NodePath:
	var col: CollisionShape2D = get_dungeon_camera_collision_shape(dungeon_index)
	return col.get_path() if col else NodePath()


func _resolve_output_layers() -> Array[TileMapLayerAdvanced]:
	var layers: Array[TileMapLayerAdvanced] = []
	if not output_tile_layers.is_empty():
		for l in output_tile_layers:
			if l:
				layers.append(l)
	elif output_tile_layer:
		layers.append(output_tile_layer)
	return layers


func _dungeon_stride_tiles() -> int:
	var n_rooms_clamped: int = clampi(num_rooms, 3, 512)
	return n_rooms_clamped * maxi(width, height) + maxi(0, dungeon_instance_gap_tiles)


## When [member generate_maze] has not run, fill missing [member _instance_origins] slots using the same X stride as generation (so spawns/camera match painted tiles).
func _ensure_instance_origins_through(dungeon_index: int) -> void:
	if dungeon_index < 0:
		return
	if _instance_origins.size() > dungeon_index:
		return
	var old_sz: int = _instance_origins.size()
	_instance_origins.resize(dungeon_index + 1)
	for i in range(old_sz, dungeon_index + 1):
		_instance_origins[i] = Vector2i(i * _dungeon_stride_tiles(), 0)


func clear_generated() -> void:
	for l in _resolve_output_layers():
		if l:
			l.clear()
	_instance_origins.clear()
	_dungeon_camera_tile_bounds.clear()
	_boss_room_maze_cells.clear()


func generate_maze() -> void:
	var layers: Array[TileMapLayerAdvanced] = _resolve_output_layers()
	if layers.is_empty():
		push_warning("MazeDungeonBuilder: assign output_tile_layers or output_tile_layer.")
		return
	if not base_tile_layer:
		push_warning("MazeDungeonBuilder: assign base_tile_layer.")
		return
	if not entrance_tile_layer:
		push_warning("MazeDungeonBuilder: assign entrance_tile_layer.")
		return
	if not boss_tile_layer or not triforce_tile_layer:
		push_warning("MazeDungeonBuilder: assign boss_tile_layer and triforce_tile_layer.")
		return
	var n_rooms: int = clampi(num_rooms, 3, 512)
	if n_rooms != num_rooms:
		push_warning("MazeDungeonBuilder: num_rooms clamped to 3..512.")
	if n_rooms > 3 and block_tile_layers.is_empty():
		push_warning("MazeDungeonBuilder: num_rooms > 3 needs at least one block_tile_layers entry.")
		return
	if not _wall_arrays_valid():
		push_warning("MazeDungeonBuilder: each wall direction needs at least door [0] and wall [1] layers.")
		return
	var stride: int = _dungeon_stride_tiles()
	_instance_origins.clear()
	_instance_origins.resize(layers.size())
	_dungeon_camera_tile_bounds.clear()
	_dungeon_camera_tile_bounds.resize(layers.size())
	_boss_room_maze_cells.clear()
	_boss_room_maze_cells.resize(layers.size())

	for layer_i in range(layers.size()):
		if not layers[layer_i]:
			continue
		layers[layer_i].clear()
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		var placement: Dictionary = {}
		for _a in maxi(1, placement_max_attempts):
			placement = _try_maze_placement_deep_boss(n_rooms, rng)
			if not placement.is_empty():
				break
		if placement.is_empty():
			push_warning("MazeDungeonBuilder: could not build layout for instance %d." % layer_i)
			var io_fail := Vector2i(layer_i * stride, 0)
			_instance_origins[layer_i] = io_fail
			_dungeon_camera_tile_bounds[layer_i] = Rect2i(io_fail.x, io_fail.y, width, height)
			_boss_room_maze_cells[layer_i] = Vector2i.ZERO
			_ensure_and_fit_dungeon_camera(layers[layer_i], layer_i)
			continue

		var grid_pos: Array[Vector2i] = placement.positions
		var tree_edges: Dictionary = placement.edges
		var instance_origin := Vector2i(layer_i * stride, 0)
		_instance_origins[layer_i] = instance_origin
		_dungeon_camera_tile_bounds[layer_i] = _tile_bounds_all_rooms(grid_pos, instance_origin)
		_boss_room_maze_cells[layer_i] = grid_pos[n_rooms - 2]

		var grid_to_room: Dictionary = {}
		for i in range(n_rooms):
			grid_to_room[grid_pos[i]] = i

		var dst: TileMapLayerAdvanced = layers[layer_i]
		for room_i in range(n_rooms):
			var origin: Vector2i = _room_tile_origin(grid_pos[room_i], instance_origin)
			_paint_base_room(dst, origin)
			_paint_room_interior(dst, room_i, origin)

		for room_i in range(n_rooms):
			var origin: Vector2i = _room_tile_origin(grid_pos[room_i], instance_origin)
			for dir_i in 4:
				var ngrid: Vector2i = grid_pos[room_i] + _DIR_VEC[dir_i]
				var neighbor: int = grid_to_room[ngrid] if grid_to_room.has(ngrid) else -1
				var kind: int
				if room_i == 0 and dir_i == _DIR_S:
					kind = 0
				elif neighbor >= 0 and _edge_in_tree(tree_edges, room_i, neighbor):
					kind = 0
				else:
					kind = 1
				if room_i == 0 and dir_i == _DIR_S and entrance_door_tiles:
					var door_anchor: Vector2i = origin + _wall_anchor_for_dir(_DIR_S)
					_stamp_template_at_anchor(dst, door_anchor, entrance_door_tiles)
				else:
					_stamp_wall_for_side(dst, origin, dir_i, kind)

		_ensure_and_fit_dungeon_camera(dst, layer_i)

		if navigation_regions.size() > layer_i and navigation_regions[layer_i]:
			navigation_regions[layer_i].call_deferred("bake_navigation_polygon")

	_bake_navigation_if_any(layers.size())


func _room_origin(grid_cell: Vector2i) -> Vector2i:
	return Vector2i(grid_cell.x * width, grid_cell.y * height)


func _room_tile_origin(grid_cell: Vector2i, instance_origin: Vector2i) -> Vector2i:
	return instance_origin + _room_origin(grid_cell)


func _tile_bounds_all_rooms(grid_pos: Array[Vector2i], instance_origin: Vector2i) -> Rect2i:
	var min_x: int = 2147483647
	var min_y: int = 2147483647
	var max_x: int = -2147483648
	var max_y: int = -2147483648
	for gp in grid_pos:
		var o: Vector2i = _room_tile_origin(gp, instance_origin)
		min_x = mini(min_x, o.x)
		min_y = mini(min_y, o.y)
		max_x = maxi(max_x, o.x + width - 1)
		max_y = maxi(max_y, o.y + height - 1)
	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)


func _dungeon_camera_tile_rect_for_layer(layer_i: int) -> Rect2i:
	if layer_i >= 0 and layer_i < _dungeon_camera_tile_bounds.size():
		var stored: Rect2i = _dungeon_camera_tile_bounds[layer_i]
		if stored.size.x > 0 and stored.size.y > 0:
			return stored
	_ensure_instance_origins_through(layer_i)
	var io: Vector2i = _instance_origins[layer_i] if layer_i < _instance_origins.size() else Vector2i.ZERO
	return Rect2i(io.x, io.y, width, height)


## Phantom camera limits: one [CameraArea2D] per output layer; rectangle covers the whole instance in tile space.
func _ensure_and_fit_dungeon_camera(layer: TileMapLayerAdvanced, layer_i: int) -> void:
	if not layer or layer_i < 0:
		return
	_ensure_instance_origins_through(layer_i)
	if not layer.tile_set:
		return
	var cam: CameraArea2D = layer.get_node_or_null("DungeonCameraArea2D") as CameraArea2D
	if not cam:
		cam = CameraArea2D.new()
		cam.name = "DungeonCameraArea2D"
		cam.collision_layer = 256
		cam.monitoring = false
		cam.monitorable = false
		layer.add_child(cam)
		var col_new := CollisionShape2D.new()
		col_new.name = "CollisionShape2D"
		col_new.shape = RectangleShape2D.new()
		cam.add_child(col_new)
	var col_shape: CollisionShape2D = cam.get_node("CollisionShape2D") as CollisionShape2D
	if not col_shape:
		col_shape = CollisionShape2D.new()
		col_shape.name = "CollisionShape2D"
		col_shape.shape = RectangleShape2D.new()
		cam.add_child(col_shape)
	var shape: RectangleShape2D = col_shape.shape as RectangleShape2D
	if not shape:
		shape = RectangleShape2D.new()
		col_shape.shape = shape
	cam.position = Vector2.ZERO
	var ts: Vector2 = layer.tile_set.tile_size
	# Prefer painted tile bounds (includes walls/doors that extend past room grid math).
	var used: Rect2i = layer.get_used_rect()
	var tile_bounds: Rect2i
	if used.size.x > 0 and used.size.y > 0:
		tile_bounds = used
	else:
		tile_bounds = _dungeon_camera_tile_rect_for_layer(layer_i)
	var tl_tile: Vector2i = tile_bounds.position
	var br_tile: Vector2i = tile_bounds.position + tile_bounds.size - Vector2i(1, 1)
	var m: Vector2 = dungeon_camera_margin_pixels
	var top_left: Vector2 = layer.map_to_local(tl_tile) - m
	var bottom_right: Vector2 = layer.map_to_local(br_tile) + ts + m
	var size_px: Vector2 = (bottom_right - top_left).max(Vector2.ONE)
	var center_layer: Vector2 = (top_left + bottom_right) * 0.5
	shape.size = size_px
	# CollisionShape2D is under CameraArea2D; express center in cam local space (handles non-zero cam offset).
	col_shape.position = cam.to_local(layer.to_global(center_layer))
	cam.level = layer_i


func _wall_arrays_valid() -> bool:
	return (
		up_wall_tile_layers.size() >= 2
		and down_wall_tile_layers.size() >= 2
		and left_wall_tile_layers.size() >= 2
		and right_wall_tile_layers.size() >= 2
	)


func _edge_key(a: int, b: int) -> String:
	var lo: int = mini(a, b)
	var hi: int = maxi(a, b)
	return "%d,%d" % [lo, hi]


func _edge_in_tree(edges: Dictionary, a: int, b: int) -> bool:
	return edges.has(_edge_key(a, b))


## Random spanning tree for entrance + block rooms (branching maze), then boss on a parent that
## maximizes graph distance from the entrance. Triforce is always east (right) of the boss.
func _try_maze_placement_deep_boss(n: int, rng: RandomNumberGenerator) -> Dictionary:
	if n < 3:
		return {}
	var block_count: int = n - 3
	var last_block_idx: int = block_count
	var boss_idx: int = n - 2
	var triforce_idx: int = n - 1

	var positions: Array[Vector2i] = []
	positions.resize(n)
	var edges: Dictionary = {}
	var occupied: Dictionary = {}
	positions[0] = Vector2i.ZERO
	occupied[positions[0]] = true
	var south_of_entrance: Vector2i = positions[0] + Vector2i(0, 1)

	var in_tree: Array[bool] = []
	in_tree.resize(n)
	for i in range(n):
		in_tree[i] = false
	in_tree[0] = true

	var attach_order: Array[int] = []
	for j in range(1, last_block_idx + 1):
		attach_order.append(j)
	_shuffle_int_array(attach_order, rng)

	for new_idx in attach_order:
		var parents: Array[int] = []
		for p in range(n):
			if in_tree[p] and p <= last_block_idx:
				parents.append(p)
		_shuffle_int_array(parents, rng)
		var placed_new: bool = false
		for p in parents:
			var dirs_pb: Array[int] = [0, 1, 2, 3]
			_shuffle_int_array(dirs_pb, rng)
			for d in dirs_pb:
				var cand: Vector2i = positions[p] + _DIR_VEC[d]
				if cand == south_of_entrance:
					continue
				if occupied.has(cand):
					continue
				positions[new_idx] = cand
				occupied[cand] = true
				in_tree[new_idx] = true
				edges[_edge_key(p, new_idx)] = true
				placed_new = true
				break
			if placed_new:
				break
		if not placed_new:
			return {}

	var dist: Array[int] = _bfs_depth_from_entrance_on_edges(edges, last_block_idx)
	var best_boss_depth: int = -1
	var boss_options: Array = []
	for p in range(last_block_idx + 1):
		var dirs_b: Array[int] = [0, 1, 2, 3]
		_shuffle_int_array(dirs_b, rng)
		for d in dirs_b:
			var cand_b: Vector2i = positions[p] + _DIR_VEC[d]
			if cand_b == south_of_entrance:
				continue
			if occupied.has(cand_b):
				continue
			var triforce_east: Vector2i = cand_b + _DIR_VEC[_DIR_E]
			if triforce_east == south_of_entrance or occupied.has(triforce_east):
				continue
			var d_here: int = dist[p] + 1
			if d_here > best_boss_depth:
				best_boss_depth = d_here
				boss_options.clear()
				boss_options.append(Vector3i(p, cand_b.x, cand_b.y))
			elif d_here == best_boss_depth:
				boss_options.append(Vector3i(p, cand_b.x, cand_b.y))

	if boss_options.is_empty():
		return {}

	var pick: Vector3i = boss_options[rng.randi_range(0, boss_options.size() - 1)]
	var parent_boss: int = pick.x
	var boss_cell := Vector2i(pick.y, pick.z)
	positions[boss_idx] = boss_cell
	occupied[boss_cell] = true
	edges[_edge_key(parent_boss, boss_idx)] = true

	var cand_tf: Vector2i = positions[boss_idx] + _DIR_VEC[_DIR_E]
	if cand_tf == south_of_entrance or occupied.has(cand_tf):
		return {}
	positions[triforce_idx] = cand_tf
	occupied[cand_tf] = true
	edges[_edge_key(boss_idx, triforce_idx)] = true
	for i in range(1, n):
		if positions[i] == south_of_entrance:
			return {}
	return {"positions": positions, "edges": edges}


func _bfs_depth_from_entrance_on_edges(edges: Dictionary, last_block_idx: int) -> Array[int]:
	var n_pre: int = last_block_idx + 1
	var adj: Array = []
	adj.resize(n_pre)
	for i in range(n_pre):
		adj[i] = []
	for k in edges.keys():
		var parts: PackedStringArray = String(k).split(",")
		if parts.size() != 2:
			continue
		var a: int = int(parts[0])
		var b: int = int(parts[1])
		if a > last_block_idx or b > last_block_idx:
			continue
		adj[a].append(b)
		adj[b].append(a)
	var dist: Array[int] = []
	dist.resize(n_pre)
	for i in range(n_pre):
		dist[i] = -1
	dist[0] = 0
	var q: Array[int] = [0]
	while q.size() > 0:
		var u: int = q.pop_front()
		for v in adj[u]:
			if dist[v] < 0:
				dist[v] = dist[u] + 1
				q.append(v)
	return dist


func _shuffle_int_array(a: Array, rng: RandomNumberGenerator) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var t = a[i]
		a[i] = a[j]
		a[j] = t


func _paint_base_room(dst: TileMapLayerAdvanced, origin: Vector2i) -> void:
	for y in height:
		for x in width:
			var src_c := Vector2i(x, y)
			if base_tile_layer.get_cell_source_id(src_c) < 0:
				continue
			var dst_c: Vector2i = origin + src_c
			dst.set_cell(
				dst_c,
				base_tile_layer.get_cell_source_id(src_c),
				base_tile_layer.get_cell_atlas_coords(src_c),
				base_tile_layer.get_cell_alternative_tile(src_c)
			)


func _paint_room_interior(dst: TileMapLayerAdvanced, room_index: int, origin: Vector2i) -> void:
	var n: int = clampi(num_rooms, 3, 512)
	var last_block_idx: int = n - 3
	var src: TileMapLayerAdvanced = null
	if room_index == 0:
		src = entrance_tile_layer
	elif room_index >= 1 and room_index <= last_block_idx:
		var bi: int = (room_index - 1) % block_tile_layers.size()
		src = block_tile_layers[bi]
	elif room_index == n - 2:
		src = boss_tile_layer
	elif room_index == n - 1:
		src = triforce_tile_layer
	if not src:
		return
	var used: Array[Vector2i] = src.get_used_cells()
	if used.is_empty():
		return
	var min_t := used[0]
	for c in used:
		min_t.x = mini(min_t.x, c.x)
		min_t.y = mini(min_t.y, c.y)
	for c in used:
		var sid: int = src.get_cell_source_id(c)
		if sid < 0:
			continue
		var dst_c: Vector2i = origin + interior_tile_offset + (c - min_t)
		if not _is_tile_in_room(origin, dst_c):
			continue
		dst.set_cell(dst_c, sid, src.get_cell_atlas_coords(c), src.get_cell_alternative_tile(c))


func _is_tile_in_room(room_origin: Vector2i, global_tile: Vector2i) -> bool:
	var rel: Vector2i = global_tile - room_origin
	return rel.x >= 0 and rel.y >= 0 and rel.x < width and rel.y < height


func _wall_layers_for_dir(dir_i: int) -> Array[TileMapLayerAdvanced]:
	match dir_i:
		_DIR_N:
			return up_wall_tile_layers
		_DIR_E:
			return right_wall_tile_layers
		_DIR_S:
			return down_wall_tile_layers
		_DIR_W:
			return left_wall_tile_layers
		_:
			return left_wall_tile_layers


func _wall_anchor_for_dir(dir_i: int) -> Vector2i:
	match dir_i:
		_DIR_N:
			return wall_up_start_index
		_DIR_E:
			return wall_right_start_index
		_DIR_S:
			return wall_down_start_index
		_DIR_W:
			return wall_left_start_index
		_:
			return wall_left_start_index


func _stamp_wall_for_side(
	dst: TileMapLayerAdvanced,
	room_origin: Vector2i,
	dir_i: int,
	layer_kind: int
) -> void:
	var layers: Array[TileMapLayerAdvanced] = _wall_layers_for_dir(dir_i)
	if layers.is_empty():
		return
	var idx: int = clampi(layer_kind, 0, layers.size() - 1)
	var src: TileMapLayerAdvanced = layers[idx]
	while not src and idx > 0:
		idx -= 1
		src = layers[idx]
	if not src:
		return
	var anchor: Vector2i = room_origin + _wall_anchor_for_dir(dir_i)
	_stamp_template_at_anchor(dst, anchor, src)


func _stamp_template_at_anchor(dst: TileMapLayerAdvanced, dst_anchor: Vector2i, src: TileMapLayerAdvanced) -> void:
	var used: Array[Vector2i] = src.get_used_cells()
	if used.is_empty():
		return
	var min_t := used[0]
	for c in used:
		min_t.x = mini(min_t.x, c.x)
		min_t.y = mini(min_t.y, c.y)
	for c in used:
		var sid: int = src.get_cell_source_id(c)
		if sid < 0:
			continue
		var dst_c: Vector2i = dst_anchor + (c - min_t)
		dst.set_cell(dst_c, sid, src.get_cell_atlas_coords(c), src.get_cell_alternative_tile(c))


func _bake_navigation_if_any(output_layer_count: int) -> void:
	if output_layer_count <= 0:
		return
	if navigation_region:
		navigation_region.call_deferred("bake_navigation_polygon")
