class_name ItemSlot extends Panel

enum ItemSlotType
{
	Inventory,
	Equipment,
	WeaponBelt
}

enum DropSlotType
{
	All,
	Equipment,
	WeaponBelt
}

@onready var icon: TextureRect = $Icon

@export var item: Item
@export var item_slot_type: ItemSlotType = ItemSlotType.Inventory
@export var can_drop_slot_type: DropSlotType = DropSlotType.All
@export var equipment_slot: Equipment.EquipmentSlotType
@export var index: int

signal swap_slots(i:int, j:int)

func _process(_delta: float) -> void:
	if Input.get_current_cursor_shape() == CURSOR_FORBIDDEN:
		DisplayServer.cursor_set_shape(DisplayServer.CURSOR_ARROW)

func set_item(i: Item):
	item = i
	_update_ui()

func get_item():
	return item

func set_index(i: int):
	index = i

func _update_ui() -> void:
	if not item:
		icon.texture = null
		return
	
	if item.texture and (item.hframes > 1 or item.vframes > 1):
		icon.texture = create_atlas_texture(item)
	else:
		icon.texture = item.texture
	
	tooltip_text = item.name

func create_atlas_texture(item_data: Item) -> AtlasTexture:
	var atlas_texture = AtlasTexture.new()
	atlas_texture.atlas = item_data.texture
	
	# Calculate frame dimensions
	var frame_width = float(item_data.texture.get_width()) / float(item_data.hframes)
	var frame_height = float(item_data.texture.get_height()) / float(item_data.vframes)
	
	# Calculate frame position
	var frame_x = (item_data.frame % item_data.hframes) * frame_width
	@warning_ignore("integer_division")
	var frame_y = (item_data.frame / item_data.hframes) * frame_height # Intentional integer division for row calculation
	
	# Set the region for this specific frame
	atlas_texture.region = Rect2(frame_x, frame_y, frame_width, frame_height)
	
	return atlas_texture

func _get_drag_data(_at_position: Vector2) -> Variant:
	if not item:
		return
	
	var preview = duplicate()
	var c = Control.new()
	c.add_child(preview)
	preview.position -= Vector2(size.x / 2, size.y / 2)
	preview.self_modulate = Color.TRANSPARENT
	c.modulate = Color(c.modulate, 0.5)
	
	set_drag_preview(c)
	icon.hide()
	return self

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if can_drop_slot_type == DropSlotType.All:
		return true
	if can_drop_slot_type == DropSlotType.Equipment:
		if data.item is Equipable and data.item.slot == equipment_slot:
			return true
	if can_drop_slot_type == DropSlotType.WeaponBelt:
		if data.item is Weapon:
			return true
	return false
	
func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if data.item_slot_type == ItemSlotType.Inventory:
		if item_slot_type == ItemSlotType.Inventory:
			swap_slots.emit(data.index, index)
			
	var tmp = item
	item = data.item
	data.item = tmp
	icon.show()
	data.show()
	_update_ui()
	data._update_ui()
	
var data_bk
func _notification(what: int) -> void:
	if what == Node.NOTIFICATION_DRAG_BEGIN:
		data_bk = get_viewport().gui_get_drag_data()
	if what == Node.NOTIFICATION_DRAG_END:
		if not is_drag_successful():
			if data_bk:
				data_bk.icon.show()
				data_bk = null
