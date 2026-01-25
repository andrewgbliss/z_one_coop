class_name GameUtils extends Node

static var grid_size: int = 16

static func snap_to_grid(pos: Vector2) -> Vector2:
	var current_pos = pos
	var snapped_pos = Vector2(
		round(current_pos.x / grid_size) * grid_size,
		round(current_pos.y / grid_size) * grid_size
	)
	return snapped_pos

static func set_transparent_window():
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_TRANSPARENT, true)

static func get_bottom_right_position(window: Window) -> Vector2:
	var screen_size = DisplayServer.screen_get_size()
	var window_size = window.size
	return Vector2(screen_size.x - window_size.x, screen_size.y - window_size.y)

static func set_window_position(pos: Vector2):
	DisplayServer.window_set_position(pos)
