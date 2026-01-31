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

var target: Node2D
var closest_target: Node2D
var has_given_damage = false
var velocity
var time_elapsed = 0

var current_weight
var angular_velocity

func start(_position, _direction):
	position = _position
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

func _ready():
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

func die():
	call_deferred("queue_free")
	
func _on_hitbox_collided(_pos: Vector2):
	if destroy_on_collide:
		call_deferred("queue_free")
