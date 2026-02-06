class_name ItemTextureRect extends TextureRect

@export var item: Item

func set_item(i: Item):
	item = i
	_update_ui()

func _update_ui():
	if item:
		texture = item.texture
	else:
		texture = null
