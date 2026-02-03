class_name PlayerControls extends CharacterControls

@export var mouse_cursor: Texture2D
@export var touch_sprite: Sprite2D

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

enum DOUBLE_TAP_DIRECTION {NONE, LEFT, RIGHT, UP, DOWN}
var double_tap_direction = DOUBLE_TAP_DIRECTION.NONE
var double_tap_timer: Timer = null
var double_tap_time: float = 0.3
var double_tap_count: int = 0
var touch_position: Vector2 = Vector2.ZERO
var is_touching: bool = false
var last_pressed_movement: String = ""
var last_movement_direction: Vector2 = Vector2.ZERO
var last_aim_direction: Vector2 = Vector2.RIGHT

func _ready():
	super ()
	_detect_input_method()
	set_device_index(parent.device_index)
	if mouse_cursor:
		Input.set_custom_mouse_cursor(mouse_cursor, Input.CURSOR_ARROW, Vector2(16, 16))
		
	double_tap_timer = Timer.new()
	double_tap_timer.one_shot = true
	double_tap_timer.wait_time = double_tap_time
	double_tap_timer.connect("timeout", _on_double_tap_timeout)
	add_child(double_tap_timer)
	
	touch_sprite.hide()
	
func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_setup_mobile()
	elif event is InputEventJoypadMotion:
		_setup_joystick()

	if event is InputEventScreenTouch and event.double_tap:
		touch_position = to_world_position(event.position)
		simulate_button_press(double_tap)
	elif event is InputEventScreenDrag:
		touch_position = to_world_position(event.position)
		if touch_sprite != null:
			touch_sprite.global_position = touch_position
			touch_sprite.show()
		is_touching = true
	elif event is InputEventScreenTouch and event.pressed:
		touch_position = to_world_position(event.position)
		if touch_sprite != null:
			touch_sprite.global_position = touch_position
			touch_sprite.show()
		is_touching = true
	elif event is InputEventScreenTouch and not event.pressed:
		touch_position = Vector2.ZERO
		if touch_sprite != null:
			touch_sprite.hide()
			touch_sprite.global_position = touch_position
		is_touching = false
		
func _process(_delta: float) -> void:
	_double_tap()
	_touch_trigger_left()

func set_device_index(index: int):
	device_index = str(index)
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

func _touch_trigger_left():
	if trigger_type == INPUT_TYPE.TOUCH and is_touching:
		simulate_button_press(trigger_left)
		
func _on_double_tap_timeout():
	double_tap_count = 0

func get_double_tap_direction():
	match double_tap_direction:
		DOUBLE_TAP_DIRECTION.LEFT:
			return Vector2.LEFT
		DOUBLE_TAP_DIRECTION.RIGHT:
			return Vector2.RIGHT
		DOUBLE_TAP_DIRECTION.UP:
			return Vector2.UP
		DOUBLE_TAP_DIRECTION.DOWN:
			return Vector2.DOWN

func get_movement_direction():
	match move_type:
		INPUT_TYPE.MOUSE:
			last_movement_direction = get_mouse_movement_direction()
		INPUT_TYPE.TOUCH:
			last_movement_direction = get_touch_movement_direction()
		INPUT_TYPE.JOYSTICK:
			last_movement_direction = get_joystick_movement_direction()
		_:
			last_movement_direction = get_joystick_movement_direction()
	return last_movement_direction
	
func get_aim_direction():
	match aim_type:
		INPUT_TYPE.MOUSE:
			last_aim_direction = get_mouse_aim_direction()
		INPUT_TYPE.TOUCH:
			last_aim_direction = get_touch_aim_direction()
		INPUT_TYPE.JOYSTICK:
			last_aim_direction = get_joystick_aim_direction()
		_:
			last_aim_direction = get_joystick_movement_direction()
	return last_aim_direction
	
func get_mouse_movement_direction():
	if is_action_pressed("mouse_left"):
		return get_mouse_aim_direction()
	return Vector2.ZERO
	
func get_mouse_aim_direction():
	var direction = parent.get_global_mouse_position() - parent.global_position
	return direction.normalized()
	
func get_touch_movement_direction():
	if is_touching:
		return get_touch_aim_direction()
	return Vector2.ZERO
	
