class_name DebugPosLabel extends Label

@export var node: Node2D

func _process(_delta: float) -> void:
	text = "Pos: " + str(snappedf(node.position.x, 0.01)) + " - " + str(snappedf(node.position.y, 0.01)) + " Glob Pos: " + str(snappedf(node.global_position.x, 0.01)) + " - " + str(snappedf(node.global_position.y, 0.01))
