class_name Hurtbox extends Area2D

@export var audio_name: StringName = &"Hit"

var parent: CharacterController
var _player_damage_cooldown_active := false

func _ready() -> void:
	parent = get_parent() as CharacterController
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Node2D) -> void:
	if area is Hitbox:
		take_damage(area.damage, area)

func _is_player() -> bool:
	return parent and parent.controls is PlayerControls

func take_damage(damage: int, hitbox_area: Node2D = null) -> void:
	if not parent:
		return
	# Players get 1 second invincibility after taking damage; NPCs do not
	if _is_player():
		if _player_damage_cooldown_active:
			return
		_player_damage_cooldown_active = true
		get_tree().create_timer(1.0).timeout.connect(_on_player_damage_cooldown_finished)
	parent.take_damage(damage)
	if audio_name:
		AudioManager.play(audio_name)
	# Only players (CharacterController with PlayerControls) get knockback; NPCs do not
	if parent.controls and parent.controls is PlayerControls:
		var direction := (global_position - hitbox_area.global_position).normalized() if hitbox_area else Vector2.ZERO
		if direction != Vector2.ZERO:
			parent.apply_knockback(direction)

func _on_player_damage_cooldown_finished() -> void:
	_player_damage_cooldown_active = false

# func apply_knockback_rigid(rigidbody: RigidBody2D) -> void:
# 	# Direction AWAY from hitbox - flip it
# 	var direction = (rigidbody.global_position - global_position).normalized()
# 	var impulse = direction * parent.character.knockback_force * 2.0
# 	# print("Knockback direction: ", direction, " impulse: ", impulse)
# 	rigidbody.apply_central_impulse(impulse)
