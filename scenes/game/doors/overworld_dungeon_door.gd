class_name OverworldDungeonDoor extends Node2D

@onready var area: Area2D = $Area2D

enum DoorType {
	DUNGEON,
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
			var dungeon_idx: int = 0
			if body.blackboard:
				dungeon_idx = body.blackboard.level
			level.teleport_to_dungeon(global_position, dungeon_idx)
		elif door_type == DoorType.DUNGEON:
			level.teleport_back_to_pos()
