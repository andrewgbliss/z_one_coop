@tool
class_name TileMapLayerAdvanced extends TileMapLayer

enum TerrainType {
	BASE,
  WATER,
  DIRT,
  SAND,
  GRASS,
  PLAINS,
  MOUNTAINS,
  SNOW,
  PLATFORM,
  BACKGROUND
}

@export var generate_on_ready: bool = false
@export var default_terrain_type: TerrainType = TerrainType.GRASS
@export var terrain_name: String = "grass"
@export var generation_width: int = 100
@export var generation_height: int = 100

@export var maze_layer_group: MazeLayerGroup

@export_group("Generation Bounds")
@export var min_offset: Vector2i = Vector2i(0, 0)
@export var max_offset: Vector2i = Vector2i(0, 0)

@export_group("Overlap Control")
@export var avoid_overlap_layers: Array[TileMapLayerAdvanced] = []

@export_group("Environmental Noise")
@export_range(0.0, 1.0) var temperature: float = 0.6
@export_range(0.0, 1.0) var moisture: float = 0.7
@export_range(0.0, 1.0) var altitude: float = 0.4
@export var noise: FastNoiseLite

@export_group("Breakable")
@export var is_breakable: bool = false
@export var custom_data_name: String = "hp"

var cell_hp_dict: Dictionary = {}

var cell_temperature_dict: Dictionary = {}
var cell_moisture_dict: Dictionary = {}
var cell_altitude_dict: Dictionary = {}

@export_group("Actions")
@export_tool_button("Generate Noise from Terrain Type", "Callable") var generate_noise_action = generate_noise_from_terrain_type
@export_tool_button("Generate Terrain Now", "Callable") var generate_terrain_action = generate_terrain_now
@export_tool_button("Generate Solid Terrain", "Callable") var generate_solid_action = generate_solid_terrain
@export_tool_button("Clear Terrain", "Callable") var clear_terrain_action = clear_terrain

func generate_noise_from_terrain_type():
	print("Generating noise configuration for terrain type: ", terrain_name)
	
	match default_terrain_type:
		TerrainType.WATER:
			# Water needs low altitude, medium temperature, variable moisture
			temperature = 0.5
			moisture = 0.5
			altitude = 0.2
			noise = FastNoiseLite.new()
			noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
			noise.frequency = 0.02
			noise.seed = randi()
			
		TerrainType.SAND:
			# Desert needs low moisture, high temperature, varied altitude
			temperature = 0.8
			moisture = 0.2
			altitude = 0.5
			noise = FastNoiseLite.new()
			noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
			noise.frequency = 0.015
			noise.seed = randi()
			
		TerrainType.GRASS:
			# Grass needs moderate moisture, moderate temperature, low altitude
			temperature = 0.6
			moisture = 0.7
			altitude = 0.4
			noise = FastNoiseLite.new()
			noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
			noise.frequency = 0.025
			noise.seed = randi()
			
		TerrainType.PLAINS:
			# Plains need moderate conditions all around
			temperature = 0.5
			moisture = 0.6
			altitude = 0.4
			noise = FastNoiseLite.new()
			noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
			noise.frequency = 0.018
			noise.seed = randi()
			
		TerrainType.MOUNTAINS:
			# Mountains need high altitude with dramatic changes
			temperature = 0.4
			moisture = 0.5
			altitude = 0.8
			noise = FastNoiseLite.new()
			noise.noise_type = FastNoiseLite.TYPE_PERLIN
			noise.frequency = 0.008
			noise.fractal_octaves = 4
			noise.seed = randi()
			
		TerrainType.SNOW:
			# Snow needs low temperature, high altitude
			temperature = 0.2
			moisture = 0.5
			altitude = 0.9
			noise = FastNoiseLite.new()
			noise.noise_type = FastNoiseLite.TYPE_PERLIN
			noise.frequency = 0.01
			noise.fractal_octaves = 3
			noise.seed = randi()
			
		TerrainType.DIRT:
			# Ground is a general terrain with balanced settings
			temperature = 0.5
			moisture = 0.5
			altitude = 0.5
			noise = FastNoiseLite.new()
			noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
			noise.frequency = 0.02
			noise.seed = randi()
			
		TerrainType.PLATFORM, TerrainType.BACKGROUND:
			# Platform and background use simple noise patterns
			temperature = 0.5
			moisture = 0.5
			altitude = 0.5
			noise = FastNoiseLite.new()
			noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
			noise.frequency = 0.03
			noise.seed = randi()
	
	print("Noise configuration generated successfully!")
	print("  Temperature: ", temperature)
	print("  Moisture: ", moisture)
	print("  Altitude: ", altitude)
	print("  Noise frequency: ", str(noise.frequency) if noise else "none")

