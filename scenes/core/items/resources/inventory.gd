@tool
class_name Inventory extends Resource

@export var gold: int = 0
@export var max_gold: int = 10000
@export var max_slots: int = 50
@export var items: Array[Item] = []

signal item_added(item: Item)
signal item_removed(item: Item)
signal gold_changed(gold: int)
	
func add(new_item: Item):
	var item = new_item.duplicate()
	# Duplicate the resource to make a brand new instance to put into inventory
	# The bad side of this will make the in_inventory function not work
	# since its checking the actual object and not some id
	
	if in_inventory(item) and item.has("is_unique") and item.is_unique:
		print("Item is unique")
		return
		
	if in_inventory(item) and item.has("is_stackable") and item.has("max_stackable_count") and item.is_stackable and item.quantity < item.max_stackable_count:
		print("Add quantity")
		add_quantity(item, item.quantity)
		return

	var slot_index = get_next_available_slot()
	if slot_index >= 0:
		if items[slot_index] == null:
			var prev_index = get_slot_index(item)
			items[slot_index] = item
			items[prev_index] = null
			
	item_added.emit(item)

	return item
	
func remove(item: Item):
	items.erase(item)
	item_removed.emit(item)

func add_quantity(item: Item, amount: int):
	item.quantity += amount
	if item.quantity <= 0:
		remove(item)
	item_removed.emit(item, Vector2.ZERO)
	pass
	
func add_gold(item: Item):
	gold += item.amount
	if gold > max_gold:
		gold = max_gold
	gold_changed.emit(gold)
	
func in_inventory(item: Item):
	var index = items.find(item)
	return index != -1
	
func get_slot(slot_index: int) -> Item:
	if items.size() > 0 and slot_index < items.size():
		return items[slot_index]
	else:
		return null
			
func get_slot_index(item: Item):
	return items.find(item)
	
func get_next_available_slot():
	for i in items.size():
		if items[i] == null:
			return i
	return -1

func set_slot(slot_index: int, item: Item):
	if slot_index >= 0 and slot_index < items.size():
		items[slot_index] = item
		return true
	return false

func swap_slots(from_index: int, to_index: int):
	if from_index >= 0 and from_index < items.size() and to_index >= 0 and to_index < items.size():
		var tmp = items[from_index]
		items[from_index] = items[to_index]
		items[to_index] = tmp
		return true
	return false

func save():
	var data = {
		"gold": gold,
		"items": items.map(func(item): return item.save() if item else null)
	}
	return data
	
func restore(data):
	if data.has("gold"):
		gold = data["gold"]
	if data.has("items"):
		items = data["items"].map(func(item: Item): return item.restore(item))

func print_inventory():
	print("Inventory: ", save())
