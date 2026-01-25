class_name StateMachine extends Node

signal state_changed(new_state_name: String)

var states: Dictionary = {}
var current_state: State
var transitions: Dictionary = {}

func add_state(state: State) -> void:
	states[state.name] = state
	transitions[state.name] = []

func add_transition(from_state_name: String, to_state_name: String, condition: Callable) -> void:
	if not transitions.has(from_state_name):
		transitions[from_state_name] = []
	transitions[from_state_name].append({
		"to": to_state_name,
		"condition": condition
	})

func add_state_definition(
	state_name: String,
	enter_callback: Callable = Callable(),
	exit_callback: Callable = Callable(),
	process_callback: Callable = Callable(),
	physics_process_callback: Callable = Callable()
) -> void:
	var state = State.new(
		state_name,
		enter_callback,
		exit_callback,
		process_callback,
		physics_process_callback
	)
	add_state(state)

func set_initial_state(state_name: String) -> void:
	if states.has(state_name):
		current_state = states[state_name]
		current_state.enter()
		state_changed.emit(state_name)

func change_state(state_name: String) -> void:
	if not states.has(state_name):
		return
	
	if current_state:
		current_state.exit()
	
	current_state = states[state_name]
	current_state.enter()
	state_changed.emit(state_name)

func process(delta: float) -> void:
	if not current_state:
		return
	
	current_state.process(delta)
	_check_transitions()

func physics_process(delta: float) -> void:
	if not current_state:
		return
	
	current_state.physics_process(delta)
	_check_transitions()

func _check_transitions() -> void:
	if not current_state or not transitions.has(current_state.name):
		return
	
	for transition in transitions[current_state.name]:
		if transition.condition.is_valid() and transition.condition.call():
			change_state(transition.to)
			break

func get_current_state_name() -> String:
	if current_state:
		return current_state.name
	return ""