func reset_seed():
	if noise:
		noise.seed = randi()

func _get_generation_bounds(width: int, height: int) -> Rect2i:
	var min_off := min_offset
	var max_off := max_offset

	var start := Vector2i(
		clamp(min_off.x, 0, width),
		clamp(min_off.y, 0, height)
	)
	var end := Vector2i(
		clamp(width - max_off.x, 0, width),
		clamp(height - max_off.y, 0, height)
	)

	# Ensure non-negative size even if offsets overlap
	var size := Vector2i(
		max(0, end.x - start.x),
		max(0, end.y - start.y)
	)
	return Rect2i(start, size)

func generate_terrain_now():
	print("Generating terrain in editor...")
	reset_seed()
	clear()
	cell_temperature_dict.clear()
	cell_moisture_dict.clear()
	cell_altitude_dict.clear()
	cell_hp_dict.clear()
	generate_terrain_by_type_auto(generation_width, generation_height, default_terrain_type)

func generate_solid_terrain():
	print("Generating solid terrain...")
	clear()
	generate_terrain_by_type_solid(generation_width, generation_height, default_terrain_type)

func clear_terrain():
	print("Clearing terrain...")
	# Only clear inside the generation-bounds area
	var bounds := _get_generation_bounds(generation_width, generation_height)
	var positions: Array[Vector2i] = []
	for x in range(bounds.position.x, bounds.position.x + bounds.size.x):
		for y in range(bounds.position.y, bounds.position.y + bounds.size.y):
			var cell_coords := Vector2i(x, y)
			positions.append(cell_coords)
			
			if cell_temperature_dict.has(cell_coords):
				cell_temperature_dict.erase(cell_coords)
			if cell_moisture_dict.has(cell_coords):
				cell_moisture_dict.erase(cell_coords)
			if cell_altitude_dict.has(cell_coords):
				cell_altitude_dict.erase(cell_coords)
			if cell_hp_dict.has(cell_coords):
				cell_hp_dict.erase(cell_coords)
	
	# Clear terrain in bulk (terrain_id = -1 means "no terrain")
	if positions.size() > 0:
		set_cells_terrain_connect(positions, 0, -1, false)

func _ready():
	if generate_on_ready and not Engine.is_editor_hint():
		generate_terrain_by_type_auto(generation_width, generation_height, default_terrain_type)

func handle_collision(collision: KinematicCollision2D, blast_radius: float):
	if is_breakable:
		var collision_position = collision.get_position()
		var local_position = to_local(collision_position)
		var center_coords = local_to_map(local_position)

		# Calculate how many tiles to check based on blast radius
		var tile_size = tile_set.tile_size
		var radius_in_tiles = ceil(blast_radius / tile_size.x)

		# Check all tiles within the blast radius
		for x in range(-radius_in_tiles, radius_in_tiles + 1):
			for y in range(-radius_in_tiles, radius_in_tiles + 1):
				var check_coords = center_coords + Vector2i(x, y)

				# Check if this tile is within the circular blast radius
				var tile_world_pos = map_to_local(check_coords)
				var distance = collision_position.distance_to(to_global(tile_world_pos))

				if distance <= blast_radius:
					var cell_data = get_cell_tile_data(check_coords)
					if cell_data:
						var default_hp = cell_data.get_custom_data(custom_data_name)

						# If coord doesn't exist in dictionary, initialize with default HP from custom_data
						if not cell_hp_dict.has(check_coords):
							if default_hp:
								cell_hp_dict[check_coords] = default_hp

						# If coord exists in dictionary, decrement HP
						if cell_hp_dict.has(check_coords):
							cell_hp_dict[check_coords] -= 1

						if default_hp:
							if cell_data.material:
								var current_hp = cell_hp_dict[check_coords]
								var break_progress: float = float(current_hp) / float(default_hp)
								apply_break_to_tile(collision_position, cell_data, break_progress)

						if cell_hp_dict[check_coords] <= 0:
							erase_cell(check_coords)
							cell_hp_dict.erase(check_coords)

