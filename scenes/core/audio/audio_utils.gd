class_name AudioUtils extends Node
	
static func set_volume(bus_idx: int, volume: float):
	if (volume == 0):
		AudioServer.set_bus_mute(bus_idx, true)
	else:
		if AudioServer.is_bus_mute(bus_idx):
			AudioServer.set_bus_mute(bus_idx, false)
		var db = convert_percent_to_db(volume)
		AudioServer.set_bus_volume_db(bus_idx, db)
	
static func convert_percent_to_db(percent: float) -> float:
	var scale = 20.0
	var divisor = 50.0
	return scale * log(percent / divisor) / log(10.0)

static func load_mp3(p: String):
	var file = FileAccess.open(p, FileAccess.READ)
	var sound = AudioStreamMP3.new()
	sound.data = file.get_buffer(file.get_length())
	return sound
