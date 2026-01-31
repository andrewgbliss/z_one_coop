class_name NavigationAgentSetMoveTo extends CharacterBaseNode

func _process(_delta: float) -> void:
	if parent.navigation_agent == null:
		return
	parent.navigation_agent.set_target_position(parent.controls.target.global_position)
