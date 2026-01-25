class_name CharacterBlackboard extends Resource

enum CharacterControllerType {PLAYER, NPC}
enum CharacterRace {Dwarf, Elf, Halfling, Human, Dragonborn, Gnome, HalfElf, HalfOrc}
enum CharacterClassType {Barbarian, Bard, Cleric, Druid, Fighter, Monk, Paladin, Ranger, Rogue, Sorcerer, Warlock, Wizard}
enum CharacterGender {Male, Female}

@export var character_name: String = ""
@export var character_controller_type: CharacterControllerType = CharacterControllerType.PLAYER

@export_group("Type")
@export var race: CharacterRace = CharacterRace.Human
@export var class_type: CharacterClassType = CharacterClassType.Fighter
@export var gender: CharacterGender = CharacterGender.Male
@export_range(-1.0, 1.0) var alignment: float = 0.0

@export_group("Points")
@export var level: int = 0
@export var health: int = 0
@export var max_health: int = 0
@export var armor: int = 0
@export var max_armor: int = 0
@export var mana: int = 0
@export var max_mana: int = 0
@export var stamina: int = 0
@export var max_stamina: int = 0
@export var special: int = 0
@export var max_special: int = 0
@export var xp: int = 0
@export var max_xp: int = 0

@export_group("Stats")
@export var strength: int = 0
@export var dexterity: int = 0
@export var constitution: int = 0
@export var intelligence: int = 0
@export var wisdom: int = 0
@export var charisma: int = 0
@export var attack: int = 0

signal health_changed(health_change: int, max_health: int)
signal armor_changed(armor_change: int, max_armor: int)
signal mana_changed(mana_change: int, max_mana: int)
signal stamina_changed(stamina_change: int, max_stamina: int)
signal special_changed(special_change: int, max_special: int)
signal alignment_changed(alignment: float)
signal level_changed(level: int)

@export_group("Physics")
@export var speed: float = 300.0
@export var acceleration: float = 100.0
@export var friction: float = 50.0
@export var max_velocity: Vector2 = Vector2(1000.0, 1000.0)
@export var direction: Vector2
@export var aim_direction: Vector2
@export var dash_speed: float = 600.0
@export var dash_time: float = 0.05
@export var run_multiplier: float = 2.0
@export var velocity: Vector2
@export var knockback_force: float = 500.0
@export var is_facing_right: bool = true

@export_group("Inventory")
@export var inventory: Inventory
@export var equipment: Equipment
@export var item_belt: ItemBelt

func reset():
	level = 0
	health = 0
	max_health = 0
	mana = 0
	max_mana = 0
	stamina = 0
	max_stamina = 0
	special = 0
	max_special = 0
	strength = 0
	dexterity = 0
	constitution = 0
	intelligence = 0
	wisdom = 0
	charisma = 0
	attack = 0
	health_changed.emit(health, max_health)
	armor_changed.emit(armor, max_armor)
	mana_changed.emit(mana, max_mana)
	stamina_changed.emit(stamina, max_stamina)
	special_changed.emit(special, max_special)

func spawn_reset():
	health = max_health
	mana = max_mana
	stamina = max_stamina
	health_changed.emit(health, max_health)
	mana_changed.emit(mana, max_mana)
	stamina_changed.emit(stamina, max_stamina)

func take_damage(amount: int):
	if armor > 0:
		armor -= amount
		armor_changed.emit(armor, max_armor)
		if armor > 0:
			return
	health -= amount
	health_changed.emit(health, max_health)
	if health <= 0:
		health_changed.emit(health, max_health)

func set_alignment(value: float):
	alignment = clamp(value, -1.0, 1.0)
	alignment_changed.emit(alignment)

func change_alignment(value: float):
	set_alignment(alignment + value)

func is_good():
	return alignment > 0.3

func is_evil():
	return alignment < -0.3

func is_neutral():
	return alignment >= -0.3 and alignment <= 0.3

func get_heat_stars():
	if alignment >= 0:
		return ""
	elif alignment >= -0.25:
		return "*"
	elif alignment >= -0.5:
		return "**"
	elif alignment >= -0.75:
		return "***"
	elif alignment >= -1:
		return "****"

func get_heat() -> int:
	if alignment >= 0:
		return 0
	elif alignment >= -0.25:
		return 1
	elif alignment >= -0.5:
		return 2
	elif alignment >= -0.75:
		return 3
	elif alignment >= -1:
		return 4
	return 0

func set_health(value: int):
	health = clamp(value, 0, max_health)
	health_changed.emit(health, max_health)
	
func set_armor(value: int):
	armor = clamp(value, 0, max_armor)
	armor_changed.emit(armor, max_armor)

