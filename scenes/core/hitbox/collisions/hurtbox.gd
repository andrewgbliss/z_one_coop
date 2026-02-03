class_name Hurtbox extends Area2D

var parent: CharacterController

func _ready() -> void:
	parent = get_parent() as CharacterController
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Node2D) -> void:
	if area is Hitbox:
		take_damage(area.damage, area)

func take_damage(damage: int, hitbox_area: Node2D = null) -> void:
	if not parent:
		return
	parent.take_damage(damage)
	# Only players (CharacterController with PlayerControls) get knockback; NPCs do not
	if parent.controls and parent.controls is PlayerControls:
		var direction := (global_position - hitbox_area.global_position).normalized() if hitbox_area else Vector2.ZERO
		if direction != Vector2.ZERO:
			parent.apply_knockback(direction)

# func apply_knockback_rigid(rigidbody: RigidBody2D) -> void:
# 	# Direction AWAY from hitbox - flip it
# 	var direction = (rigidbody.global_position - global_position).normalized()
# 	var impulse = direction * parent.character.knockback_force * 2.0
# 	# print("Knockback direction: ", direction, " impulse: ", impulse)
# 	rigidbody.apply_central_impulse(impulse)
