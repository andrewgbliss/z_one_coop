class_name AimAtTarget extends CharacterBaseNode

@export var target_group: StringName = "player"

func _process(_delta: float) -> void:
	find_target()
	calc_target_direction()

func find_target():
	if parent.controls.target == null:
		var nodes = get_tree().get_nodes_in_group(target_group)
		if nodes.is_empty():
			return
		var closest: Node2D = null
		var closest_dist_sq: float = INF
		var origin := parent.global_position
		for node in nodes:
			var n := node as Node2D
			if n == null:
				continue
			var dist_sq := origin.distance_squared_to(n.global_position)
			if dist_sq < closest_dist_sq:
				closest_dist_sq = dist_sq
				closest = n
		parent.controls.target = closest

func calc_target_direction():
	if parent.controls.target == null:
		parent.controls.target_aim_direction = Vector2.ZERO
		return
	parent.controls.target_aim_direction = (parent.controls.target.global_position - parent.global_position).normalized()