func set_mana(value: int):
	mana = clamp(value, 0, max_mana)
	mana_changed.emit(mana, max_mana)

func set_stamina(value: int):
	stamina = clamp(value, 0, max_stamina)
	stamina_changed.emit(stamina, max_stamina)

func set_special(value: int):
	special = clamp(value, 0, max_special)
	special_changed.emit(special, max_special)

func add_health(value: int):
	set_health(health + value)

func add_mana(value: int):
	set_mana(mana + value)

func add_stamina(value: int):
	set_stamina(stamina + value)

func add_xp(value: int):
	xp += value
	if xp >= max_xp:
		level += 1
		xp = 0
		max_xp = 100
		health_changed.emit(health, max_health)

func add_level(value: int):
	level += value
	level_changed.emit(level)

func add_armor(value: int):
	armor += value
	if armor > max_armor:
		armor = max_armor
	armor_changed.emit(armor, max_armor)

func serialize():
	var data = {
		"character_name": character_name,
		"character_controller_type": character_controller_type,
		"race": race,
		"class_type": class_type,
		"level": level,
		"strength": strength,
		"dexterity": dexterity,
		"constitution": constitution,
		"intelligence": intelligence,
		"wisdom": wisdom,
		"charisma": charisma,
		"attack": attack,
		"health": health,
		"max_health": max_health,
		"armor": armor,
		"max_armor": max_armor,
		"mana": mana,
		"max_mana": max_mana,
		"stamina": stamina,
		"max_stamina": max_stamina,
		"special": special,
		"max_special": max_special,
		"alignment": alignment,
		"speed": speed,
		"acceleration": acceleration,
		"friction": friction,
		"max_velocity_x": max_velocity.x,
		"max_velocity_y": max_velocity.y,
		"direction_x": direction.x,
		"direction_y": direction.y,
		"aim_direction_x": aim_direction.x,
		"aim_direction_y": aim_direction.y,
		"dash_speed": dash_speed,
		"dash_time": dash_time,
		"run_multiplier": run_multiplier,
		"velocity_x": velocity.x,
		"velocity_y": velocity.y,
		"is_facing_right": is_facing_right
	}
	return data

func deserialize(data):
	if data.has("character_name"):
		character_name = data.get("character_name")
	if data.has("character_controller_type"):
		character_controller_type = data.get("character_controller_type")
	if data.has("race"):
		race = data.get("race")
	if data.has("class_type"):
		class_type = data.get("class_type")
	if data.has("level"):
		level = data.get("level")
	if data.has("strength"):
		strength = data.get("strength")
	if data.has("dexterity"):
		dexterity = data.get("dexterity")
	if data.has("constitution"):
		constitution = data.get("constitution")
	if data.has("intelligence"):
		intelligence = data.get("intelligence")
	if data.has("wisdom"):
		wisdom = data.get("wisdom")
	if data.has("charisma"):
		charisma = data.get("charisma")
	if data.has("attack"):
		attack = data.get("attack")
	if data.has("health"):
		health = data.get("health")
	if data.has("max_health"):
		max_health = data.get("max_health")
	if data.has("armor"):
		armor = data.get("armor")
	if data.has("max_armor"):
		max_armor = data.get("max_armor")
	if data.has("mana"):
		mana = data.get("mana")
	if data.has("max_mana"):
		max_mana = data.get("max_mana")
	if data.has("stamina"):
		stamina = data.get("stamina")
	if data.has("max_stamina"):
		max_stamina = data.get("max_stamina")
	if data.has("special"):
		special = data.get("special")
	if data.has("max_special"):
		max_special = data.get("max_special")
	if data.has("alignment"):
		alignment = data.get("alignment")
	if data.has("speed"):
		speed = data["speed"]
	if data.has("acceleration"):
		acceleration = data["acceleration"]
	if data.has("friction"):
		friction = data["friction"]
	if data.has("max_velocity_x") and data.has("max_velocity_y"):
		max_velocity = Vector2(data["max_velocity_x"], data["max_velocity_y"])
	if data.has("direction_x") and data.has("direction_y"):
		direction = Vector2(data["direction_x"], data["direction_y"])
	if data.has("aim_direction_x") and data.has("aim_direction_y"):
		aim_direction = Vector2(data["aim_direction_x"], data["aim_direction_y"])
	if data.has("dash_speed"):
		dash_speed = data["dash_speed"]
	if data.has("dash_time"):
		dash_time = data["dash_time"]
	if data.has("run_multiplier"):
		run_multiplier = data["run_multiplier"]
	if data.has("velocity_x") and data.has("velocity_y"):
		velocity = Vector2(data["velocity_x"], data["velocity_y"])
	if data.has("is_facing_right"):
		is_facing_right = data["is_facing_right"]
