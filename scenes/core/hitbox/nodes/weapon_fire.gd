class_name WeaponFire extends Node2D

enum WeaponFireInput {
	TRIGGER_LEFT,
	TRIGGER_RIGHT,
	BUMPER_LEFT,
	BUMPER_RIGHT
}
@export var weapon_fire_input: WeaponFireInput = WeaponFireInput.TRIGGER_LEFT

@export var weapon: Weapon

var parent: CharacterController

func _ready() -> void:
	parent = get_parent()

func _process(delta: float) -> void:
	if weapon_fire_input == WeaponFireInput.TRIGGER_LEFT and parent.controls.is_action_pressed(parent.controls.trigger_left):
		_fire_weapon()
	elif weapon_fire_input == WeaponFireInput.TRIGGER_RIGHT and parent.controls.is_action_pressed(parent.controls.trigger_right):
		_fire_weapon()
	elif weapon_fire_input == WeaponFireInput.BUMPER_LEFT and parent.controls.is_action_pressed(parent.controls.bumper_left):
		_fire_weapon()
	elif weapon_fire_input == WeaponFireInput.BUMPER_RIGHT and parent.controls.is_action_pressed(parent.controls.bumper_right):
		_fire_weapon()
	if parent.controls.target:
		_fire_weapon()
	_update_weapon_cooldowns(delta)

func spawn_projectile_from_weapon() -> void:
	if not weapon or weapon.projectile == "":
		return
	var aim_direction = Vector2.RIGHT
	if parent.blackboard.character_controller_type == CharacterBlackboard.CharacterControllerType.PLAYER:
		aim_direction = parent.controls.get_aim_direction()
	else:
		aim_direction = parent.controls.target_aim_direction
	var spawn_position = global_position
	if not weapon.top_level:
		spawn_position = position
	var entity = SpawnManager.spawn(weapon.projectile, spawn_position, self)
	if entity is Projectile:
		if weapon.top_level:
			entity.top_level = true
		entity.start(spawn_position, aim_direction)

func _update_weapon_cooldowns(delta: float) -> void:
	if weapon:
		weapon.update_cooldown(delta)

func _fire_weapon() -> void:
	if not weapon or not weapon.can_fire():
		return
	parent.is_attacking = true
	spawn_projectile_from_weapon()
	weapon.fire()
