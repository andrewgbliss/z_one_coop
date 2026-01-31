class_name FollowTarget extends CharacterBaseNode
 			
@export var target_group: StringName = "player"

func _physics_process(_delta: float) -> void:
	if not parent.controls.target:
		return
	parent.move()

func _process(_delta: float) -> void:
	calc_target_direction()

func calc_target_direction():
	if parent.controls.target == null:
		parent.controls.target_movement_direction = Vector2.ZERO
		return
	parent.controls.target_movement_direction = (parent.controls.target.global_position - parent.global_position).normalized()
