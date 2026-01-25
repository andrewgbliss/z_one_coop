@tool
@abstract
class_name Item extends Resource

enum Rarity {
	COMMON,
	UNCOMMON,
	RARE,
	EPIC,
	LEGENDARY
}

@export var package: String = ""
@export var name: String = ""
@export var description: String = ""
@export var is_level_unique: bool = false
@export var is_game_unique: bool = false
@export var is_stackable: bool = false
@export var max_stackable_count: int = 1
@export var texture: Texture2D
@export var frame: int
@export var hframes: int = 1
@export var vframes: int = 1
@export var rarity: Rarity = Rarity.COMMON

func save():
	var data = {
		"name": name,
		"description": description,
		"is_level_unique": is_level_unique,
		"is_game_unique": is_game_unique,
		"is_stackable": is_stackable,
		"max_stackable_count": max_stackable_count,
		"texture": texture,
		"frame": frame,
		"hframes": hframes,
		"vframes": vframes,
		"rarity": rarity,
	}
	return data

func restore(data):
	if data.has("name"):
		name = data["name"]
	if data.has("description"):
		description = data["description"]
	if data.has("is_level_unique"):
		is_level_unique = data["is_level_unique"]
	if data.has("is_game_unique"):
		is_game_unique = data["is_game_unique"]
	if data.has("is_stackable"):
		is_stackable = data["is_stackable"]
	if data.has("max_stackable_count"):
		max_stackable_count = data["max_stackable_count"]
	if data.has("texture"):
		texture = data["texture"]
	if data.has("frame"):
		frame = data["frame"]
	if data.has("hframes"):
		hframes = data["hframes"]
	if data.has("vframes"):
		vframes = data["vframes"]
	if data.has("rarity"):
		rarity = data["rarity"]
