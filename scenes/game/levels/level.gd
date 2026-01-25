class_name Level extends Node2D

@export var player_spawner: Node2D

func _ready() -> void:
	SpawnManager.spawn("link", player_spawner.global_position, self)
