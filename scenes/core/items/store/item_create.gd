@tool
class_name ItemCreate extends Node

static func create_item(key: StringName, item_name: String) -> Item:
	var store = DataStore.get_store_by_path(key)

	if store == null:
		print("Store not found: ", key)
		return null

	if not store.has("items"):
		print("Store has no items: ", key)
		return null
	
	var item_index = store.items.find_custom(func(item): return item.name == item_name)

	if item_index == -1:
		print("Item not found: ", item_name)
		return null
	
	var item_data = store.items[item_index]

	if not store.has("spriteSheet"):
		print("Store has no spriteSheet: ", key)
		return null

	if not store.spriteSheet.has("atlas"):
		print("SpriteSheet has no atlas: ", key)
		return null

	var sprite_sheet = store.spriteSheet
	var atlas = sprite_sheet.atlas

	if not item_data.has("type"):
		print("Item has no type: ", item_name)
		return null

	if item_data.type == "currency":
		return create_currency(item_data, atlas)
	elif item_data.type == "weapon":
		return create_weapon(item_data, atlas)
	elif item_data.type == "armor":
		return create_armor(item_data, atlas)
	elif item_data.type == "consumable":
		return create_consumable(item_data, atlas)

	return null

static func fill_texture(item: Item, item_data, atlas):
	if atlas != null:
		if atlas.has("path"):
			item.texture = load(atlas.path)
		if atlas.has("hframes"):
			item.hframes = atlas.hframes
		if atlas.has("vframes"):
			item.vframes = atlas.vframes
		if item_data.has("frame"):
			item.frame = item_data.frame

static func create_currency(item_data, atlas):
	var currency = Currency.new()
	currency.restore(item_data)
	fill_texture(currency, item_data, atlas)
	return currency

static func create_weapon(item_data, atlas):
	var weapon = Weapon.new()
	weapon.restore(item_data)
	fill_texture(weapon, item_data, atlas)
	return weapon

static func create_armor(item_data, atlas):
	var armor = Armor.new()
	armor.restore(item_data)
	fill_texture(armor, item_data, atlas)
	return armor

static func create_consumable(item_data, atlas):
	var consumable = Consumable.new()
	consumable.restore(item_data)
	fill_texture(consumable, item_data, atlas)
	return consumable

static func create_random_item() -> Item:
	var items = DataStore.get_store_directory("items")
	var random_key = items.keys().pick_random()
	var random_store = items[random_key]
	var random_item = random_store.items.pick_random()
	if random_item:
		return create_item("items/" + random_key, random_item.name)
	return null
