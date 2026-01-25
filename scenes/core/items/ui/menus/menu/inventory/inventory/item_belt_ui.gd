class_name ItemBeltUI extends GridContainer

var item_belt: ItemBelt

func _on_belt_slot_changed(_slot: int, _weapon: Weapon):
	_update_ui()

func _update_ui():
	var children = get_children()
	for i in range(children.size()):
		var child = children[i]
		if child is ItemSlot:
			child.set_index(i)
			var item = item_belt.get_slot(child.get_index())
			if item:
				child.set_item(item)
