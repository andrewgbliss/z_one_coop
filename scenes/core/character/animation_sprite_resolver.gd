class_name AnimationSpriteResolver extends CharacterBaseNode

var last_animation: String = ""
var last_velocity: Vector2 = Vector2.ZERO
var last_direction: String = "Down"
var last_state: String = "Idle"

func _process(_delta: float) -> void:
	_update_animation_sprite()

func _update_animation_sprite():
	var velocity = parent.velocity
	var state = "Idle"
	var direction = last_direction # Use last direction as default instead of "Down"

	if velocity != Vector2.ZERO:
		state = "Walk"
		# Only update direction when actually moving
		if velocity.x < 0:
			direction = "Side"
		elif velocity.x > 0:
			direction = "Side"
		elif velocity.y < 0:
			direction = "Up"
		elif velocity.y > 0:
			direction = "Down"
		# Update last_direction only when moving
		last_direction = direction
	else:
		# When idle, keep using the last direction (already set above)
		state = "Idle"

	if direction == "Side":
		parent.is_facing_y = false
	elif direction == "Up":
		parent.is_facing_y = true
	elif direction == "Down":
		parent.is_facing_y = true

	if parent.is_attacking:
		state = "Attack"

	var next_animation = state + " " + direction

	if last_state == "Attack":
		if parent.animated_sprite.is_playing():
			return
		parent.is_attacking = false

	if next_animation != last_animation:
		parent.animated_sprite.play(next_animation)
		last_animation = next_animation
		last_state = state

	last_velocity = velocity
