class_name Door extends Node2D

@onready var area: Area2D = $Area2D

enum DoorType {
	CAVE,
	OVERWORLD
}

@export var door_type: DoorType = DoorType.OVERWORLD

var level: Level

func _ready() -> void:
	level = get_tree().root.get_node("Overworld")
	area.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterController:
		if door_type == DoorType.OVERWORLD:
			SpawnManager.free_group("enemy")
			level.teleport_to_cave(global_position)
		elif door_type == DoorType.CAVE:
			level.teleport_back_to_pos()
