class_name AnimationSpriteResolver extends CharacterBaseNode

@export var idle_str: StringName = &"Idle"
@export var walk_str: StringName = &"Walk"
@export var direction_side_str: StringName = &"Side"
@export var direction_up_str: StringName = &"Up"
@export var direction_down_str: StringName = &"Down"
@export var attack_str: StringName = &"Attack"


var last_animation: String = ""
var last_velocity: Vector2 = Vector2.ZERO
var last_direction: String = ""
var last_state: String = ""

func _ready() -> void:
	super()
	last_direction = direction_down_str
	last_state = idle_str

func _process(_delta: float) -> void:
	_update_animation_sprite()

func _update_animation_sprite():
	var velocity = parent.velocity
	var state = idle_str
	var direction = last_direction # Use last direction as default instead of "Down"

	if velocity != Vector2.ZERO:
		state = walk_str
		# Whichever axis has the larger absolute velocity wins
		if abs(velocity.x) >= abs(velocity.y):
			direction = direction_side_str
		else:
			if velocity.y < 0:
				direction = direction_up_str
			else:
				direction = direction_down_str
		# Update last_direction only when moving
		last_direction = direction
	else:
		# When idle, keep using the last direction (already set above)
		state = idle_str

	if direction == direction_side_str:
		parent.is_facing_y = false
	elif direction == direction_up_str:
		parent.is_facing_y = true
	elif direction == direction_down_str:
		parent.is_facing_y = true

	if parent.is_attacking:
		state = attack_str

	var next_animation = state + " " + direction

	if last_state == attack_str:
		if parent.animated_sprite.is_playing():
			return
		parent.is_attacking = false

	if next_animation != last_animation:
		parent.animated_sprite.play(next_animation)
		last_animation = next_animation
		last_state = state

	last_velocity = velocity
