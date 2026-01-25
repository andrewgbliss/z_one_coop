@tool
class_name Equipment extends Resource

enum EquipmentSlotType {
	NONE,
	HELMET,
	NECK,
	CHEST,
	WAIST,
	LEGS,
	BOOTS,
	GLOVES,
	LEFT_FINGER,
	RIGHT_FINGER,
	LEFT_HAND,
	RIGHT_HAND
}

@export var head: Equipable
@export var neck: Equipable
@export var chest: Equipable
@export var waist: Equipable
@export var legs: Equipable
@export var feet: Equipable
@export var hand: Equipable
@export var left_finger: Equipable
@export var right_finger: Equipable
@export var left_hand: Equipable
@export var right_hand: Equipable

signal equipment_change

							
func equip(item: Item, equipment_slot_type: EquipmentSlotType):
	match equipment_slot_type:
		EquipmentSlotType.HELMET:
			head = item
		EquipmentSlotType.NECK:
			neck = item
		EquipmentSlotType.CHEST:
			chest = item
		EquipmentSlotType.WAIST:
			waist = item
		EquipmentSlotType.LEGS:
			legs = item
		EquipmentSlotType.BOOTS:
			feet = item
		EquipmentSlotType.LEFT_HAND:
			left_hand = item
		EquipmentSlotType.RIGHT_HAND:
			right_hand = item
		EquipmentSlotType.LEFT_FINGER:
			left_finger = item
		EquipmentSlotType.RIGHT_FINGER:
			right_finger = item
	equipment_change.emit()
	
func unequip(equipment_slot_type: EquipmentSlotType):
	match equipment_slot_type:
		EquipmentSlotType.HELMET:
			head = null
		EquipmentSlotType.NECK:
			neck = null
		EquipmentSlotType.CHEST:
			chest = null
		EquipmentSlotType.WAIST:
			waist = null
		EquipmentSlotType.LEGS:
			legs = null
		EquipmentSlotType.BOOTS:
			feet = null
		EquipmentSlotType.LEFT_HAND:
			left_hand = null
		EquipmentSlotType.RIGHT_HAND:
			right_hand = null
		EquipmentSlotType.LEFT_FINGER:
			left_finger = null
		EquipmentSlotType.RIGHT_FINGER:
			right_finger = null
	equipment_change.emit()

func get_slot_type(slot_type: Equipable.EquipableSlotType) -> EquipmentSlotType:
	if slot_type == Equipable.EquipableSlotType.HELMET:
		return EquipmentSlotType.HELMET
	if slot_type == Equipable.EquipableSlotType.NECK:
		return EquipmentSlotType.NECK
	if slot_type == Equipable.EquipableSlotType.CHEST:
		return EquipmentSlotType.CHEST
	if slot_type == Equipable.EquipableSlotType.WAIST:
		return EquipmentSlotType.WAIST
	if slot_type == Equipable.EquipableSlotType.LEGS:
		return EquipmentSlotType.LEGS
	if slot_type == Equipable.EquipableSlotType.BOOTS:
		return EquipmentSlotType.BOOTS
	if slot_type == Equipable.EquipableSlotType.GLOVES:
		return EquipmentSlotType.GLOVES
	if slot_type == Equipable.EquipableSlotType.FINGER:
		return EquipmentSlotType.LEFT_FINGER
	if slot_type == Equipable.EquipableSlotType.FINGER:
		return EquipmentSlotType.RIGHT_FINGER
	if slot_type == Equipable.EquipableSlotType.HAND:
		return EquipmentSlotType.LEFT_HAND
	if slot_type == Equipable.EquipableSlotType.HAND:
		return EquipmentSlotType.RIGHT_HAND
	return EquipmentSlotType.NONE


func save():
	var data = {
		"head": head,
		"neck": neck,
		"chest": chest,
		"waist": waist,
		"legs": legs,
		"feet": feet,
		"hand": hand,
		"left_finger": left_finger,
		"right_finger": right_finger,
		"left_hand": left_hand,
		"right_hand": right_hand
	}
	return data

func restore(data):
	if data.has("head"):
		head = data["head"]
	if data.has("neck"):
		neck = data["neck"]
	if data.has("chest"):
		chest = data["chest"]
	if data.has("waist"):
		waist = data["waist"]
	if data.has("legs"):
		legs = data["legs"]
	if data.has("feet"):
		feet = data["feet"]
	if data.has("hand"):
		hand = data["hand"]
	if data.has("left_finger"):
		left_finger = data["left_finger"]
	if data.has("right_finger"):
		right_finger = data["right_finger"]
	if data.has("left_hand"):
		left_hand = data["left_hand"]
	if data.has("right_hand"):
		right_hand = data["right_hand"]
