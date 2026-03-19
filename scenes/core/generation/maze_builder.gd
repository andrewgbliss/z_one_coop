@tool
class_name MazeBuilder extends Node2D

## Number of maze cells in each dimension (e.g. 8 x 8 = 64 cells total).
@export var grid_size: Vector2i = Vector2i(8, 8)
## Each cell is this many tiles wide and tall; copied as a block from wall/path layers.
@export var cell_size: int = 8
## Godot units per block (one cell). Used to position each tilemap layer so they don't overlap.
@export var block_size_units: int = 1024

@export var navigation_region: NavigationRegion2D
@export var level: int = 0

@export_tool_button("Generate Maze", "Callable")
var generate_maze_action = generate_maze

@export_tool_button("Clear Terrain", "Callable")
var clear_terrain_action = clear_terrain

signal maze_generated(start_tile: Vector2i)

@export var tile_map_layers: Array[TileMapLayerAdvanced] = []
## Used during generation; first layer is used for get_tile_by_pos / get_tiles_by_type when array is non-empty.
var _current_tile_map_layer: TileMapLayerAdvanced
## The TileMapLayer currently parented under `navigation_region` for navigation baking/queries.
var _navigation_active_layer: TileMapLayerAdvanced = null
## Map offset for current layer.
## Kept at (0,0) so generated tile coordinates always start from the layer's origin.
var _current_layer_map_offset: Vector2i = Vector2i(0, 0)

## Per-layer door positions (cell coords) from last generation. Layer N's end connects to layer N+1's start.
var layer_start_cells: Array[Vector2i] = []
var layer_end_cells: Array[Vector2i] = []

## Per-layer layout position in "layer grid" (layer 0 = (0,0); each next is one step up/down/left/right, branching).
## Use get_layer_world_offset() to get world position in Godot units for placing each layer.
var layer_positions: Array[Vector2i] = []

## Records the shop placement for the entry layer (layer index `1`) so gameplay can
## spawn the player "just under" the shop tiles.
var last_shop_layer_index: int = -1
var last_shop_top_left_tile_in_layer: Vector2i = Vector2i(-1, -1)
var last_shop_size_in_tiles: Vector2i = Vector2i(0, 0)
var last_shop_bottom_mid_tile_in_layer: Vector2i = Vector2i(-1, -1)
var last_wall_source_id: int = -1
var _current_layer_index: int = -1
var _shop_record_layer_index: int = 0

class TileInfo:
	var tile_data: TileData
	var map_coords: Vector2
	var local_coords: Vector2
	
func get_tile_by_pos(local_coords: Vector2) -> TileInfo:
	var layer := _main_layer()
	if not layer:
		return null
	var map_coords = layer.local_to_map(local_coords)
	var data = layer.get_cell_tile_data(map_coords)
	if data:
		var tile_info = TileInfo.new()
		tile_info.tile_data = data
		tile_info.map_coords = map_coords
		tile_info.local_coords = map_coords
		return tile_info
	return null

func get_tiles_by_type(type: String) -> Array[TileInfo]:
	var tiles: Array[TileInfo] = []
	var layer := _main_layer()
	if not layer:
		return tiles
	var total_tiles_x := grid_size.x * cell_size
	var total_tiles_y := grid_size.y * cell_size
	for row in total_tiles_y:
		for col in total_tiles_x:
			var local_coords = Vector2(col * 16, row * 16)
			var map_coords = layer.local_to_map(local_coords)
			var data = layer.get_cell_tile_data(map_coords)
			if data:
				var data_type = data.get_custom_data("type")
				print(data_type)
				if type == data.get_custom_data("type"):
					var tile_info = TileInfo.new()
					tile_info.tile_data = data
					tile_info.map_coords = map_coords
					tile_info.local_coords = local_coords
					tiles.append(tile_info)
	return tiles

func _ready() -> void:
	pass

func enable_area(layer_index: int = -1, debug_prints: bool = true) -> void:
	if tile_map_layers.is_empty():
		if debug_prints:
			print("MazeBuilder.enable_area: no tile_map_layers")
		return

	var target_index := layer_index
	if target_index < 0:
		target_index = int(level)

	if debug_prints:
		print("MazeBuilder.enable_area: target_index=", target_index, " layers=", tile_map_layers.size())

	for layer in tile_map_layers:
		if layer:
			layer.process_mode = Node.PROCESS_MODE_DISABLED

	if target_index < 0 or target_index >= tile_map_layers.size():
		if debug_prints:
			print("MazeBuilder.enable_area: target_index out of range")
		return

	# Enable previous, current, and next layer (so transitions/preloads can run).
	for idx in [target_index - 1, target_index, target_index + 1]:
		if idx < 0 or idx >= tile_map_layers.size():
			if debug_prints:
				print("MazeBuilder.enable_area: skip idx=", idx, " (out of range)")
			continue
		var layer := tile_map_layers[idx]
		if layer:
			layer.process_mode = Node.PROCESS_MODE_INHERIT
			if debug_prints:
				print("MazeBuilder.enable_area: enabled idx=", idx, " name=", layer.name)
		elif debug_prints:
			print("MazeBuilder.enable_area: idx=", idx, " is null")

	if debug_prints:
		for i in range(tile_map_layers.size()):
			var l := tile_map_layers[i]
			if not l:
				print("MazeBuilder.enable_area: layer[", i, "] = null")
				continue
			print("MazeBuilder.enable_area: layer[", i, "] name=", l.name, " process_mode=", l.process_mode)