func apply_break_to_tile(tile_position: Vector2, cell_data, break_progress):
	var viewport_size = get_viewport().get_visible_rect().size
	var tile_size = Vector2(16, 16) # Adjust to your tile size

	# Convert tile position to screen coordinates
	var screen_pos = tile_position # If tile_position is already in screen space

	# Convert to normalized UV (0.0 to 1.0)
	var screen_min = screen_pos / viewport_size
	var screen_max = (screen_pos + tile_size) / viewport_size

	# Apply to the tilemap's material
	cell_data.material.set_shader_parameter("target_screen_min", screen_min)
	cell_data.material.set_shader_parameter("target_screen_max", screen_max)
	cell_data.material.set_shader_parameter("break_progress", break_progress)

# Check if a cell is occupied in any avoid-overlap layer
func _is_cell_occupied_in_avoid_layers(cell_coords: Vector2i) -> bool:
	for layer in avoid_overlap_layers:
		if layer and layer.get_cell_source_id(cell_coords) != -1:
			return true
	return false

# Generate environmental values for a specific cell position
func generate_cell_environment(cell_coords: Vector2i):
	var world_pos = map_to_local(cell_coords)

	# Scale coordinates for better noise patterns
	var scaled_x = world_pos.x * 0.1
	var scaled_y = world_pos.y * 0.1

	var noise_value = noise.get_noise_2d(scaled_x, scaled_y) * 0.5 if noise else 0.0
	cell_temperature_dict[cell_coords] = clamp(temperature + noise_value, 0.0, 1.0)
	cell_moisture_dict[cell_coords] = clamp(moisture + noise_value, 0.0, 1.0)
	cell_altitude_dict[cell_coords] = clamp(altitude + noise_value, 0.0, 1.0)

# Generate environmental values for all cells in use
func generate_all_cell_environments():
	for cell_coords in get_used_cells():
		generate_cell_environment(cell_coords)

# Get temperature value for a cell (-1.0 to 1.0)
func get_cell_temperature(cell_coords: Vector2i) -> float:
	if not cell_temperature_dict.has(cell_coords):
		generate_cell_environment(cell_coords)
	return cell_temperature_dict.get(cell_coords, 0.0)

# Get moisture value for a cell (-1.0 to 1.0)
func get_cell_moisture(cell_coords: Vector2i) -> float:
	if not cell_moisture_dict.has(cell_coords):
		generate_cell_environment(cell_coords)
	return cell_moisture_dict.get(cell_coords, 0.0)

# Get altitude value for a cell (-1.0 to 1.0)
func get_cell_altitude(cell_coords: Vector2i) -> float:
	if not cell_altitude_dict.has(cell_coords):
		generate_cell_environment(cell_coords)
	return cell_altitude_dict.get(cell_coords, 0.0)

# Set environmental values manually for a specific cell
func set_cell_environment(cell_coords: Vector2i, temp: float, moist: float, alt: float):
	cell_temperature_dict[cell_coords] = temp
	cell_moisture_dict[cell_coords] = moist
	cell_altitude_dict[cell_coords] = alt

# Get all environmental values for a cell as a dictionary
func get_cell_environment(cell_coords: Vector2i) -> Dictionary:
	return {
		"temperature": get_cell_temperature(cell_coords),
		"moisture": get_cell_moisture(cell_coords),
		"altitude": get_cell_altitude(cell_coords)
	}

func find_terrain_ids(ter_name: String) -> Dictionary:
	if not tile_set:
		push_error("TileMapLayerAdvanced: No tileset assigned")
		return {"set_id": - 1, "terrain_id": - 1}
	
	# Search through all terrain sets to find matching name
	for terrain_set_id in range(tile_set.get_terrain_sets_count()):
		for terrain_id in range(tile_set.get_terrains_count(terrain_set_id)):
			var found_terrain_name = tile_set.get_terrain_name(terrain_set_id, terrain_id)
			
			# Match terrain names (case insensitive)
			if found_terrain_name.to_lower().contains(ter_name.to_lower()):
				return {"set_id": terrain_set_id, "terrain_id": terrain_id}
	
	push_warning("TileMapLayerAdvanced: Could not find terrain named '%s' in tileset" % ter_name)
	return {"set_id": - 1, "terrain_id": - 1}

