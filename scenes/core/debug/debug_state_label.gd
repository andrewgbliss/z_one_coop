class_name DebugStateLabel extends Label

@export var player_state_machine: PlayerStateMachine

func _ready() -> void:
	if player_state_machine and player_state_machine.state_machine:
		player_state_machine.state_machine.state_changed.connect(_on_state_changed)
		# Set initial state
		text = player_state_machine.state_machine.get_current_state_name()

func _on_state_changed(new_state_name: String) -> void:
	text = new_state_name
