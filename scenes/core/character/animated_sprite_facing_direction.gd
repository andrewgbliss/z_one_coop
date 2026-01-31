class_name AnimatedSpriteFacingDirection extends CharacterBaseNode

@export var flip_offset: Vector2 = Vector2.ZERO

var default_offset: Vector2 = Vector2.ZERO
var is_facing_right: bool = true

func _ready():
	super ()
	call_deferred("_after_ready")
	
func _after_ready():
	default_offset = parent.animated_sprite.offset
	is_facing_right = parent.is_facing_right
	
func _process(_delta: float) -> void:
	_update_facing_direction()

func _update_facing_direction():
	var new_is_facing_right = is_facing_right
	if not parent.flip_h_lock:
		match parent.controls.aim_type:
			PlayerControls.INPUT_TYPE.MOUSE:
				var mouse_pos = parent.get_global_mouse_position()
				new_is_facing_right = mouse_pos.x > parent.position.x
			PlayerControls.INPUT_TYPE.TOUCH:
				new_is_facing_right = parent.controls.touch_position.x > parent.global_position.x
			PlayerControls.INPUT_TYPE.JOYSTICK:
				new_is_facing_right = parent.controls.get_aim_direction().x > 0
			PlayerControls.INPUT_TYPE.DEFAULT:
				if parent.velocity.x != 0:
					new_is_facing_right = parent.velocity.x > 0
		if parent.is_facing_y:
			new_is_facing_right = true
	if new_is_facing_right != is_facing_right:
		is_facing_right = new_is_facing_right
		parent.is_facing_right = is_facing_right
		parent.flip_h()