# Get the condition function for a specific terrain type
func get_terrain_condition(terrain_type: TerrainType) -> Callable:
	match terrain_type:
		TerrainType.BASE:
			return func(_temp, _moist, _alt): return true
		TerrainType.WATER:
			return func(_temp, _moist, alt): return alt < 0.35
		TerrainType.DIRT:
			return func(_temp, _moist, alt): return alt >= 0.35 and alt <= 0.65
		TerrainType.SAND:
			return func(temp, moist, alt): return moist < 0.35 and temp > 0.65 and alt >= 0.35 and alt <= 0.8
		TerrainType.GRASS:
			return func(temp, moist, alt): return moist > 0.65 and temp > 0.55 and alt >= 0.35 and alt <= 0.8
		TerrainType.PLAINS:
			return func(temp, moist, alt): return moist > 0.55 and temp > 0.4 and alt >= 0.35 and alt <= 0.8
		TerrainType.MOUNTAINS:
			return func(_temp, _moist, alt): return alt > 0.65
		TerrainType.SNOW:
			return func(temp, _moist, alt): return alt > 0.8 and temp < 0.4
		TerrainType.PLATFORM:
			return func(_temp, _moist, alt): return alt > 0.65
		TerrainType.BACKGROUND:
			return func(_temp, _moist, _alt): return true
		_:
			return func(_temp, _moist, _alt): return false

# Generate terrain for the entire region without noise
func generate_terrain(width: int, height: int, _terrain_set_id: int, _terrain_id: int):
	var bounds := _get_generation_bounds(width, height)
	for x in range(bounds.position.x, bounds.position.x + bounds.size.x):
		for y in range(bounds.position.y, bounds.position.y + bounds.size.y):
			set_cell(Vector2i(x, y), 0, Vector2i(0, 0), 0)

# Generate terrain for a region based on environmental conditions
# Similar to WorldGenerator's logic
func generate_terrain_from_environment(width: int, height: int, terrain_set_id: int, terrain_id: int, condition_func: Callable):
	var positions: Array[Vector2i] = []

	var bounds := _get_generation_bounds(width, height)
	for x in range(bounds.position.x, bounds.position.x + bounds.size.x):
		for y in range(bounds.position.y, bounds.position.y + bounds.size.y):
			var cell_coords = Vector2i(x, y)

			# Skip cells that are already occupied on any overlap-avoidance layer
			if _is_cell_occupied_in_avoid_layers(cell_coords):
				continue

			# Generate environmental values
			generate_cell_environment(cell_coords)

			var temp = get_cell_temperature(cell_coords)
			var moist = get_cell_moisture(cell_coords)
			var alt = get_cell_altitude(cell_coords)

			# Use the condition function to determine if this cell should get terrain
			if condition_func.call(temp, moist, alt):
				positions.append(cell_coords)

	# Place terrain tiles
	if positions.size() > 0:
		set_cells_terrain_connect(positions, terrain_set_id, terrain_id, false)

# Generate a completely solid area of the given terrain (no noise / thresholds)
func generate_terrain_solid_fill(width: int, height: int, terrain_set_id: int, terrain_id: int):
	var positions: Array[Vector2i] = []
	var bounds := _get_generation_bounds(width, height)
	for x in range(bounds.position.x, bounds.position.x + bounds.size.x):
		for y in range(bounds.position.y, bounds.position.y + bounds.size.y):
			var cell_coords := Vector2i(x, y)
			# Skip cells that are already occupied on any overlap-avoidance layer
			if _is_cell_occupied_in_avoid_layers(cell_coords):
				continue
			positions.append(cell_coords)
	if positions.size() > 0:
		set_cells_terrain_connect(positions, terrain_set_id, terrain_id, false)

# Convenience function to generate terrain using TerrainType enum
func generate_terrain_by_type(width: int, height: int, terrain_set_id: int, terrain_id: int, terrain_type: TerrainType):
	print("Generating terrain")
	var condition_func := get_terrain_condition(terrain_type)
	generate_terrain_from_environment(width, height, terrain_set_id, terrain_id, condition_func)

# Automatically find terrain IDs and generate terrain
func generate_terrain_by_type_auto(width: int, height: int, terrain_type: TerrainType):
	var terrain_info = find_terrain_ids(terrain_name)
		
	if terrain_info["set_id"] == -1 or terrain_info["terrain_id"] == -1:
		push_error("TileMapLayerAdvanced: Failed to find terrain IDs for '%s'" % terrain_name)
		return
	
	generate_terrain_by_type(width, height, terrain_info["set_id"], terrain_info["terrain_id"], terrain_type)

func generate_terrain_by_type_solid(width: int, height: int, _terrain_type: TerrainType):
	var terrain_info = find_terrain_ids(terrain_name)
		
	if terrain_info["set_id"] == -1 or terrain_info["terrain_id"] == -1:
		push_error("TileMapLayerAdvanced: Failed to find terrain IDs for '%s'" % terrain_name)
		return
	
	generate_terrain_solid_fill(width, height, terrain_info["set_id"], terrain_info["terrain_id"])
