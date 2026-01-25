@tool
class_name ItemBelt extends Resource

@export var items: Array[Item] = []

signal belt_slot_changed(slot: int, item: Item)

func set_belt_slot(slot: int, item: Item):
	if slot > 0 and slot <= items.size():
		items[slot] = item
		belt_slot_changed.emit(slot, item)

func set_next_belt_slot(item: Item):
	var next_empty_slot = items.find(null)
	if next_empty_slot == -1:
		return false
	set_belt_slot(next_empty_slot, item)
	return true

func get_slot(slot: int):
	if items.size() <= slot:
		return null
	return items[slot]

func save():
	var data = {
		"items": items.map(func(item): return item.save() if item else null),
	}
	return data

func restore(data):
	if data.has("items"):
		items = data["items"]

func swap_slots(from_index: int, to_index: int):
	items[from_index] = items[to_index]
	items[to_index] = items[from_index]
