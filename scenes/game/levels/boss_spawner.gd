class_name BossSpawner extends Node2D

@export var boss_name: String = ""
@export var group_name: String = "enemy"
## If negative, uses the index passed with [signal Level.dungeon_entered].
@export var dungeon_index: int = -1

var level: Level

func _ready() -> void:
	level = get_tree().root.get_node("Overworld") as Level
	if level:
		level.dungeon_entered.connect(_on_dungeon_entered)


func _on_dungeon_entered(entered_index: int) -> void:
	if boss_name.is_empty():
		return
	if not level or not level.build_dungeon:
		return

	var idx: int = dungeon_index
	if idx < 0:
		idx = entered_index

	var global_pos: Vector2 = level.build_dungeon.get_boss_room_spawn_global_position(idx)
	var pos_in_level: Vector2 = level.to_local(global_pos)
	SpawnManager.spawn(boss_name, pos_in_level, level, group_name)
