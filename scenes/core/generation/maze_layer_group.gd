class_name MazeLayerGroup extends Node2D

@export var tile_map_walls: Array[TileMapLayerAdvanced] = []
@export var tile_map_paths: Array[TileMapLayerAdvanced] = []
@export var tile_map_dungeons: Array[TileMapLayerAdvanced] = []
@export var tile_map_start: Array[TileMapLayerAdvanced] = []
@export var tile_map_end: Array[TileMapLayerAdvanced] = []
# Template tilemap layers used to place shop rooms/doors.
# MazeBuilder will place at least one shop per generated maze layer when configured.
@export var tile_map_shop: Array[TileMapLayerAdvanced] = []