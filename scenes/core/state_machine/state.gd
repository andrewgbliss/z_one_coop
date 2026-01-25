class_name State extends RefCounted

var name: String
var on_enter: Callable
var on_exit: Callable
var on_process: Callable
var on_physics_process: Callable

func _init(
	state_name: String,
	enter_callback: Callable = Callable(),
	exit_callback: Callable = Callable(),
	process_callback: Callable = Callable(),
	physics_process_callback: Callable = Callable()
) -> void:
	name = state_name
	on_enter = enter_callback
	on_exit = exit_callback
	on_process = process_callback
	on_physics_process = physics_process_callback

func enter() -> void:
	if on_enter.is_valid():
		on_enter.call()

func exit() -> void:
	if on_exit.is_valid():
		on_exit.call()

func process(_delta: float) -> void:
	if on_process.is_valid():
		on_process.call(_delta)

func physics_process(_delta: float) -> void:
	if on_physics_process.is_valid():
		on_physics_process.call(_delta)
