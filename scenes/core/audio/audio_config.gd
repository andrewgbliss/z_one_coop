class_name AudioConfig extends Resource

@export var master_volume: float = 50.0
@export var music_volume: float = 50.0
@export var ambience_volume: float = 50.0
@export var effects_volume: float = 50.0

func _init():
	var data = FilesUtil.restore_or_create("user://audio_config.json", save())
	if data != null:
		restore(data)
	
func get_volume(bus_idx: int) -> float:
	match bus_idx:
		0: return master_volume
		1: return music_volume
		2: return ambience_volume
		3: return effects_volume
	return 0.0

func set_volume(bus_idx: int, volume: float):
	match bus_idx:
		0: master_volume = volume
		1: music_volume = volume
		2: ambience_volume = volume
		3: effects_volume = volume
	AudioUtils.set_volume(bus_idx, volume)
	save_to_file()

func save():
	return {
		"master_volume": master_volume,
		"music_volume": music_volume,
		"ambience_volume": ambience_volume,
		"effects_volume": effects_volume
	}

func restore(data):
	if data.has("master_volume"):
		master_volume = data["master_volume"]
	if data.has("music_volume"):
		music_volume = data["music_volume"]
	if data.has("ambience_volume"):
		ambience_volume = data["ambience_volume"]
	if data.has("effects_volume"):
		effects_volume = data["effects_volume"]

func save_to_file():
	var save_data = save()
	FilesUtil.save("user://audio_config.json", save_data)

func reset():
	master_volume = 50.0
	music_volume = 50.0
	ambience_volume = 50.0
	effects_volume = 50.0
	save_to_file()
