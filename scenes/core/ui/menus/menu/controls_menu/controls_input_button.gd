class_name ControlsInputButton extends Button

var action_name: String = ""
var input_listener: InputListenerOverlay
var controls_menu: ControlsMenuScript

signal binding_changed(action: String, event: InputEvent)

func _ready():
	# Enable the button for interaction
	disabled = false
	custom_minimum_size.x = 120
	
	# Connect the button press signal
	pressed.connect(_on_button_pressed)


func set_action(action: String):
	"""Set the action name and update the display text"""
	action_name = action
	update_display_text()

func update_display_text():
	"""Update the button text to show current keybindings"""
	if action_name.is_empty():
		text = "Not Set"
		return
	
	text = get_action_display_text(action_name)

func get_action_display_text(action: String) -> String:
	"""Get the display text for an action's current keybindings"""
	var events = InputMap.action_get_events(action)
	if events.is_empty():
		return "Not Set"
	
	var display_texts = []
	for event in events:
		display_texts.append(get_event_display_text(event))
	
	return ", ".join(display_texts)

func get_event_display_text(event: InputEvent) -> String:
	"""Convert an input event to a user-friendly display string"""
	if event is InputEventKey:
		# Use physical_keycode if keycode is 0 (which happens with WASD keys)
		var key_to_use = event.keycode if event.keycode != 0 else event.physical_keycode
		return OS.get_keycode_string(key_to_use)
	elif event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				return "Left Click"
			MOUSE_BUTTON_RIGHT:
				return "Right Click"
			MOUSE_BUTTON_MIDDLE:
				return "Middle Click"
			_:
				return "Mouse " + str(event.button_index)
	elif event is InputEventJoypadButton:
		return "Gamepad " + str(event.button_index)
	elif event is InputEventJoypadMotion:
		var axis_name = ""
		match event.axis:
			JOY_AXIS_LEFT_X:
				axis_name = "Left Stick X"
			JOY_AXIS_LEFT_Y:
				axis_name = "Left Stick Y"
			JOY_AXIS_RIGHT_X:
				axis_name = "Right Stick X"
			JOY_AXIS_RIGHT_Y:
				axis_name = "Right Stick Y"
			JOY_AXIS_TRIGGER_LEFT:
				axis_name = "Left Trigger"
			JOY_AXIS_TRIGGER_RIGHT:
				axis_name = "Right Trigger"
			_:
				axis_name = "Axis " + str(event.axis)
		
		var direction = ""
		if event.axis_value > 0:
			direction = "+"
		elif event.axis_value < 0:
			direction = "-"
		
		return axis_name + direction
	
	return "Unknown"

func refresh():
	"""Refresh the display text (call this when keybindings might have changed)"""
	update_display_text()

func _on_button_pressed():
	if not input_listener:
		print("Warning: Input listener not found")
		return
	
	# Get current events for this action
	var events = InputMap.action_get_events(action_name)
	
	# If there are multiple events, let user choose which one to edit
	# For now, we'll edit the first one or start fresh
	var existing_event = events[0] if not events.is_empty() else null
	
	# Start listening for input
	input_listener.start_listening(action_name, existing_event)

func _on_input_received(event: InputEvent):
	"""Handle when new input is received"""
	if event == null:
		# This means the binding was cleared
		update_display_text()
		binding_changed.emit(action_name, null)
		return
	
	# Check for conflicts with other actions
	var conflicting_action = _find_conflicting_action(event)
	if conflicting_action != "" and conflicting_action != action_name:
		# Show conflict dialog or handle it
		_handle_input_conflict(event, conflicting_action)
		return
	
	# Add the new event to the action
	InputMap.action_add_event(action_name, event)
	
	# Update display and notify
	update_display_text()
	binding_changed.emit(action_name, event)

func _on_input_cancelled():
	"""Handle when input listening is cancelled"""
	# Nothing to do, just return to normal state
	pass

func _find_conflicting_action(event: InputEvent) -> String:
	"""Find if the given event conflicts with any existing action"""
	for action in InputMap.get_actions():
		if action == action_name:
			continue
		
		var events = InputMap.action_get_events(action)
		for existing_event in events:
			if _events_are_same(event, existing_event):
				return action
	
	return ""

func _events_are_same(event1: InputEvent, event2: InputEvent) -> bool:
	"""Check if two input events are the same"""
	if event1.get_class() != event2.get_class():
		return false
	
	if event1 is InputEventKey and event2 is InputEventKey:
		return event1.keycode == event2.keycode and event1.physical_keycode == event2.physical_keycode
	elif event1 is InputEventMouseButton and event2 is InputEventMouseButton:
		return event1.button_index == event2.button_index
	elif event1 is InputEventJoypadButton and event2 is InputEventJoypadButton:
		return event1.button_index == event2.button_index
	elif event1 is InputEventJoypadMotion and event2 is InputEventJoypadMotion:
		return event1.axis == event2.axis and sign(event1.axis_value) == sign(event2.axis_value)
	
	return false

func _handle_input_conflict(event: InputEvent, conflicting_action: String):
	"""Handle input conflict by removing from conflicting action and adding to current"""
	# Remove from conflicting action
	var conflicting_events = InputMap.action_get_events(conflicting_action)
	for conflicting_event in conflicting_events:
		if _events_are_same(event, conflicting_event):
			InputMap.action_erase_event(conflicting_action, conflicting_event)
			break
	
	# Add to current action
	InputMap.action_add_event(action_name, event)
	
	# Update display and notify
	update_display_text()
	binding_changed.emit(action_name, event)
	
	# Notify about the conflict resolution
	print("Resolved conflict: Moved binding from '", conflicting_action, "' to '", action_name, "'")
