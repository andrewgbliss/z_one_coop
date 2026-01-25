@tool
class_name Item2D extends Node2D

@export var item: Item
@export var create_random_item: bool = false
@export var sprite_material: Material

@export_tool_button("Create Random Item", "Callable") var create_random_item_action = _on_create_random_item_button_pressed
func _on_create_random_item_button_pressed():
	item = ItemCreate.create_random_item()
	set_item(item)

var sprite: Sprite2D

func _ready():
	if Engine.is_editor_hint():
		return
	if create_random_item:
		item = ItemCreate.create_random_item()
	if item:
		set_item(item)
	if sprite:
		sprite.material = sprite_material.duplicate(true)

func set_item(new_item: Item):
	if not sprite:
		sprite = Sprite2D.new()
		add_child(sprite)
	item = new_item
	sprite.texture = item.texture
	sprite.hframes = item.hframes
	sprite.vframes = item.vframes
	sprite.frame = item.frame
	if sprite and sprite.material:
		sprite.material.set_shader_parameter("rarity", item.rarity)
