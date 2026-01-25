@tool
extends Node

var data_store = {}
var data_store_dir = "res://data/"

var is_loaded = false

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_create_data_store()

func _create_data_store():
	if is_loaded:
		return
	is_loaded = true
	var files = FilesUtil.find_files(data_store_dir, "json")
	# Create nested structure based on directory paths
	for file_info in files:
		var file_data = FilesUtil.restore(file_info.full_path)
		if file_data != null:
			var current_dict = data_store
			# Navigate through directory structure
			for dir_name in file_info.path:
				if not current_dict.has(dir_name):
					current_dict[dir_name] = {}
				current_dict = current_dict[dir_name]
			
			# Store file data using filename without extension as key
			var file_key = file_info.filename.get_basename()
			current_dict[file_key] = file_data
		else:
			print("Failed to load: ", file_info.full_path)

# Get data from nested path (e.g., "items/currency" or "soundtracks/chiptune_1")
func get_store_by_path(path: String) -> Dictionary:
	if not is_loaded:
		_create_data_store()
	var path_parts = path.split("/")
	var current_dict = data_store
	
	for part in path_parts:
		if current_dict.has(part):
			current_dict = current_dict[part]
		else:
			print("Path not found: ", path, " at part: ", part)
			return {}
	
	return current_dict

# Get all data under a specific directory (e.g., all items)
func get_store_directory(directory: String) -> Dictionary:
	if not is_loaded:
		_create_data_store()
	if data_store.has(directory):
		return data_store[directory]
	else:
		print("Directory not found: ", directory)
		return {}