func set_navigation_active_layer(_layer_index: int) -> void:
	# this will just enable / diable the region as needed already pre baked
	pass
	# if not navigation_region:
	# 	return
	# if tile_map_layers.is_empty():
	# 	return
	# if layer_index < 0 or layer_index >= tile_map_layers.size():
	# 	return

	# var target: TileMapLayerAdvanced = tile_map_layers[layer_index]
	# if not target:
	# 	return

	# # Move any existing TileMapLayerAdvanced children of the navigation region back under the builder.
	# # This keeps the region owning exactly one active layer at a time.
	# for child in navigation_region.get_children():
	# 	if child is TileMapLayerAdvanced:
	# 		var existing: TileMapLayerAdvanced = child
	# 		if existing != target:
	# 			existing.reparent(self , true)

	# # If our tracked active layer is different, ensure it's also moved out.
	# if _navigation_active_layer and is_instance_valid(_navigation_active_layer) and _navigation_active_layer != target:
	# 	if _navigation_active_layer.get_parent() == navigation_region:
	# 		_navigation_active_layer.reparent(self , true)

	# # Finally, move the requested layer under the navigation region.
	# if target.get_parent() != navigation_region:
	# 	target.reparent(navigation_region, true)
	# _navigation_active_layer = target
	# call_deferred("_bake_navigation_deferred")

func _bake_navigation_deferred() -> void:
	if not navigation_region:
		return
	# This function is invoked via `call_deferred()`, then we wait one more frame
	# so reparenting/tile updates have fully applied before baking.
	# await get_tree().create_timer(1.0).timeout
	# if navigation_region.has_method("bake_navigation_polygon_async"):
	# 	navigation_region.bake_navigation_polygon_async()
	# elif navigation_region.has_method("bake_navigation_polygon"):
	# 	navigation_region.bake_navigation_polygon()

func _main_layer() -> TileMapLayerAdvanced:
	if tile_map_layers.is_empty():
		return null
	return tile_map_layers[0]

## Returns world offset in Godot units. One step = one full layer size so adjacent layers touch.
func get_layer_world_offset(layer_index: int) -> Vector2:
	if layer_index < 0 or layer_index >= layer_positions.size():
		return Vector2.ZERO
	var p: Vector2i = layer_positions[layer_index]
	return Vector2(
		p.x * grid_size.x * block_size_units,
		p.y * grid_size.y * block_size_units
	)

func _apply_layer_positions() -> void:
	# Move the actual layer nodes so visual placement comes from transforms,
	# not from shifted tile coordinates.
	for i in range(tile_map_layers.size()):
		var layer = tile_map_layers[i]
		if not layer:
			continue
		var offset := get_layer_world_offset(i)
		# Prefer moving the layer itself (it has a `position` property in Godot's TileMapLayer).
		layer.position = offset

func clear_terrain() -> void:
	for layer in tile_map_layers:
		if layer:
			layer.clear()
	var layer := _main_layer()
	if layer:
		var source_count = layer.tile_set.get_source_count()
		print(source_count)

func _get_tile_from_layer(layer: TileMapLayerAdvanced, map_pos: Vector2i) -> Dictionary:
	# Returns { source_id: int, atlas_coords: Vector2i, alternative_tile: int } or empty if no tile.
	if not layer:
		return {}
	var coords := map_pos
	if layer.get_cell_source_id(coords) == -1:
		coords = Vector2i(0, 0)
	if layer.get_cell_source_id(coords) == -1:
		return {}
	return {
		"source_id": layer.get_cell_source_id(coords),
		"atlas_coords": layer.get_cell_atlas_coords(coords),
		"alternative_tile": layer.get_cell_alternative_tile(coords)
	}

func _get_any_tile_from_layer(layer: TileMapLayerAdvanced) -> Dictionary:
	# Returns the first non-empty tile found in the layer (tries (0,0), (1,1), then first cell_size x cell_size).
	if not layer:
		return {}
	for y in cell_size:
		for x in cell_size:
			var c := Vector2i(x, y)
			if layer.get_cell_source_id(c) != -1:
				return {
					"source_id": layer.get_cell_source_id(c),
					"atlas_coords": layer.get_cell_atlas_coords(c),
					"alternative_tile": layer.get_cell_alternative_tile(c)
				}
	return {}

func _get_any_tile_from_layer_used_cells(layer: TileMapLayerAdvanced) -> Dictionary:
	# Returns the first tile from the layer by scanning get_used_cells(), so we find tiles anywhere on the layer.
	if not layer:
		return {}
	var used: Array = layer.get_used_cells()
	for cell in used:
		var c: Vector2i = Vector2i(cell.x, cell.y)
		if layer.get_cell_source_id(c) != -1:
			return {
				"source_id": layer.get_cell_source_id(c),
				"atlas_coords": layer.get_cell_atlas_coords(c),
				"alternative_tile": layer.get_cell_alternative_tile(c),
				"map_coords": c
			}
	return {}

