class_name DungeonDoor extends Node2D

enum DungeonDoorType {
  UP,
  DOWN,
  LEFT,
  RIGHT
}

@export var dungeon_door_type: DungeonDoorType = DungeonDoorType.UP

func _ready() -> void:
  pass
