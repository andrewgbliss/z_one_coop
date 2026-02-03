class_name InputFire extends Node2D

enum InputFireInput {
	TRIGGER_LEFT,
	TRIGGER_RIGHT,
	BUMPER_LEFT,
	BUMPER_RIGHT
}

enum InputHand {
	LEFT,
	RIGHT
}

@export var weapon_fire_input: InputFireInput = InputFireInput.TRIGGER_LEFT
@export var hand: InputHand = InputHand.LEFT

var parent: CharacterController

func _ready() -> void:
	parent = get_parent()

func _process(delta: float) -> void:
	if weapon_fire_input == InputFireInput.TRIGGER_LEFT and parent.controls.is_action_pressed(parent.controls.trigger_left):
		_fire()
	elif weapon_fire_input == InputFireInput.TRIGGER_RIGHT and parent.controls.is_action_pressed(parent.controls.trigger_right):
		_fire()
	elif weapon_fire_input == InputFireInput.BUMPER_LEFT and parent.controls.is_action_pressed(parent.controls.bumper_left):
		_fire()
	elif weapon_fire_input == InputFireInput.BUMPER_RIGHT and parent.controls.is_action_pressed(parent.controls.bumper_right):
		_fire()
	if parent.controls.target:
		_fire()
	_update_weapon_cooldowns(delta)

func spawn_projectile_from_weapon() -> void:
	var weapon = parent.blackboard.equipment.left_hand
	if hand == InputHand.RIGHT:
		weapon = parent.blackboard.equipment.right_hand
	if not weapon or weapon.projectile == "":
		return
	var aim_direction = Vector2.RIGHT
	if parent.blackboard.character_controller_type == CharacterBlackboard.CharacterControllerType.PLAYER:
		aim_direction = parent.controls.get_aim_direction()
	else:
		aim_direction = parent.controls.target_aim_direction
	var spawn_position = position
	var projectile = weapon.projectile
	var container = parent
	var tl = false
	if parent.blackboard.health == parent.blackboard.max_health:
		projectile = projectile + "_shoot"
		container = parent.get_parent()
		tl = true
		spawn_position = global_position
	var entity = SpawnManager.spawn(projectile, spawn_position, container)
	if entity is Projectile:
		if tl:
			entity.top_level = true
		entity.start(spawn_position, aim_direction)

func _update_weapon_cooldowns(delta: float) -> void:
	var weapon = parent.blackboard.equipment.left_hand
	if hand == InputHand.RIGHT:
		weapon = parent.blackboard.equipment.right_hand
	if weapon:
		weapon.update_cooldown(delta)

func _fire() -> void:
	var weapon = parent.blackboard.equipment.left_hand
	if hand == InputHand.RIGHT:
		weapon = parent.blackboard.equipment.right_hand
	if not weapon or not weapon.can_fire():
		return
	parent.is_attacking = true
	spawn_projectile_from_weapon()
	weapon.fire()