## Copies a cell_size x cell_size block from source_layer into current tile map layer at the given cell position.
func _copy_cell_block(
	cell_pos: Vector2i,
	source_layer: TileMapLayerAdvanced,
	tile_fallback: Dictionary,
	source_origin: Vector2i = Vector2i(0, 0)
) -> void:
	if not _current_tile_map_layer:
		return
	var base_x := cell_pos.x * cell_size
	var base_y := cell_pos.y * cell_size
	for dy in cell_size:
		for dx in cell_size:
			var tile_pos := Vector2i(base_x + dx, base_y + dy) + _current_layer_map_offset
			if source_layer:
				var src_coords := Vector2i(source_origin.x + dx, source_origin.y + dy)
				var sid := source_layer.get_cell_source_id(src_coords)
				if sid != -1:
					_current_tile_map_layer.set_cell(
						tile_pos,
						sid,
						source_layer.get_cell_atlas_coords(src_coords),
						source_layer.get_cell_alternative_tile(src_coords)
					)
					continue
			if not tile_fallback.is_empty():
				_current_tile_map_layer.set_cell(tile_pos, tile_fallback.source_id, tile_fallback.atlas_coords, tile_fallback.alternative_tile)

func _template_block_has_any_tile(layer: TileMapLayerAdvanced, origin: Vector2i) -> bool:
	if not layer:
		return false
	for dy in cell_size:
		for dx in cell_size:
			if layer.get_cell_source_id(origin + Vector2i(dx, dy)) != -1:
				return true
	return false

## Copies all authored (used) tiles from `source_layer` into the target layer, placing `source_anchor`
## at the top-left tile of the chosen `cell_pos` block.
## This is more accurate than copying a fixed 8x8 block when templates are authored with offsets.
func _copy_used_tiles_to_cell(
	cell_pos: Vector2i,
	source_layer: TileMapLayerAdvanced,
	source_anchor: Vector2i
) -> void:
	if not _current_tile_map_layer or not source_layer:
		return
	var dst_base := Vector2i(cell_pos.x * cell_size, cell_pos.y * cell_size) + _current_layer_map_offset
	var used: Array[Vector2i] = source_layer.get_used_cells()
	for src_c in used:
		var sid: int = source_layer.get_cell_source_id(src_c)
		if sid == -1:
			continue
		var dst_c: Vector2i = dst_base + (src_c - source_anchor)
		_current_tile_map_layer.set_cell(
			dst_c,
			sid,
			source_layer.get_cell_atlas_coords(src_c),
			source_layer.get_cell_alternative_tile(src_c)
		)

func _place_shop_templates_in_current_layer(rng: RandomNumberGenerator) -> void:
	if not _current_tile_map_layer:
		print("no current tile map layer")
		return

	var shop_layers: Array[TileMapLayerAdvanced] = _current_tile_map_layer.maze_layer_group.tile_map_shop
	if shop_layers.is_empty():
		return

	var shop_layer: TileMapLayerAdvanced = shop_layers.pick_random()
	var used: Array[Vector2i] = shop_layer.get_used_cells()
	if used.is_empty():
		return

	# Compute template bounds in tile coordinates so we can keep the translated shop inside our grid.
	var min_tile: Vector2i = used[0]
	var max_tile: Vector2i = used[0]
	for c in used:
		min_tile.x = min(min_tile.x, c.x)
		min_tile.y = min(min_tile.y, c.y)
		max_tile.x = max(max_tile.x, c.x)
		max_tile.y = max(max_tile.y, c.y)

	var rel_max_x := max_tile.x - min_tile.x
	var rel_max_y := max_tile.y - min_tile.y

	# Grid bounds in tile coordinates.
	var max_local_x := grid_size.x * cell_size - 1
	var max_local_y := grid_size.y * cell_size - 1

	# We only pick inner odd cells for consistency with other placements.
	var min_shop_cell_x := 1
	var max_shop_cell_x := grid_size.x - 2
	var min_shop_cell_y := 1
	var max_shop_cell_y := grid_size.y - 2

	# Ensure the template (translated) doesn't exceed the layer grid.
	max_shop_cell_x = min(
		max_shop_cell_x,
		int(floor((max_local_x - rel_max_x) / float(cell_size)))
	)
	max_shop_cell_y = min(
		max_shop_cell_y,
		int(floor((max_local_y - rel_max_y) / float(cell_size)))
	)

	if max_shop_cell_x < min_shop_cell_x or max_shop_cell_y < min_shop_cell_y:
		return

	var preferred_x := rng.randi_range(min_shop_cell_x, max_shop_cell_x)
	var preferred_y := rng.randi_range(min_shop_cell_y, max_shop_cell_y)

	var shop_cell_x := _clamp_to_odd_range(min_shop_cell_x, max_shop_cell_x, preferred_x)
	var shop_cell_y := _clamp_to_odd_range(min_shop_cell_y, max_shop_cell_y, preferred_y)

	# Record the placement for the entry layer so gameplay can spawn relative to it.
	if _current_layer_index == _shop_record_layer_index:
		# `shop_cell_x/y` are cell-block coords; convert to tile coords.
		# The template is copied starting at dst_base = cell_pos * cell_size.
		var dst_base := Vector2i(shop_cell_x * cell_size, shop_cell_y * cell_size) + _current_layer_map_offset
		var template_size_in_tiles := Vector2i(rel_max_x + 1, rel_max_y + 1)
		last_shop_layer_index = _current_layer_index
		last_shop_top_left_tile_in_layer = dst_base
		last_shop_size_in_tiles = template_size_in_tiles

		# Record a stable "bottom middle" tile so spawn can be aligned precisely.
		# We use the placed template's bottom-most row (max y in used cells) and pick
		# the x closest to the middle of that row.
		var bottom_row_cells: Array[Vector2i] = []
		for c in used:
			if c.y == max_tile.y:
				bottom_row_cells.append(c)
		if bottom_row_cells.size() > 0:
			var row_min_x := bottom_row_cells[0].x
			var row_max_x := bottom_row_cells[0].x
			for c in bottom_row_cells:
				row_min_x = min(row_min_x, c.x)
				row_max_x = max(row_max_x, c.x)
			var desired_rel_mid_x := int(floor((row_min_x + row_max_x) / 2.0))
			var best_cell: Vector2i = bottom_row_cells[0]
			var best_dist: int = abs(bottom_row_cells[0].x - desired_rel_mid_x)
			for c in bottom_row_cells:
				var d: int = abs(c.x - desired_rel_mid_x)
				if d < best_dist:
					best_dist = d
					best_cell = c

			# Translate from source template tile coords into destination tile coords.
			var src_anchor := min_tile
			var bottom_mid_x := dst_base.x + (best_cell.x - src_anchor.x)
			var bottom_mid_y := dst_base.y + (best_cell.y - src_anchor.y)
			last_shop_bottom_mid_tile_in_layer = Vector2i(bottom_mid_x, bottom_mid_y)

	_copy_used_tiles_to_cell(Vector2i(shop_cell_x, shop_cell_y), shop_layer, min_tile)

