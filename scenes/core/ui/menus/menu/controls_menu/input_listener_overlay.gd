class_name InputListenerOverlay extends Control

signal input_received(event: InputEvent)
signal cancelled

var is_listening: bool = false
var target_action: String = ""
var target_event: InputEvent = null # For editing existing bindings

@onready var overlay_panel: Panel = $OverlayPanel
@onready var instruction_label: Label = $OverlayPanel/VBoxContainer/InstructionLabel
@onready var current_binding_label: Label = $OverlayPanel/VBoxContainer/CurrentBindingLabel
@onready var cancel_button: Button = $OverlayPanel/VBoxContainer/ButtonContainer/CancelButton
@onready var clear_button: Button = $OverlayPanel/VBoxContainer/ButtonContainer/ClearButton

func _ready():
	# Make sure the overlay covers the entire screen
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Connect button signals
	if cancel_button:
		cancel_button.pressed.connect(_on_cancel_pressed)
	if clear_button:
		clear_button.pressed.connect(_on_clear_pressed)
	
	# Initially hide the overlay
	visible = false

func start_listening(action_name: String, existing_event: InputEvent = null):
	"""Start listening for input for the specified action"""
	target_action = action_name
	target_event = existing_event
	is_listening = true
	visible = true
	
	# Update UI text
	if instruction_label:
		instruction_label.text = "Press any key, mouse button, or gamepad input..."
	
	if current_binding_label:
		if existing_event:
			current_binding_label.text = "Current: " + get_event_display_text(existing_event)
		else:
			current_binding_label.text = "No current binding"
	
	# Enable input processing
	set_process_unhandled_input(true)

func stop_listening():
	"""Stop listening for input"""
	is_listening = false
	visible = false
	set_process_unhandled_input(false)
	target_action = ""
	target_event = null

func _unhandled_input(event):
	if not is_listening:
		return
	
	# Ignore UI input events
	if event is InputEventMouseMotion:
		return
	
	# Handle the input
	if _is_valid_input_event(event):
		# Consume the event
		get_viewport().set_input_as_handled()
		
		# Emit the signal with the captured event
		input_received.emit(event)
		stop_listening()

func _is_valid_input_event(event: InputEvent) -> bool:
	"""Check if the input event is valid for key binding"""
	if event is InputEventKey:
		# Ignore modifier keys alone (Shift, Ctrl, Alt)
		if event.keycode == 0 and event.physical_keycode in [4194325, 4194326, 4194327]: # Shift, Ctrl, Alt
			return false
		return true
	elif event is InputEventMouseButton:
		return true
	elif event is InputEventJoypadButton:
		return true
	elif event is InputEventJoypadMotion:
		# Only accept significant joystick movements
		return abs(event.axis_value) > 0.5
	
	return false

func _on_cancel_pressed():
	cancelled.emit()
	stop_listening()

func _on_clear_pressed():
	"""Clear the current binding"""
	if target_event and target_action != "":
		# Remove the specific event from the action
		InputMap.action_erase_event(target_action, target_event)
		input_received.emit(null) # Signal that binding was cleared
	stop_listening()

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
