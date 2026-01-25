class_name AnimatedSpriteFacingDirection extends CharacterBaseNode

@export var agent: CharacterController
@export var animated_sprite: AnimatedSprite2D
@export var flip_offset: Vector2 = Vector2.ZERO

var default_offset: Vector2 = Vector2.ZERO
var is_facing_right: bool = true
var previous_facing_right: bool = true

func _ready():
	super()
	call_deferred("_after_ready")
	
func _after_ready():
	default_offset = animated_sprite.offset
	is_facing_right = agent.is_facing_right
	
func _process(_delta: float) -> void:
	_update_facing_direction()

func _update_facing_direction():
	var new_is_facing_right = agent.is_facing_right
	if not agent.flip_h_lock:
		match parent.controls.aim_type:
			CharacterControls.INPUT_TYPE.MOUSE:
				var mouse_pos = parent.get_global_mouse_position()
				new_is_facing_right = mouse_pos.x > agent.position.x
			CharacterControls.INPUT_TYPE.TOUCH:
				new_is_facing_right = agent.controls.touch_position.x > agent.global_position.x
				new_is_facing_right = agent.velocity.x > 0
			CharacterControls.INPUT_TYPE.JOYSTICK:
				new_is_facing_right = agent.controls.get_aim_direction().x > 0
			CharacterControls.INPUT_TYPE.DEFAULT:
				if agent.velocity.x != 0:
					new_is_facing_right = agent.velocity.x > 0
	if new_is_facing_right != is_facing_right:
		is_facing_right = new_is_facing_right
		agent.is_facing_right = is_facing_right
		agent.flip_h()
