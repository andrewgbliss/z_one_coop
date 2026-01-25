class_name DebugAimSprite extends Sprite2D

@export var player: CharacterController

func _process(_delta: float) -> void:
	_update_aim_sprite()

func _update_aim_sprite():
	global_position = player.global_position + player.controls.get_aim_direction() * 50
