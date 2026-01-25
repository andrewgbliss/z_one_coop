class_name EquipmentUI extends Panel

@export var helmet_slot: ItemSlot
@export var neck_slot: ItemSlot
@export var chest_slot: ItemSlot
@export var waist_slot: ItemSlot
@export var legs_slot: ItemSlot
@export var feet_slot: ItemSlot
@export var gloves_slot: ItemSlot
@export var left_finger_slot: ItemSlot
@export var right_finger_slot: ItemSlot
@export var left_hand_slot: ItemSlot
@export var right_hand_slot: ItemSlot

var equipment: Equipment

func _on_equipment_change():
	_update_ui()

func _update_ui() -> void:
	helmet_slot.set_item(equipment.head)
	neck_slot.set_item(equipment.neck)
	chest_slot.set_item(equipment.chest)
	waist_slot.set_item(equipment.waist)
	legs_slot.set_item(equipment.legs)
	feet_slot.set_item(equipment.feet)
	gloves_slot.set_item(equipment.hand)
	left_finger_slot.set_item(equipment.left_finger)
	right_finger_slot.set_item(equipment.right_finger)
	left_hand_slot.set_item(equipment.left_hand)
	right_hand_slot.set_item(equipment.right_hand)