## Returns tile data from the current layer at the top-left of a cell (guaranteed same tileset). Used so dungeon always draws.
func _get_tile_from_main_layer_at_cell(cell_pos: Vector2i) -> Dictionary:
	if not _current_tile_map_layer:
		return {}
	var tile_pos := Vector2i(cell_pos.x * cell_size, cell_pos.y * cell_size) + _current_layer_map_offset
	var sid: int = _current_tile_map_layer.get_cell_source_id(tile_pos)
	if sid < 0:
		return {}
	return {
		"source_id": sid,
		"atlas_coords": _current_tile_map_layer.get_cell_atlas_coords(tile_pos),
		"alternative_tile": _current_tile_map_layer.get_cell_alternative_tile(tile_pos)
	}

func generate_maze() -> Vector2i:
	if tile_map_layers.is_empty():
		return Vector2i(-1, -1)

	# Reset per-generation recorded values.
	last_shop_layer_index = -1
	last_shop_top_left_tile_in_layer = Vector2i(-1, -1)
	last_shop_size_in_tiles = Vector2i(0, 0)
	last_shop_bottom_mid_tile_in_layer = Vector2i(-1, -1)
	last_wall_source_id = -1

	# `generate_maze()` previously referenced `_current_tile_map_layer` before
	# it was assigned, which crashes when `_current_tile_map_layer` is `Nil`.
	# Use the first layer as the template source for picking start/end/walls.
	var reference_layer: TileMapLayerAdvanced = tile_map_layers[0]

	# Pick one random layer from each array. Walls: index 0 = top, 1 = middle, 2 = bottom (by row).
	var start_layer: TileMapLayerAdvanced = null
	var end_layer: TileMapLayerAdvanced = null
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Time.get_ticks_msec()) ^ randi()

	if reference_layer and reference_layer.maze_layer_group:
		if reference_layer.maze_layer_group.tile_map_start.size() > 0:
			start_layer = reference_layer.maze_layer_group.tile_map_start[rng.randi_range(0, reference_layer.maze_layer_group.tile_map_start.size() - 1)]
		if reference_layer.maze_layer_group.tile_map_end.size() > 0:
			end_layer = reference_layer.maze_layer_group.tile_map_end[rng.randi_range(0, reference_layer.maze_layer_group.tile_map_end.size() - 1)]

	var start_tile_fallback: Dictionary = _get_any_tile_from_layer(start_layer) if start_layer else {}
	var end_tile_fallback: Dictionary = _get_any_tile_from_layer(end_layer) if end_layer else {}

	var wall_source_id: int = -1
	if reference_layer and reference_layer.maze_layer_group and reference_layer.maze_layer_group.tile_map_walls.size() > 0:
		var first_wall_tile: Dictionary = _get_any_tile_from_layer(reference_layer.maze_layer_group.tile_map_walls[0])
		if not first_wall_tile.is_empty():
			wall_source_id = first_wall_tile.get("source_id", -1) as int

	last_wall_source_id = wall_source_id

	var first_start_tile := Vector2i(-1, -1)

	layer_start_cells.clear()
	layer_end_cells.clear()
	layer_positions.clear()
	layer_start_cells.resize(tile_map_layers.size())
	layer_end_cells.resize(tile_map_layers.size())
	layer_positions.resize(tile_map_layers.size())
	for i in range(tile_map_layers.size()):
		layer_start_cells[i] = Vector2i(-1, -1)
		layer_end_cells[i] = Vector2i(-1, -1)
		layer_positions[i] = Vector2i(0, 0)
	layer_positions[0] = Vector2i(0, 0)

	for layer_index in tile_map_layers.size():
		_current_layer_index = layer_index
		_current_tile_map_layer = tile_map_layers[layer_index]
		if not _current_tile_map_layer:
			continue

		# Always keep generated tile coordinates starting at (0,0) in the layer.
		# Layers are visually separated by transform via _apply_layer_positions().
		_current_layer_map_offset = Vector2i(0, 0)

		var is_first: bool = (layer_index == 0)
		var is_last: bool = (layer_index == tile_map_layers.size() - 1)

		if is_first:
			# First layer: random path tiles in the middle, wall border on the outside only, one exit on the border.
			_current_tile_map_layer.clear()
			# Fill entire grid with varied random path tiles.
			for cy in grid_size.y:
				for cx in grid_size.x:
					var path_choice_cell: Array = _get_random_path_layer_and_fallback(rng)
					_copy_cell_block(Vector2i(cx, cy), path_choice_cell[0], path_choice_cell[1])
			# Overwrite only the outside border (no walls in the middle).
			var wall_layer_for_border: TileMapLayerAdvanced = _get_wall_layer_for_row(0)
			var wall_fallback: Dictionary = _get_any_tile_from_layer(wall_layer_for_border) if wall_layer_for_border else {}
			for cx in grid_size.x:
				_copy_cell_block(Vector2i(cx, 0), wall_layer_for_border, wall_fallback)
				_copy_cell_block(Vector2i(cx, grid_size.y - 1), wall_layer_for_border, wall_fallback)
			for cy in range(1, grid_size.y - 1):
				_copy_cell_block(Vector2i(0, cy), wall_layer_for_border, wall_fallback)
				_copy_cell_block(Vector2i(grid_size.x - 1, cy), wall_layer_for_border, wall_fallback)
			# Place exit on a random border cell.
			var border: Array[Vector2i] = _get_border_cells()
			if border.is_empty():
				continue
			var exit_cell: Vector2i = border[rng.randi_range(0, border.size() - 1)]
			var end_layer_or_path: TileMapLayerAdvanced = end_layer if end_layer else null
			var end_fallback: Dictionary = end_tile_fallback if not end_tile_fallback.is_empty() else {}
			if end_layer_or_path == null:
				var path_choice_first: Array = _get_random_path_layer_and_fallback(rng)
				end_layer_or_path = path_choice_first[0]
				end_fallback = path_choice_first[1]
			_copy_cell_block(exit_cell, end_layer_or_path, end_fallback)
			layer_end_cells[0] = exit_cell

			# Place at least one shop template inside this layer.
			_place_shop_templates_in_current_layer(rng)

			# Layer 1 position: in the direction the exit faces (exit on top -> layer 1 above).
			if tile_map_layers.size() > 1:
				layer_positions[1] = layer_positions[0] + _dir_from_border_cell(exit_cell)
			continue

		_current_tile_map_layer.clear()

		# Fill grid with walls.
		for cy in grid_size.y:
			var wall_layer_for_row: TileMapLayerAdvanced = _get_wall_layer_for_row(cy)
			var wall_fallback_for_row: Dictionary = _get_any_tile_from_layer(wall_layer_for_row) if wall_layer_for_row else {}
			for cx in grid_size.x:
				_copy_cell_block(Vector2i(cx, cy), wall_layer_for_row, wall_fallback_for_row)

		if grid_size.x < 3 or grid_size.y < 3:
			continue

		# Start = cell on this layer that aligns with previous layer's end door (so doors connect when placed).
		var dir_to_this: Vector2i = layer_positions[layer_index] - layer_positions[layer_index - 1]
		var start_cell: Vector2i = _connecting_cell_on_next_layer(layer_end_cells[layer_index - 1], dir_to_this)
		if start_cell.x < 0 or start_cell.y < 0:
			start_cell = Vector2i(1, 1)
		var end_cell: Vector2i
		var border_cells: Array[Vector2i] = _get_border_cells()
		var used_pos: Dictionary = {}
		for k in range(layer_index + 1):
			used_pos[layer_positions[k]] = true
		if border_cells.size() < 2:
			end_cell = Vector2i(grid_size.x - 2, grid_size.y - 2)
		else:
			# Only consider border cells that would place the next layer in an unused spot (branch away, never back).
			var valid_cells: Array[Vector2i] = []
			for cell in border_cells:
				if cell == start_cell:
					continue
				var next_pos: Vector2i = layer_positions[layer_index] + _dir_from_border_cell(cell)
				if used_pos.has(next_pos):
					continue
				valid_cells.append(cell)
			var max_dist := -1
			var farthest: Array[Vector2i] = []
			var pool: Array[Vector2i] = valid_cells if valid_cells.size() > 0 else border_cells
			for cell in pool:
				if cell == start_cell:
					continue
				var dist: int = abs(cell.x - start_cell.x) + abs(cell.y - start_cell.y)
				if dist > max_dist:
					max_dist = dist
					farthest.clear()
					farthest.append(cell)
				elif dist == max_dist:
					farthest.append(cell)
			end_cell = farthest[rng.randi_range(0, farthest.size() - 1)] if farthest.size() > 0 else (pool[0] if pool.size() > 0 else border_cells[0])
		layer_start_cells[layer_index] = start_cell
		layer_end_cells[layer_index] = end_cell
		if layer_index + 1 < tile_map_layers.size():
			layer_positions[layer_index + 1] = layer_positions[layer_index] + _dir_from_border_cell(end_cell)

		var start_inner := _border_neighbor_inside(start_cell)
		var end_inner := _border_neighbor_inside(end_cell)

		var path_choice: Array = _get_random_path_layer_and_fallback(rng)
		_copy_cell_block(start_inner, path_choice[0], path_choice[1])
		path_choice = _get_random_path_layer_and_fallback(rng)
		_copy_cell_block(end_inner, path_choice[0], path_choice[1])

		# Full maze: DFS carve, connect end to maze, optional dungeon.
		var stack: Array[Vector2i] = [start_inner]
		var visited := {}
		visited[start_inner] = true

		var dtile: Dictionary = {}
		var dungeon_layer: TileMapLayerAdvanced = null
		if _current_tile_map_layer.maze_layer_group.tile_map_dungeons.size() > 0:
			dungeon_layer = _current_tile_map_layer.maze_layer_group.tile_map_dungeons[rng.randi_range(0, _current_tile_map_layer.maze_layer_group.tile_map_dungeons.size() - 1)]
			dtile = _get_any_tile_from_layer_used_cells(dungeon_layer)
			if dtile.is_empty():
				dtile = _get_any_tile_from_layer(dungeon_layer)
		if dtile.is_empty():
			dtile = _get_tile_from_main_layer_at_cell(start_inner)
		if dtile.is_empty() and _current_tile_map_layer.maze_layer_group.tile_map_walls.size() > 0:
			var _wall_layer: TileMapLayerAdvanced = _get_wall_layer_for_row(int(grid_size.y / 2.0))
			dtile = _get_any_tile_from_layer(_wall_layer)
		if dtile.is_empty() and _current_tile_map_layer.maze_layer_group.tile_map_walls.size() > 0:
			dtile = _get_tile_from_layer(_current_tile_map_layer.maze_layer_group.tile_map_walls[0], Vector2i(0, 0))
		var carved_count: int = 0
		var dungeon_target: int = 1
		var dungeon_cell_choice: Vector2i = Vector2i(-1, -1)

		var directions: Array[Vector2i] = [
			Vector2i(2, 0),
			Vector2i(-2, 0),
			Vector2i(0, 2),
			Vector2i(0, -2),
		]
		while stack.size() > 0:
			var current: Vector2i = stack[stack.size() - 1]
			var dirs: Array[Vector2i] = []
			dirs.append_array(directions)
			_shuffle_vec2i_in_place(dirs, rng)
			var carved := false
			for d: Vector2i in dirs:
				var next: Vector2i = current + d
				if not _is_inner_cell(next):
					continue
				if visited.has(next):
					continue
				var between: Vector2i = current + Vector2i(d.x >> 1, d.y >> 1)
				path_choice = _get_random_path_layer_and_fallback(rng)
				_copy_cell_block(between, path_choice[0], path_choice[1])
				path_choice = _get_random_path_layer_and_fallback(rng)
				_copy_cell_block(next, path_choice[0], path_choice[1])
				visited[next] = true
				stack.append(next)
				carved = true
				carved_count += 1
				if dungeon_cell_choice.x < 0 and carved_count >= dungeon_target and next != start_inner and next != end_inner:
					dungeon_cell_choice = next
				break
			if not carved:
				stack.pop_back()

		_connect_border_to_maze(end_inner, start_inner, rng, wall_source_id)

		if dungeon_cell_choice.x >= 0 and not dtile.is_empty():
			_copy_cell_block(dungeon_cell_choice, dungeon_layer, dtile)

		# Place start tile (entrance / spawn).
		var start_layer_or_path: TileMapLayerAdvanced = start_layer if start_layer else null
		var start_fallback: Dictionary = start_tile_fallback if not start_tile_fallback.is_empty() else {}
		if start_layer_or_path == null:
			path_choice = _get_random_path_layer_and_fallback(rng)
			start_layer_or_path = path_choice[0]
			start_fallback = path_choice[1]
		_copy_cell_block(start_cell, start_layer_or_path, start_fallback)

		# Place end door only if not the last level (connects to next layer).
		if not is_last:
			var end_layer_or_path: TileMapLayerAdvanced = end_layer if end_layer else null
			var end_fallback: Dictionary = end_tile_fallback if not end_tile_fallback.is_empty() else {}
			if end_layer_or_path == null:
				path_choice = _get_random_path_layer_and_fallback(rng)
				end_layer_or_path = path_choice[0]
				end_fallback = path_choice[1]
			_copy_cell_block(end_cell, end_layer_or_path, end_fallback)

		# Place at least one shop template inside this layer.
		_place_shop_templates_in_current_layer(rng)

		# First maze layer (index 1) is where the player enters from the first layer's end door.
		if layer_index == 1:
			first_start_tile = Vector2i(start_cell.x * cell_size, start_cell.y * cell_size)

		_apply_layer_positions()
	# After generation, parent the exported level's layer under the navigation region
	# so navigation can be generated/queried for that active layer immediately.
	set_navigation_active_layer(int(level) if level != null else 0)
	maze_generated.emit(first_start_tile)
	return first_start_tile

