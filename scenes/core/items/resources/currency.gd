@tool
class_name Currency extends Item

@export var amount: int = 0

func save():
	var data = super.save()
	data["amount"] = amount
	return data

func restore(data):
	super.restore(data)
	if data.has("amount"):
		amount = int(data["amount"])
