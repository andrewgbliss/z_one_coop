class_name Projectile extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var hitbox: Hitbox = $Hitbox

@export var animation_name: String = "Fire"
@export var offset: float = 0.0
@export var speed = 300
@export var acceleration = 1
@export var follow_group_name: String
@export var gravity: float = 0
@export var destroy_on_collide: bool = true
@export var time_to_live: float = 5.0
@export var audio: AudioStreamPlayer2D
@export_range(-100.0, 0) var min_audio_level: float = -20
@export_range(-100.0, 0) var max_audio_level: float = -5
@export var disable_rotation: bool = false
@export var reflect_times: int = 0
@export var effect_time_elapsed: PackedScene
@export var spawn_add: String
var current_reflect_times: int = 0

var target: Node2D
var closest_target: Node2D
var has_given_damage = false
var velocity
var time_elapsed = 0

var current_weight
var angular_velocity
var parent

func start(_position, _direction):
	position = _position
	if not disable_rotation:
		rotation = _direction.angle()
	position += Vector2.from_angle(rotation) * offset
	if speed > 0:
		velocity = _direction.normalized() * speed
	else:
		velocity = Vector2.ZERO

	if audio != null:
		var rand_level = randf_range(min_audio_level, max_audio_level)
		audio.volume_db = rand_level
		audio.play()

	if animation_player:
		animation_player.play(animation_name)
	
	if follow_group_name:
		var targets = get_tree().get_nodes_in_group(follow_group_name)
		for t in targets:
			if not closest_target:
				closest_target = t
			else:
				var distance = t.global_position.distance_to(global_position)
				var closest_distance = closest_target.global_position.distance_to(global_position)
				if distance < closest_distance:
					closest_target = t
		if closest_target:
			target = closest_target
	time_elapsed = time_to_live

	if spawn_add:
		var entity = SpawnManager.spawn(spawn_add, position, get_parent())
		if entity is Projectile:
			entity.start(position, _direction)

func _ready():
	parent = get_parent()
	hitbox.collided.connect(_on_hitbox_collided)
	
func _physics_process(delta):
	if gravity != 0:
		velocity.y += gravity * delta

	if speed > 0:
		if target != null and target.is_inside_tree():
			var direction = target.global_position - global_position
			
			velocity.x = move_toward(velocity.x, direction.normalized().x * speed, acceleration * delta)
			velocity.y = move_toward(velocity.y, direction.normalized().y * speed, acceleration * delta)

			rotation = velocity.angle()
		elif target != null and not target.is_inside_tree():
			target = null

		position += velocity * delta
			
	time_elapsed -= delta
	if time_elapsed <= 0:
		die()
		if effect_time_elapsed:
			var effect = effect_time_elapsed.instantiate()
			effect.global_position = global_position
			get_tree().current_scene.add_child(effect)

func die():
	call_deferred("queue_free")

func _surface_normal_for_bounce(collision_point: Vector2, fallback: Vector2) -> Vector2:
	if fallback.length_squared() < 0.0001 and velocity.length_squared() < 0.0001:
		return Vector2.ZERO
	var inc: Vector2 = velocity if velocity.length_squared() > 0.0001 else fallback.normalized()
	inc = inc.normalized()
	var space := get_world_2d().direct_space_state
	var from_pt := collision_point - inc * 48.0
	var to_pt := collision_point + inc * 24.0
	var pq := PhysicsRayQueryParameters2D.create(from_pt, to_pt)
	pq.exclude = [hitbox.get_rid()]
	pq.collision_mask = hitbox.collision_mask
	pq.collide_with_areas = true
	pq.collide_with_bodies = true
	var hit := space.intersect_ray(pq)
	if hit.is_empty():
		return fallback.normalized() if fallback.length_squared() > 0.0001 else Vector2.ZERO
	var n: Vector2 = hit.get("normal", Vector2.ZERO)
	if n.length_squared() < 0.0001:
		return fallback.normalized() if fallback.length_squared() > 0.0001 else Vector2.ZERO
	n = n.normalized()
	if velocity.dot(n) > 0.0:
		n = -n
	return n

func _on_hitbox_collided(collision_point: Vector2, direction: Vector2):
	if reflect_times > 0 and current_reflect_times < reflect_times:
		current_reflect_times += 1
		var normal := _surface_normal_for_bounce(collision_point, direction)
		if normal.length_squared() < 0.0001 and direction.length_squared() > 0.0001:
			normal = direction.normalized()
		if normal.length_squared() > 0.0001:
			velocity = velocity.bounce(normal)
		return
	if destroy_on_collide:
		die()
