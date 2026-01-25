class_name CharacterController extends CharacterBody2D

enum CameraBoundsType {
	RECTANGLE,
	TOP_BOTTOM,
	LEFT_RIGHT
}

@onready var sprite: Sprite2D = $Sprite2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera: PhantomCamera2D = $PhantomCamera2D

@export var blackboard: CharacterBlackboard
@export var controls: CharacterControls
@export var device_index: int = 0
@export var is_facing_right: bool = true

@export_group("Clean Up")
@export var garbage: bool = false
@export var garbage_time: float = 0.0
@export var die_explosions: Array[Explosion]

@export_group("Navigation")
@export var navigation_agent: NavigationAgent2D
@export var paths: Array[Path2D]
@export var lock_to_camera_bounds: bool = false
@export var camera_bounds: Area2D
@export var camera_bounds_type: CameraBoundsType = CameraBoundsType.RECTANGLE

@export_group("Weapons")
@export var weapon_fires: Array[WeaponFire]

var is_alive: bool = false
var is_paralyzed: bool = false
var flip_v_lock: bool = false
var flip_h_lock: bool = false
var spawn_position: Vector2 = Vector2.ZERO
var gravity_dir: Vector2 = Vector2(0, 1)
var facing_right_modifier: int = 1

signal spawned(pos: Vector2)
signal died(pos: Vector2)
signal facing_direction_changed
signal parent_path_created(path: Path2D)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_1:
			prev_level()
		elif event.keycode == KEY_2:
			next_level()

func prev_level():
	if blackboard.level < 1:
		blackboard.add_level(6)
	else:
		blackboard.add_level(-1)
	var weapon_fire = weapon_fires[0]
	var weapon = weapon_fire.weapon
	if weapon:
		weapon.attack_rate = 0.15
		weapon.projectile = "bullet_" + str(blackboard.level + 1)

func next_level():
	if blackboard.level >= 6:
		blackboard.add_level(-6)
	else:
		blackboard.add_level(1)
	var weapon_fire = weapon_fires[0]
	var weapon = weapon_fire.weapon
	if weapon:
		weapon.attack_rate = 0.15
		weapon.projectile = "bullet_" + str(blackboard.level + 1)

func _ready() -> void:
	if navigation_agent:
		navigation_agent.velocity_computed.connect(Callable(_on_velocity_computed))
	is_alive = false
	is_paralyzed = true
	hide()

func created_parent_path(path: Path2D):
	parent_path_created.emit(path)

func handle_collisions():
	for i in get_slide_collision_count():
		var col = get_slide_collision(i)
		var collider = col.get_collider()
		if collider is RigidBody2D:
			collider.apply_central_impulse(col.get_normal() * -blackboard.push_force)

func calc_new_velocity(v: Vector2, d: Vector2, s: float, a: float, f: float, c: Vector2):
	if d != Vector2.ZERO:
		v = v.move_toward(d * s, a)
	else:
		v = v.move_toward(Vector2.ZERO, f)
	v = v.clamp(-c, c)
	return v

func _on_velocity_computed(safe_velocity: Vector2):
	safe_velocity = safe_velocity.clamp(-blackboard.max_velocity, blackboard.max_velocity)
	velocity = safe_velocity

func default_move() -> void:
	if move_and_slide():
		handle_collisions()
	if lock_to_camera_bounds:
		_clamp_to_camera_bounds()

func move() -> void:
	# Calculate speed multiplier for running
	var speed_multiplier: float = 1.0
	if controls.is_running():
		speed_multiplier = blackboard.run_multiplier
	
	# Update direction and aim
	blackboard.direction = controls.get_movement_direction()
	blackboard.aim_direction = controls.get_aim_direction()
	
	# Calculate new velocity
	blackboard.velocity = calc_new_velocity(
		velocity,
		blackboard.direction,
		blackboard.speed * speed_multiplier,
		blackboard.acceleration,
		blackboard.friction,
		blackboard.max_velocity
	)
	
	velocity = blackboard.velocity
	default_move()

func _clamp_to_camera_bounds():
	if camera_bounds:
		var limit_target = camera_bounds.get_node("CollisionShape2D")
		var shape = limit_target.shape as RectangleShape2D
		if camera_bounds_type == CameraBoundsType.TOP_BOTTOM:
			position.y = clamp(position.y, camera_bounds.position.y - shape.size.y / 2, camera_bounds.position.y - 16 + shape.size.y / 2)
		elif camera_bounds_type == CameraBoundsType.LEFT_RIGHT:
			position.x = clamp(position.x, camera_bounds.position.x - shape.size.x / 2, camera_bounds.position.x + shape.size.x / 2)
		else:
			position.x = clamp(position.x, camera_bounds.position.x - shape.size.x / 2, camera_bounds.position.x + shape.size.x / 2)
			position.y = clamp(position.y, camera_bounds.position.y - shape.size.y / 2, camera_bounds.position.y - 16 + shape.size.y / 2)

