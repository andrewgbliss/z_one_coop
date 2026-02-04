@tool
@abstract
class_name Equipable extends Item

enum EquipableSlotType {
	NONE,
	HELMET,
	NECK,
	CHEST,
	WAIST,
	LEGS,
	BOOTS,
	GLOVES,
	FINGER,
	HAND
}

enum EquipableEffect {
	FIRE_DAMAGE,
	FROST_DAMAGE,
	HEALTH_REGEN,
	MANA_BOOST,
	CRITICAL_STRIKE,
	SPEED_INCREASE,
	POISON,
	DEFENSE_BOOST,
	ATTACK_BOOST,
	XP_GAIN
}

@export var slot: EquipableSlotType
@export var equip_on_pickup: bool = false
@export var handed: int = 1
@export var effect: Array[EquipableEffect] = []

func get_slot_type(s: String):
	match s:
		"head":
			return EquipableSlotType.HELMET
		"neck":
			return EquipableSlotType.NECK
		"chest":
			return EquipableSlotType.CHEST
		"waist":
			return EquipableSlotType.WAIST
		"legs":
			return EquipableSlotType.LEGS
		"feet":
			return EquipableSlotType.BOOTS
		"hands":
			return EquipableSlotType.GLOVES
		"hand":
			return EquipableSlotType.HAND
		_:
			return EquipableSlotType.NONE

func save_slot_type(s: EquipableSlotType):
	match s:
		EquipableSlotType.HELMET:
			return "head"
		EquipableSlotType.NECK:
			return "neck"
		EquipableSlotType.CHEST:
			return "chest"
		EquipableSlotType.WAIST:
			return "waist"
		EquipableSlotType.LEGS:
			return "legs"
		EquipableSlotType.BOOTS:
			return "feet"
		EquipableSlotType.GLOVES:
			return "hands"
		EquipableSlotType.HAND:
			return "hand"
		_:
			return "none"

func save():
	var data = super.save()
	
	data["slot"] = save_slot_type(slot)
	data["equip_on_pickup"] = equip_on_pickup
	data["effect"] = effect
	return data

func restore(data):
	super.restore(data)
	if data.has("slot"):
		slot = get_slot_type(data["slot"])
	if data.has("equip_on_pickup"):
		equip_on_pickup = data["equip_on_pickup"]
	if data.has("effect"):
		effect = data["effect"]
