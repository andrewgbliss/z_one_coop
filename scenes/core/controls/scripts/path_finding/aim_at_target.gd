class_name AimAtTarget extends CharacterBaseNode

@export var target_group: StringName = "player"

func _process(_delta: float) -> void:
	find_target()
	calc_target_direction()

func find_target():
	if parent.controls.target == null:
		var nodes = get_tree().get_nodes_in_group(target_group)
		parent.controls.target = nodes[0]

func calc_target_direction():
	if parent.controls.target == null:
		parent.controls.target_aim_direction = Vector2.ZERO
		return
	parent.controls.target_aim_direction = (parent.controls.target.global_position - parent.global_position).normalized()