func get_touch_aim_direction():
	if touch_position == Vector2.ZERO:
		return last_aim_direction
	var direction = touch_position - parent.global_position
	return direction.normalized()

func get_joystick_movement_direction():
	return Vector2(
		Input.get_action_strength(move_right) - Input.get_action_strength(move_left),
		Input.get_action_strength(move_down) - Input.get_action_strength(move_up)
	)

func get_joystick_aim_direction():
	var direction: Vector2 = Vector2(
		Input.get_action_strength(aim_right) - Input.get_action_strength(aim_left),
		Input.get_action_strength(aim_down) - Input.get_action_strength(aim_up)
	)
	if direction.length() < 0.1:
		return last_aim_direction
	return direction

func _double_tap():
	var current_movement = ""
	if is_action_just_pressed(move_left):
		current_movement = "move_left"
	elif is_action_just_pressed(move_right):
		current_movement = "move_right"
	elif is_action_just_pressed(move_up):
		current_movement = "move_up"
	elif is_action_just_pressed(move_down):
		current_movement = "move_down"
		
	if current_movement != "":
		match current_movement:
			"move_left":
				double_tap_direction = DOUBLE_TAP_DIRECTION.LEFT
			"move_right":
				double_tap_direction = DOUBLE_TAP_DIRECTION.RIGHT
			"move_up":
				double_tap_direction = DOUBLE_TAP_DIRECTION.UP
			"move_down":
				double_tap_direction = DOUBLE_TAP_DIRECTION.DOWN
		if double_tap_timer.is_stopped():
			last_pressed_movement = current_movement
			double_tap_count = 1
			double_tap_timer.start()
		else:
			if double_tap_count == 1 and current_movement == last_pressed_movement:
				simulate_button_press(double_tap)
				double_tap_count = 0
				double_tap_timer.stop()

func simulate_button_press(action_name: String):
	var press = InputEventAction.new()
	press.action = action_name
	press.pressed = true
	Input.parse_input_event(press)

	var release = InputEventAction.new()
	release.action = action_name
	release.pressed = false
	Input.parse_input_event(release)
	
func is_action_just_pressed(action_name) -> bool:
	return Input.is_action_just_pressed(action_name)

func is_action_pressed(action_name) -> bool:
	return Input.is_action_pressed(action_name)
	
func to_world_position(screen_position: Vector2) -> Vector2:
	var canvas_transform = get_viewport().get_canvas_transform()
	var world_position = canvas_transform.affine_inverse() * screen_position
	return world_position
	
func is_running() -> bool:
	return Input.is_action_pressed(run) and get_movement_direction() != Vector2.ZERO

func _detect_input_method():
	if _setup_mobile():
		return
	if _setup_joystick():
		return
	if _setup_default():
		return

func _setup_mobile():
	if OS.has_feature("mobile") and aim_type != INPUT_TYPE.TOUCH:
		move_type = INPUT_TYPE.DEFAULT
		aim_type = INPUT_TYPE.TOUCH
		_print_debug()
		return true
	return false

func _setup_joystick():
	if aim_type != INPUT_TYPE.JOYSTICK:
		var connected_joysticks = Input.get_connected_joypads()
		var has_joystick = connected_joysticks.size() > 0
		if has_joystick:
			move_type = INPUT_TYPE.JOYSTICK
			aim_type = INPUT_TYPE.JOYSTICK
			_print_debug()
			return true
	return false

func _setup_default():
	if aim_type != INPUT_TYPE.MOUSE:
		move_type = INPUT_TYPE.DEFAULT
		aim_type = INPUT_TYPE.MOUSE
		_print_debug()
		return true
	return false

		
func _print_debug():
	match move_type:
		INPUT_TYPE.MOUSE:
			print("move_type: MOUSE")
		INPUT_TYPE.TOUCH:
			print("move_type: TOUCH")
		INPUT_TYPE.JOYSTICK:
			print("move_type: JOYSTICK")
		_:
			print("move_type: DEFAULT")
	match aim_type:
		INPUT_TYPE.MOUSE:
			print("aim_type: MOUSE")
		INPUT_TYPE.TOUCH:
			print("aim_type: TOUCH")
		INPUT_TYPE.JOYSTICK:
			print("aim_type: JOYSTICK")
		_:
			print("aim_type: DEFAULT")
