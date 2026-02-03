class_name Door extends Node2D

@onready var area: Area2D = $Area2D

@export var player_one_door_to: Door
@export var player_one_door_spawn_position: Node2D
@export var player_two_door_to: Door
@export var player_two_door_spawn_position: Node2D
@export var change_camera_area: Area2D
@export var level: Level

func _ready() -> void:
	area.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterController:
		if body.device_index == 0:
			body.global_position = player_one_door_to.player_one_door_spawn_position.global_position
		elif body.device_index == 1:
			body.global_position = player_two_door_to.player_two_door_spawn_position.global_position
		if change_camera_area:
			level.change_camera_area(change_camera_area)
