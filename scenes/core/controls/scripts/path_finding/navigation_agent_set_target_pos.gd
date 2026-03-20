class_name NavigationAgentSetMoveTo extends CharacterBaseNode

var _time_accum := 0.0
const UPDATE_INTERVAL := 1.0

func _process(_delta: float) -> void:
	var delta := _delta
	if parent.navigation_agent == null or not parent.controls.target:
		_time_accum = 0.0
		return
	_time_accum += delta
	if _time_accum < UPDATE_INTERVAL:
		return
	_time_accum = 0.0
	parent.navigation_agent.set_target_position(parent.controls.target.global_position)
