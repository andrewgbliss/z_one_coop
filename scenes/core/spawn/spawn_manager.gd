extends Node2D

@export var entities: Dictionary[String, PackedScene]
@export var entity_group_limits: Dictionary[String, int] = {"enemy": 10}

var ui_label: Label = Label.new()

func has_group_limit(group: String) -> bool:
	if not entity_group_limits.has(group):
		return false
	var group_entities = get_group(group)
	if not group_entities:
		return false
	if group_entities.size() >= entity_group_limits[group]:
		return true
	return false

func spawn(entity_name: String, spawn_position: Vector2, parent = null, group = ""):
	if group != "" and has_group_limit(group):
		return null

	if not entities.has(entity_name):
		return null
	
	var spawn_scene = entities[entity_name]
	
	var entity = spawn_scene.instantiate()
	entity.position = spawn_position
	
	if group != "":
		entity.add_to_group(group)

	if parent:
		parent.add_child(entity)
	else:
		add_child(entity)

	if entity.has_method("spawn"):
		entity.spawn(spawn_position)



	return entity

func spawn_paths(entity_name: String, spawn_position: Vector2, paths: Array[Path2D], parent = null):
	var entity = spawn(entity_name, spawn_position, parent)
	if entity:
		entity.paths = paths
	return entity

func spawn_projectile(entity_name: String, spawn_position: Vector2, direction: Vector2):
	var root = get_tree().get_root()
	var entity = spawn(entity_name, spawn_position, root)
	if entity is Projectile:
		entity.start(spawn_position, direction)
	return entity

func float_text(text: String, pos: Vector2, duration: float = 1.0, parent = null, color: Color = Color.WHITE):
	var label = Label.new()
	label.z_index = 1000
	label.text = text
	label.modulate = color
	label.position = pos
	label.material = CanvasItemMaterial.new()
	label.material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	label.add_theme_font_size_override("font_size", 16)
	if parent:
		parent.add_child(label)
	else:
		add_child(label)
	var tween = create_tween()
	tween.parallel().tween_property(label, "position", label.position + Vector2(0, -16), duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(label, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func(): label.queue_free())
	
func float_text_stay(text: String, pos: Vector2, duration: float = 1.0, parent = null, color: Color = Color.WHITE):
	ui_label.z_index = 1000
	ui_label.text = text
	ui_label.modulate = color
	ui_label.modulate.a = 0.0
	ui_label.position = pos
	ui_label.add_theme_font_size_override("font_size", 16)
	if parent:
		parent.add_child(ui_label)
	else:
		add_child(ui_label)
	var tween = create_tween()
	tween.parallel().tween_property(ui_label, "position", ui_label.position + Vector2(0, -16), duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(ui_label, "modulate:a", 1.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func fade_out_text(duration: float = 1.0):
	var tween = create_tween()
	tween.parallel().tween_property(ui_label, "position", ui_label.position + Vector2(0, 16), duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(ui_label, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func get_group(group: String):
	return get_tree().get_nodes_in_group(group)
	
func free_group(group: String):
	for node in get_group(group):
		node.queue_free()
