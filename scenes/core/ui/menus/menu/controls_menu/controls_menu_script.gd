class_name ControlsMenuScript extends Menu

@export var overlay_scene: PackedScene
@export var action_list_container: VBoxContainer
@export var reset_button: Button
@export var back_button: Button

# Input listener overlay
var input_listener: InputListenerOverlay

# Hardcoded list of actions to display in the controls menu
var input_actions = [
	{"name": "move_left", "display_name": "Move Left"},
	{"name": "move_right", "display_name": "Move Right"},
	{"name": "move_up", "display_name": "Move Up"},
	{"name": "move_down", "display_name": "Move Down"},
	{"name": "run", "display_name": "Run"},
	{"name": "dash", "display_name": "Dash"},
	{"name": "jump", "display_name": "Jump"},
	{"name": "attack_left_hand", "display_name": "Attack Left Hand"},
	{"name": "attack_right_hand", "display_name": "Attack Right Hand"},
	{"name": "aim_left", "display_name": "Aim Left"},
	{"name": "aim_right", "display_name": "Aim Right"},
	{"name": "aim_up", "display_name": "Aim Up"},
	{"name": "aim_down", "display_name": "Aim Down"},
	{"name": "pause", "display_name": "Pause"},
	{"name": "take", "display_name": "Take/Interact"},
	{"name": "rewind", "display_name": "Rewind"},
	{"name": "inventory", "display_name": "Inventory"},
	{"name": "character_sheet", "display_name": "Character Sheet"}
]

var action_buttons: Array[ControlsInputButton] = []

func _ready():
	super._ready()
	create_controls_display()
	create_input_listener()
	load_key_bindings()
	
	if reset_button:
		reset_button.pressed.connect(_on_reset_button_pressed)
	
	if back_button:
		back_button.pressed.connect(_on_back_button_pressed)

func _enter_tree():
	load_key_bindings()

func create_controls_display():
	if not action_list_container:
		return
	
	# Clear existing children
	for child in action_list_container.get_children():
		child.queue_free()
	
	action_buttons.clear()
	
	# Create header
	var header_label = Label.new()
	header_label.text = "Current Key Bindings:"
	header_label.add_theme_font_size_override("font_size", 16)
	action_list_container.add_child(header_label)
	
	# Add separator
	var separator = HSeparator.new()
	action_list_container.add_child(separator)
	
	# Create control entries for each action
	for action_data in input_actions:
		create_action_entry(action_data)

func create_action_entry(action_data: Dictionary):
	var action_name = action_data["name"]
	var display_name = action_data["display_name"]
	
	# Create container for this action
	var action_container = HBoxContainer.new()
	action_container.custom_minimum_size.y = 30
	
	# Create label for action name
	var action_label = Label.new()
	action_label.text = display_name + ":"
	action_label.custom_minimum_size.x = 150
	action_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	action_container.add_child(action_label)
	
	# Create ControlsInputButton to show current key binding
	var key_button = ControlsInputButton.new()
	key_button.set_action(action_name)
	key_button.binding_changed.connect(_on_binding_changed)
	action_container.add_child(key_button)
	
	action_buttons.append(key_button)
	action_list_container.add_child(action_container)


func _on_reset_button_pressed():
	pass
	#var user_config = GameManager.get_user_config()
	#if user_config:
		#user_config.reset_key_bindings()
		#refresh_display()

func _on_back_button_pressed():
	# This will be handled by the menu stack system
	pass

func refresh_display():
	# Refresh all existing buttons instead of recreating the whole display
	for button in action_buttons:
		if button and is_instance_valid(button):
			button.refresh()

func create_input_listener():
	input_listener = overlay_scene.instantiate()
	
	if input_listener:
		# Add it to the scene tree
		add_child(input_listener)
		
		# Make sure it's on top
		input_listener.z_index = 100

func get_input_listener() -> InputListenerOverlay:
	return input_listener


func _on_binding_changed(_action: String, _event: InputEvent):
	# Refresh all buttons to show updated bindings
	refresh_display()
	
	# Save the key bindings immediately
	save_key_bindings()
	
	# Also save the single binding immediately to user config
	#var user_config = GameManager.get_user_config()
	#if user_config:
		#var events = InputMap.action_get_events(action)
		#user_config.save_single_key_binding(action, events)

func save_key_bindings():
	var bindings = {}
	for action_data in input_actions:
		var action_name = action_data["name"]
		var events = InputMap.action_get_events(action_name)
		var event_data = []
		
		for event in events:
			event_data.append(_serialize_input_event(event))
		
		bindings[action_name] = event_data
	
	
	# Save to UserConfig
	#var user_config = GameManager.get_user_config()
	#if user_config:
		#user_config.save_key_bindings(bindings)

func load_key_bindings():
	"""Load key bindings from user config"""
	#var user_config = GameManager.get_user_config()
	#if user_config:
		#user_config.apply_key_bindings()
		#refresh_display()

func _serialize_input_event(event: InputEvent) -> Dictionary:
	var data = {}
	
	if event is InputEventKey:
		data["type"] = "key"
		data["keycode"] = event.keycode
		data["physical_keycode"] = event.physical_keycode
	elif event is InputEventMouseButton:
		data["type"] = "mouse_button"
		data["button_index"] = event.button_index
	elif event is InputEventJoypadButton:
		data["type"] = "joypad_button"
		data["button_index"] = event.button_index
	elif event is InputEventJoypadMotion:
		data["type"] = "joypad_motion"
		data["axis"] = event.axis
		data["axis_value"] = event.axis_value
	
	return data

func _deserialize_input_event(data: Dictionary) -> InputEvent:
	match data.get("type", ""):
		"key":
			var event = InputEventKey.new()
			event.keycode = data.get("keycode", 0)
			event.physical_keycode = data.get("physical_keycode", 0)
			return event
		"mouse_button":
			var event = InputEventMouseButton.new()
			event.button_index = data.get("button_index", 0)
			return event
		"joypad_button":
			var event = InputEventJoypadButton.new()
			event.button_index = data.get("button_index", 0)
			return event
		"joypad_motion":
			var event = InputEventJoypadMotion.new()
			event.axis = data.get("axis", 0)
			event.axis_value = data.get("axis_value", 0.0)
			return event
	
	return null
