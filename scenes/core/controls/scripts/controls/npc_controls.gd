class_name NpcControls extends CharacterControls

var device_index
var move_right
var move_left
var move_up
var move_down
var aim_right
var aim_left
var aim_up
var aim_down
var double_tap
var dash
var run
var trigger_left
var trigger_right
var bumper_left
var bumper_right

var buttons_pressed = {}
var buttons_just_pressed = {}

func _ready():
	super ()
	device_index = "0"
	move_right = "move_right_" + device_index
	move_left = "move_left_" + device_index
	move_down = "move_down_" + device_index
	move_up = "move_up_" + device_index
	aim_right = "aim_right_" + device_index
	aim_left = "aim_left_" + device_index
	aim_down = "aim_down_" + device_index
	aim_up = "aim_up_" + device_index
	double_tap = "double_tap_" + device_index
	dash = "dash_" + device_index
	run = "run_" + device_index
	trigger_left = "trigger_left_" + device_index
	trigger_right = "trigger_right_" + device_index
	bumper_left = "bumper_left_" + device_index
	bumper_right = "bumper_right_" + device_index

	buttons_pressed = {
		move_right: false,
		move_left: false,
		move_down: false,
		move_up: false,
		aim_right: false,
		aim_left: false,
		aim_down: false,
		aim_up: false,
		double_tap: false,
		dash: false,
		run: false,
		trigger_left: false,
		trigger_right: false,
		bumper_left: false,
		bumper_right: false,
	}
	buttons_just_pressed = {
		move_right: false,
		move_left: false,
		move_down: false,
		move_up: false,
		aim_right: false,
		aim_left: false,
		aim_down: false,
		aim_up: false,
		double_tap: false,
		dash: false,
		run: false,
		trigger_left: false,
		trigger_right: false,
		bumper_left: false,
		bumper_right: false,
	}
	
func get_movement_direction():
	return target_movement_direction

func get_aim_direction():
	return target_aim_direction

func is_running() -> bool:
	return is_action_pressed(run) and get_movement_direction() != Vector2.ZERO

func is_action_just_pressed(action_name) -> bool:
	return buttons_just_pressed[action_name]

func is_action_pressed(action_name) -> bool:
	return buttons_pressed[action_name]
