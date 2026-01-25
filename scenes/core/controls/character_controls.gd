class_name CharacterControls extends CharacterBaseNode
		
enum INPUT_TYPE {DEFAULT, MOUSE, TOUCH, JOYSTICK}

@export var move_type: INPUT_TYPE = INPUT_TYPE.DEFAULT
@export var aim_type: INPUT_TYPE = INPUT_TYPE.DEFAULT
@export var trigger_type: INPUT_TYPE = INPUT_TYPE.DEFAULT

var target
var target_movement_direction: Vector2 = Vector2.ZERO
var target_aim_direction: Vector2 = Vector2.ZERO

func get_movement_direction():
	return Vector2.ZERO

func get_aim_direction():
	return Vector2.ZERO

func is_running() -> bool:
	return false
