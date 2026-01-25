class_name Hitbox extends Area2D

@export var damage: int = 1
@export var collide_effect: PackedScene

signal collided(pos: Vector2)

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _on_body_entered(body):
	var collide_position = get_collision_point(body)
	if collide_effect:
		var effect = collide_effect.instantiate()
		effect.global_position = collide_position
		get_tree().current_scene.add_child(effect)
	collided.emit(collide_position)

func _on_area_entered(area: Area2D) -> void:
	var collide_position = get_collision_point(area)
	if collide_effect:
		var effect = collide_effect.instantiate()
		effect.global_position = collide_position
		get_tree().current_scene.add_child(effect)
	collided.emit(collide_position)

func get_collision_point(body) -> Vector2:
	# Calculate the contact point between hitbox and body
	# This is the point on our hitbox edge closest to the body
	var direction_to_body = (body.global_position - global_position).normalized()
	
	# Get our collision shape to determine the edge point
	var collision_shape = null
	for child in get_children():
		if child is CollisionShape2D:
			collision_shape = child
			break
	
	if not collision_shape:
		# Fallback: midpoint between centers
		return (global_position + body.global_position) / 2.0
	
	# Calculate approximate edge point based on shape
	var shape_resource = collision_shape.shape
	var edge_offset = Vector2.ZERO
	
	if shape_resource is CircleShape2D:
		edge_offset = direction_to_body * shape_resource.radius
	elif shape_resource is RectangleShape2D:
		var extents = shape_resource.size / 2.0
		edge_offset.x = clamp(direction_to_body.x * extents.x * 1.5, -extents.x, extents.x)
		edge_offset.y = clamp(direction_to_body.y * extents.y * 1.5, -extents.y, extents.y)
	elif shape_resource is CapsuleShape2D:
		edge_offset = direction_to_body * shape_resource.radius
	else:
		# Unknown shape, use simple midpoint
		return (global_position + body.global_position) / 2.0
	
	return global_position + collision_shape.position + edge_offset
