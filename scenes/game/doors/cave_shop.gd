class_name CaveShop extends Node2D

@export var door_one: Door
@export var door_two: Door
@export var camera_area: CameraArea2D

var level: Level

func _ready() -> void:
	level = get_tree().root.get_node("Overworld")
	door_one.area.body_entered.connect(_on_door_one_body_entered)
	door_two.area.body_entered.connect(_on_door_two_body_entered)

func _on_door_one_body_entered(body: Node2D) -> void:
	if body is CharacterController:
		#level.teleport_back_to_pos()
		pass

func _on_door_two_body_entered(body: Node2D) -> void:
	if body is CharacterController:
		#level.teleport_back_to_pos()
		pass
