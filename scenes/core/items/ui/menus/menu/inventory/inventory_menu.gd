extends Menu

@export var inventory: Inventory
@export var equipment: Equipment
@export var item_belt: ItemBelt

@export var inventory_ui: InventoryGridUI
@export var equipment_ui: EquipmentUI
@export var item_belt_ui: ItemBeltUI

func _ready():
	super()
	inventory_ui.inventory = inventory
	equipment_ui.equipment = equipment
	item_belt_ui.item_belt = item_belt