func _get_border_cells() -> Array[Vector2i]:
	var border: Array[Vector2i] = []
	for y in range(1, grid_size.y - 1):
		border.append(Vector2i(0, y))
	for y in range(1, grid_size.y - 1):
		border.append(Vector2i(grid_size.x - 1, y))
	for x in range(1, grid_size.x - 1):
		border.append(Vector2i(x, 0))
	for x in range(1, grid_size.x - 1):
		border.append(Vector2i(x, grid_size.y - 1))
	return border

## Direction to place the next layer from a border cell: top -> (0,-1), bottom -> (0,1), left -> (-1,0), right -> (1,0).
func _dir_from_border_cell(cell: Vector2i) -> Vector2i:
	if cell.y == 0:
		return Vector2i(0, -1)
	if cell.y == grid_size.y - 1:
		return Vector2i(0, 1)
	if cell.x == 0:
		return Vector2i(-1, 0)
	if cell.x == grid_size.x - 1:
		return Vector2i(1, 0)
	return Vector2i(0, 0)

## Cell on this layer that aligns with the previous layer's end door (so doors touch when layers are placed).
func _connecting_cell_on_next_layer(prev_end_cell: Vector2i, dir_to_this_layer: Vector2i) -> Vector2i:
	if dir_to_this_layer == Vector2i(0, -1):
		return Vector2i(prev_end_cell.x, grid_size.y - 1)
	if dir_to_this_layer == Vector2i(0, 1):
		return Vector2i(prev_end_cell.x, 0)
	if dir_to_this_layer == Vector2i(1, 0):
		return Vector2i(0, prev_end_cell.y)
	if dir_to_this_layer == Vector2i(-1, 0):
		return Vector2i(grid_size.x - 1, prev_end_cell.y)
	return prev_end_cell

