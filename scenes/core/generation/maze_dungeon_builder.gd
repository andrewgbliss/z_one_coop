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

@export var output_tile_layer: TileMapLayerAdvanced
@export var navigation_region: NavigationRegion2D

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


func clear_generated() -> void:
	if output_tile_layer:
		output_tile_layer.clear()


func generate_maze() -> void:
	if not output_tile_layer:
		push_warning("MazeDungeonBuilder: assign output_tile_layer.")
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
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var placement: Dictionary = {}
	for _a in maxi(1, placement_max_attempts):
		placement = _try_maze_placement_deep_boss(n_rooms, rng)
		if not placement.is_empty():
			break
	if placement.is_empty():
		push_warning("MazeDungeonBuilder: could not build room layout; increase placement_max_attempts.")
		return

	var grid_pos: Array[Vector2i] = placement.positions
	var tree_edges: Dictionary = placement.edges

	output_tile_layer.clear()

	var grid_to_room: Dictionary = {}
	for i in range(n_rooms):
		grid_to_room[grid_pos[i]] = i

	for room_i in range(n_rooms):
		var origin: Vector2i = _room_origin(grid_pos[room_i])
		_paint_base_room(origin)
		_paint_room_interior(room_i, origin)

	for room_i in range(n_rooms):
		var origin: Vector2i = _room_origin(grid_pos[room_i])
		for dir_i in 4:
			var ngrid: Vector2i = grid_pos[room_i] + _DIR_VEC[dir_i]
			var neighbor: int = grid_to_room[ngrid] if grid_to_room.has(ngrid) else -1
			var kind: int
			# Entrance: south is always the overworld exit — never a maze link (no room may sit south).
			if room_i == 0 and dir_i == _DIR_S:
				kind = 0
			elif neighbor >= 0 and _edge_in_tree(tree_edges, room_i, neighbor):
				kind = 0
			else:
				# Solid wall (non-tree neighbor or exterior).
				kind = 1
			_stamp_wall_for_side(output_tile_layer, origin, dir_i, kind)

	_bake_navigation_if_any()


func _room_origin(grid_cell: Vector2i) -> Vector2i:
	return Vector2i(grid_cell.x * width, grid_cell.y * height)


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


func _paint_base_room(origin: Vector2i) -> void:
	for y in height:
		for x in width:
			var src_c := Vector2i(x, y)
			if base_tile_layer.get_cell_source_id(src_c) < 0:
				continue
			var dst_c: Vector2i = origin + src_c
			output_tile_layer.set_cell(
				dst_c,
				base_tile_layer.get_cell_source_id(src_c),
				base_tile_layer.get_cell_atlas_coords(src_c),
				base_tile_layer.get_cell_alternative_tile(src_c)
			)


func _paint_room_interior(room_index: int, origin: Vector2i) -> void:
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
		output_tile_layer.set_cell(dst_c, sid, src.get_cell_atlas_coords(c), src.get_cell_alternative_tile(c))


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


func _bake_navigation_if_any() -> void:
	if navigation_region:
		navigation_region.bake_navigation_polygon()
