@tool
class_name Armor extends Equipable

@export var defense: int = 0

func save():
	var data = super.save()
	data["defense"] = defense
	return data

func restore(data):
	super.restore(data)
	if data.has("defense"):
		defense = data["defense"]
