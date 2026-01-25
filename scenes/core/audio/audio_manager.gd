extends Node

@export var audio_config: AudioConfig

var audio: Dictionary[String, AudioStreamPlayer] = {}

func _ready():
	for child in get_children():
		if child is AudioStreamPlayer:
			audio[child.name] = child

func play(node_name: String):
	audio[node_name].play()

func play_random(names):
	var random_index = randi_range(0, names.size() - 1)
	audio[names[random_index]].play()

func play_and_wait(node_name: String):
	audio[node_name].play()
	await audio[node_name].finished

func stop(node_name: String):
	audio[node_name].stop()

func is_playing(node_name):
	return audio[node_name].playing
