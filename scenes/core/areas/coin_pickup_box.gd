class_name CoinPickupBox extends Area2D

signal picked_up(item: Item)

func item_pickup(item: Item) -> bool:
	picked_up.emit(item)
	return true