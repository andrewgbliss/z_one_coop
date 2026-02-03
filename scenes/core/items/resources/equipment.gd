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

signal equipment_changed

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
	equipment_changed.emit()
	
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
	equipment_changed.emit()

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
	var data = {}
	if head:
		data["head"] = head.save()
	if neck:
		data["neck"] = neck.save()
	if chest:
		data["chest"] = chest.save()
	if waist:
		data["waist"] = waist.save()
	if legs:
		data["legs"] = legs.save()
	if feet:
		data["feet"] = feet.save()
	if hand:
		data["hand"] = hand.save()
	if left_finger:
		data["left_finger"] = left_finger.save()
	if right_finger:
		data["right_finger"] = right_finger.save()
	if left_hand:
		data["left_hand"] = left_hand.save()
	if right_hand:
		data["right_hand"] = right_hand.save()
	return data

func restore(data):
	if data.has("head"):
		head = Armor.new()
		head.restore(data["head"])
	if data.has("neck"):
		neck = Armor.new()
		neck.restore(data["neck"])
	if data.has("chest"):
		chest = Armor.new()
		chest.restore(data["chest"])
	if data.has("waist"):
		waist = Armor.new()
		waist.restore(data["waist"])
	if data.has("legs"):
		legs = Armor.new()
		legs.restore(data["legs"])
	if data.has("feet"):
		feet = Armor.new()
		feet.restore(data["feet"])
	if data.has("hand"):
		hand = Armor.new()
		hand.restore(data["hand"])
	if data.has("left_finger"):
		left_finger = Armor.new()
		left_finger.restore(data["left_finger"])
	if data.has("right_finger"):
		right_finger = Armor.new()
		right_finger.restore(data["right_finger"])
	if data.has("left_hand"):
		left_hand = Weapon.new()
		left_hand.restore(data["left_hand"])
	if data.has("right_hand"):
		right_hand = Weapon.new()
		right_hand.restore(data["right_hand"])