func _carve_minimal_path(from_cell: Vector2i, to_cell: Vector2i, rng: RandomNumberGenerator) -> void:
	# Carve a simple L-shaped or direct path so the first level is just start + end door area.
	var path_choice: Array
	var cur := from_cell
	while cur != to_cell:
		path_choice = _get_random_path_layer_and_fallback(rng)
		_copy_cell_block(cur, path_choice[0], path_choice[1])
		if cur.x != to_cell.x:
			cur.x += 1 if to_cell.x > cur.x else -1
		elif cur.y != to_cell.y:
			cur.y += 1 if to_cell.y > cur.y else -1
	path_choice = _get_random_path_layer_and_fallback(rng)
	_copy_cell_block(to_cell, path_choice[0], path_choice[1])

func _get_wall_layer_for_row(cy: int) -> TileMapLayerAdvanced:
	# Index 0 = top third, 1 = middle, 2 = bottom third of grid.
	if _current_tile_map_layer.maze_layer_group.tile_map_walls.size() == 0:
		return null
	var third: int = int(grid_size.y / 3.0)
	if third <= 0:
		return _current_tile_map_layer.maze_layer_group.tile_map_walls[0]
	if cy < third:
		return _current_tile_map_layer.maze_layer_group.tile_map_walls[0]
	if cy < 2 * third:
		return _current_tile_map_layer.maze_layer_group.tile_map_walls[1] if _current_tile_map_layer.maze_layer_group.tile_map_walls.size() > 1 else _current_tile_map_layer.maze_layer_group.tile_map_walls[0]
	return _current_tile_map_layer.maze_layer_group.tile_map_walls[2] if _current_tile_map_layer.maze_layer_group.tile_map_walls.size() > 2 else (_current_tile_map_layer.maze_layer_group.tile_map_walls[1] if _current_tile_map_layer.maze_layer_group.tile_map_walls.size() > 1 else _current_tile_map_layer.maze_layer_group.tile_map_walls[0])

