class_name CharacterBaseNode extends Node

var parent: CharacterController

func _ready() -> void:
	parent = get_parent()