func dash():
	# Calculate dash direction
	var dash_direction = Vector2.ZERO
	if controls.aim_type == CharacterControls.INPUT_TYPE.TOUCH and controls.double_tap_direction != controls.DOUBLE_TAP_DIRECTION.NONE:
		dash_direction = controls.get_double_tap_direction()
		controls.double_tap_direction = controls.DOUBLE_TAP_DIRECTION.NONE
	elif controls.aim_type == CharacterControls.INPUT_TYPE.MOUSE:
		dash_direction = controls.get_aim_direction()
	else:
		dash_direction = controls.get_movement_direction()
	
	# Apply dash velocity
	if dash_direction != Vector2.ZERO:
		blackboard.velocity += dash_direction * blackboard.dash_speed
	else:
		# Default dash direction if no aim direction
		blackboard.velocity += blackboard.direction.normalized() * blackboard.dash_speed

	velocity = blackboard.velocity

func apply_knockback(direction: Vector2):
	velocity = Vector2.ZERO
	blackboard.velocity = direction * blackboard.knockback_force
	velocity = blackboard.velocity
	default_move()

func spawn(sp: Vector2 = Vector2.ZERO):
	spawn_position = sp
	position = spawn_position
	velocity = Vector2.ZERO
	is_alive = true
	is_paralyzed = false
	show()
	spawned.emit(position)

func respawn():
	spawn(spawn_position)

func die():
	if not is_alive:
		return
	is_alive = false
	is_paralyzed = true
	for explosion in die_explosions:
		explosion.run()
	if garbage:
		await get_tree().create_timer(garbage_time).timeout
		call_deferred("queue_free")
	else:
		await get_tree().create_timer(garbage_time).timeout
		hide()
	died.emit(global_position)

func take_damage(amount: int):
	blackboard.take_damage(amount)
	pulse_health()
	if blackboard.health <= 0:
		die()

func pulse_health():
	if sprite:
		if sprite.material:
			# One shot
			sprite.material.set_shader_parameter("mode", 1)
			sprite.material.set_shader_parameter("cycle_speed", 10.0)
			await get_tree().create_timer(0.5).timeout
			sprite.material.set_shader_parameter("mode", 0)
			sprite.material.set_shader_parameter("cycle_speed", 1.0)

			# Continuous
			var health_percent = float(blackboard.health) / float(blackboard.max_health)
			if health_percent <= 0.5:
				var cycle_speed = health_percent * 10.0
				sprite.material.set_shader_parameter("mode", 1)
				sprite.material.set_shader_parameter("cycle_speed", cycle_speed)
			else:
				sprite.material.set_shader_parameter("mode", 0)
				sprite.material.set_shader_parameter("cycle_speed", 1.0)

	if animated_sprite:
		if animated_sprite.material:
			# One shot
			animated_sprite.material.set_shader_parameter("mode", 1)
			animated_sprite.material.set_shader_parameter("cycle_speed", 10.0)
			await get_tree().create_timer(0.5).timeout
			animated_sprite.material.set_shader_parameter("mode", 0)
			animated_sprite.material.set_shader_parameter("cycle_speed", 1.0)

			# Continuous
			var health_percent = float(blackboard.health) / float(blackboard.max_health)
			if health_percent <= 0.5:
				var cycle_speed = health_percent * 10.0
				animated_sprite.material.set_shader_parameter("mode", 1)
				animated_sprite.material.set_shader_parameter("cycle_speed", cycle_speed)
			else:
				animated_sprite.material.set_shader_parameter("mode", 0)
				animated_sprite.material.set_shader_parameter("cycle_speed", 1.0)
			
func flip_h():
	animated_sprite.flip_h = not is_facing_right
	facing_direction_changed.emit()

func item_pickup(item: Item):
	if item is Currency:
		blackboard.inventory.add_gold(item)
	elif item is Equipable:
		equip(item)
	elif item is Consumable:
		consume(item)

func consume(item: Item):
	if item.consume_on_pickup:
		if item.hp > 0:
			blackboard.add_health(item.hp)
		if item.mp > 0:
			blackboard.add_mana(item.mp)
		if item.sp > 0:
			blackboard.add_stamina(item.sp)
		if item.ammo > 0:
			var weapon_fire = weapon_fires[1]
			var weapon = weapon_fire.weapon
			if weapon:
				weapon.add_ammo(item.ammo)
		if item.armor > 0:
			blackboard.add_armor(item.armor)
		if item.level > 0:
			if blackboard.level >= 6:
				blackboard.add_level(-6)
			else:
				blackboard.add_level(item.level)
			var weapon_fire = weapon_fires[0]
			var weapon = weapon_fire.weapon
			if weapon:
				weapon.attack_rate = 0.15
				weapon.projectile = "bullet_" + str(blackboard.level + 1)
	else:
		blackboard.inventory.add(item)

func equip(item: Item):
	if item.equip_on_pickup:
		blackboard.item_belt.set_next_belt_slot(item)
		blackboard.equipment.equip(item, blackboard.equipment.get_slot_type(item.slot))
	else:
		blackboard.inventory.add(item)

func focus():
	if camera:
		camera.set_priority(10)
		#camera.enabled = true
		#camera.make_current()

func get_random_path():
	return paths[randi() % paths.size()]
	