func _get_random_path_layer_and_fallback(rng: RandomNumberGenerator) -> Array:
	# Returns [layer, fallback_dict]. Each path cell can pick a random tile from _current_tile_map_layer.maze_layer_group.tile_map_paths.
	if _current_tile_map_layer.maze_layer_group.tile_map_paths.size() == 0:
		return [null, {}]
	var layer: TileMapLayerAdvanced = _current_tile_map_layer.maze_layer_group.tile_map_paths[rng.randi_range(0, _current_tile_map_layer.maze_layer_group.tile_map_paths.size() - 1)]
	var fallback: Dictionary = _get_any_tile_from_layer(layer) if layer else {}
	return [layer, fallback]

func _pick_random_border_cells(rng: RandomNumberGenerator) -> Array:
	# Returns [start_cell, end_cell]: start random on border, end chosen to be as far as possible from start.
	var border: Array[Vector2i] = []
	# Left edge (exclude corners)
	for y in range(1, grid_size.y - 1):
		border.append(Vector2i(0, y))
	# Right edge
	for y in range(1, grid_size.y - 1):
		border.append(Vector2i(grid_size.x - 1, y))
	# Top edge (exclude corners)
	for x in range(1, grid_size.x - 1):
		border.append(Vector2i(x, 0))
	# Bottom edge
	for x in range(1, grid_size.x - 1):
		border.append(Vector2i(x, grid_size.y - 1))
	if border.size() < 2:
		return [Vector2i(1, 1), Vector2i(grid_size.x - 2, grid_size.y - 2)]
	# Pick start at random.
	var start_cell: Vector2i = border[rng.randi_range(0, border.size() - 1)]
	# Find border cells that are farthest from start (Manhattan distance).
	var max_dist := -1
	var farthest: Array[Vector2i] = []
	for cell in border:
		if cell == start_cell:
			continue
		var d: int = abs(cell.x - start_cell.x) + abs(cell.y - start_cell.y)
		if d > max_dist:
			max_dist = d
			farthest.clear()
			farthest.append(cell)
		elif d == max_dist:
			farthest.append(cell)
	var end_cell: Vector2i = farthest[rng.randi_range(0, farthest.size() - 1)] if farthest.size() > 0 else border[0]
	return [start_cell, end_cell]

func _border_neighbor_inside(border_cell: Vector2i) -> Vector2i:
	# Returns the inner cell one step inside from the border.
	if border_cell.x == 0:
		return Vector2i(1, border_cell.y)
	if border_cell.x == grid_size.x - 1:
		return Vector2i(grid_size.x - 2, border_cell.y)
	if border_cell.y == 0:
		return Vector2i(border_cell.x, 1)
	return Vector2i(border_cell.x, grid_size.y - 2)

