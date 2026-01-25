class_name PlayerStateMachine extends CharacterBaseNode

# State machine for player movement states: idle, move, and dash

var state_machine: StateMachine

# Dash state variables
var dash_time_elapsed: float = 0.0

func _ready() -> void:
	super ()
	setup_state_machine()

func setup_state_machine() -> void:
	# Create the state machine
	state_machine = StateMachine.new()
	
	# Define idle state
	state_machine.add_state_definition(
		"idle",
		_on_idle_enter,
		_on_idle_exit,
		_on_idle_process,
		_on_idle_physics_process
	)
	
	# Define move state
	state_machine.add_state_definition(
		"move",
		_on_move_enter,
		_on_move_exit,
		_on_move_process,
		_on_move_physics_process
	)
	
	# Define dash state
	state_machine.add_state_definition(
		"dash",
		_on_dash_enter,
		_on_dash_exit,
		_on_dash_process,
		_on_dash_physics_process
	)
	
	# Define transitions
	# From idle to move (when movement input detected)
	state_machine.add_transition(
		"idle",
		"move",
		func() -> bool:
			return _has_movement_input()
	)
	
	# From move to idle (when no movement input)
	state_machine.add_transition(
		"move",
		"idle",
		func() -> bool:
			return not _has_movement_input()
	)
	
	# From idle to dash (on dash input)
	state_machine.add_transition(
		"idle",
		"dash",
		func() -> bool:
			return _should_dash()
	)
	
	# From move to dash (on dash input)
	state_machine.add_transition(
		"move",
		"dash",
		func() -> bool:
			return _should_dash()
	)
	
	# From dash to idle (when dash timer expires and no movement)
	state_machine.add_transition(
		"dash",
		"idle",
		func() -> bool:
			return dash_time_elapsed <= 0.0 and not _has_movement_input()
	)
	
	# From dash to move (when dash timer expires and movement detected)
	state_machine.add_transition(
		"dash",
		"move",
		func() -> bool:
			return dash_time_elapsed <= 0.0 and _has_movement_input()
	)
	
	# Set the initial state
	state_machine.set_initial_state("idle")

func _process(delta: float) -> void:
	if state_machine:
		state_machine.process(delta)

func _physics_process(delta: float) -> void:
	if state_machine:
		state_machine.physics_process(delta)

func _unhandled_input(_event: InputEvent) -> void:
	# Handle dash input
	if parent and parent.controls:
		if parent.controls.is_action_just_pressed(parent.controls.dash):
			_trigger_dash()
		elif parent.controls.move_type == CharacterControls.INPUT_TYPE.TOUCH and parent.controls.is_action_just_pressed(parent.controls.double_tap):
			_trigger_dash()

# Helper functions
func _has_movement_input() -> bool:
	return parent.blackboard.direction != Vector2.ZERO

func _should_dash() -> bool:
	if parent.is_paralyzed:
		return false
	# This is checked in transitions, but we also handle it via input
	# Return false here to let input handling trigger the transition
	return false

func _trigger_dash() -> void:
	if parent.is_paralyzed:
		return
	# Force transition to dash state
	if state_machine and state_machine.get_current_state_name() != "dash":
		state_machine.change_state("dash")

func _is_trigger_left_pressed() -> bool:
	if parent.is_paralyzed:
		return false
	return parent.controls.is_action_pressed(parent.controls.trigger_left)

func _is_trigger_right_pressed() -> bool:
	if parent.is_paralyzed:
		return false
	return parent.controls.is_action_pressed(parent.controls.trigger_right)

func _is_bumper_left_pressed() -> bool:
	if parent.is_paralyzed:
		return false
	return parent.controls.is_action_pressed(parent.controls.bumper_left)

func _is_bumper_right_pressed() -> bool:
	if parent.is_paralyzed:
		return false
	return parent.controls.is_action_pressed(parent.controls.bumper_right)

func _move():
	if parent.is_paralyzed:
		return
	parent.move()

# State callbacks
func _on_idle_enter() -> void:
	pass

func _on_idle_exit() -> void:
	pass

func _on_idle_process(_delta: float) -> void:
	pass

func _on_idle_physics_process(_delta: float) -> void:
	_move()

func _on_move_enter() -> void:
	pass

func _on_move_exit() -> void:
	pass

func _on_move_process(_delta: float) -> void:
	pass

func _on_move_physics_process(_delta: float) -> void:
	_move()

func _on_dash_enter() -> void:
	# Initialize dash timer
	dash_time_elapsed = parent.blackboard.dash_time
	parent.dash()

func _on_dash_exit() -> void:
	pass

func _on_dash_process(_delta: float) -> void:
	pass

func _on_dash_physics_process(delta: float) -> void:
	# Update dash timer
	dash_time_elapsed -= delta
	parent.default_move()