func _connect_border_to_maze(from_cell: Vector2i, seed_cell: Vector2i, rng: RandomNumberGenerator, wall_source_id: int) -> void:
	# If from_cell is not reachable from seed_cell, carve a corridor; each cell uses a random path from paths array.
	var reachable := _flood_fill_walkable(seed_cell, wall_source_id)
	if reachable.has(from_cell):
		return
	var cur := from_cell
	for _i in range(grid_size.x + grid_size.y):
		# Step one cell toward seed_cell (axis-aligned: prefer x then y).
		if cur.x < seed_cell.x:
			cur.x += 1
		elif cur.x > seed_cell.x:
			cur.x -= 1
		elif cur.y < seed_cell.y:
			cur.y += 1
		elif cur.y > seed_cell.y:
			cur.y -= 1
		else:
			break
		if cur.x < 1 or cur.y < 1 or cur.x > grid_size.x - 2 or cur.y > grid_size.y - 2:
			break
		var path_choice: Array = _get_random_path_layer_and_fallback(rng)
		_copy_cell_block(cur, path_choice[0], path_choice[1])
		if reachable.has(cur):
			break

func _flood_fill_walkable(from_cell: Vector2i, wall_source_id: int) -> Dictionary:
	var result := {}
	var queue: Array[Vector2i] = [from_cell]
	result[from_cell] = true
	var step_dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	while queue.size() > 0:
		var c: Vector2i = queue.pop_front()
		for sd: Vector2i in step_dirs:
			var nc: Vector2i = c + sd
			if nc.x < 1 or nc.y < 1 or nc.x > grid_size.x - 2 or nc.y > grid_size.y - 2:
				continue
			if result.has(nc):
				continue
			var tile_pos := Vector2i(nc.x * cell_size, nc.y * cell_size) + _current_layer_map_offset
			var sid: int = _current_tile_map_layer.get_cell_source_id(tile_pos)
			if sid == -1 or sid == wall_source_id:
				continue
			result[nc] = true
			queue.append(nc)
	return result

func _clamp_to_odd_range(min_val: int, max_val: int, preferred: int) -> int:
	var p := clampi(preferred, min_val, max_val)
	if (p & 1) == 1:
		return p
	if p - 1 >= min_val:
		return p - 1
	return min(p + 1, max_val)

func _is_inner_cell(p: Vector2i) -> bool:
	# Inner cells exclude the outermost border ring.
	# For a grid WxH, valid interior coordinates are:
	# x in [1, W-2], y in [1, H-2]
	return p.x >= 1 and p.y >= 1 and p.x <= grid_size.x - 2 and p.y <= grid_size.y - 2

func _shuffle_vec2i_in_place(a: Array[Vector2i], rng: RandomNumberGenerator) -> void:
	# Fisher-Yates shuffle to randomize direction order.
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp: Vector2i = a[i]
		a[i] = a[j]
		a[j] = tmp

func _random_inner_odd_cell(rng: RandomNumberGenerator) -> Vector2i:
	# Pick a random "cell node" on odd coordinates inside the inner bounds.
	# Inner bounds are x in [1, W-2], y in [1, H-2].
	# We clamp to odd by snapping even picks down by 1 (still inside bounds).
	var min_x := 1
	var max_x := grid_size.x - 2
	var min_y := 1
	var max_y := grid_size.y - 2

	# If something is misconfigured and there is no interior, fall back safely.
	if max_x < min_x or max_y < min_y:
		return Vector2i(1, 1)

	var x := rng.randi_range(min_x, max_x)
	var y := rng.randi_range(min_y, max_y)

	# Snap to odd coordinates.
	if (x & 1) == 0:
		x = max(min_x, x - 1)
	if (y & 1) == 0:
		y = max(min_y, y - 1)

	# If snapping produced an even coordinate at the minimum (e.g. min_x==1 is odd so ok),
	# or if bounds are very tight, ensure we still end up odd and inside.
	if (x & 1) == 0:
		x = min(max_x, x + 1)
	if (y & 1) == 0:
		y = min(max_y, y + 1)

	return Vector2i(x, y)

func _find_farthest_walkable_cell(from_cell: Vector2i, wall_source_id: int) -> Vector2i:
	# BFS over cells; a cell is walkable if its top-left tile is not a wall.
	var queue: Array[Vector2i] = [from_cell]
	var dist := {}
	dist[from_cell] = 0
	var farthest := from_cell
	var farthest_d := 0
	var step_dirs: Array[Vector2i] = [
		Vector2i(1, 0),
		Vector2i(-1, 0),
		Vector2i(0, 1),
		Vector2i(0, -1),
	]
	while queue.size() > 0:
		var c: Vector2i = queue.pop_front()
		var d: int = dist[c]
		if d > farthest_d:
			farthest_d = d
			farthest = c
		for sd: Vector2i in step_dirs:
			var nc: Vector2i = c + sd
			if nc.x < 0 or nc.y < 0 or nc.x >= grid_size.x or nc.y >= grid_size.y:
				continue
			if dist.has(nc):
				continue
			var tile_pos := Vector2i(nc.x * cell_size, nc.y * cell_size) + _current_layer_map_offset
			var sid: int = _current_tile_map_layer.get_cell_source_id(tile_pos)
			if sid == -1 or sid == wall_source_id:
				continue
			dist[nc] = d + 1
			queue.append(nc)
	return farthest
