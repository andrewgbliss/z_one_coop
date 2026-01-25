class_name InputListenerUtils

## Utility class for creating InputListenerOverlay instances anywhere in the project
## This provides a centralized way to create input listener overlays without
## needing to duplicate the creation code

static func create_input_listener(parent: Node) -> InputListenerOverlay:
	"""Create and return a new InputListenerOverlay instance"""
	var overlay = InputListenerOverlay.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Create the overlay panel
	var panel = Panel.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(400, 200)
	panel.offset_left = -200
	panel.offset_top = -100
	panel.offset_right = 200
	panel.offset_bottom = 100
	
	# Create style for the panel
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0, 0, 0, 0.8)
	style_box.corner_radius_top_left = 8
	style_box.corner_radius_top_right = 8
	style_box.corner_radius_bottom_right = 8
	style_box.corner_radius_bottom_left = 8
	panel.add_theme_stylebox_override("panel", style_box)
	
	overlay.add_child(panel)
	overlay.overlay_panel = panel
	
	# Create the main container
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 20
	vbox.offset_top = 20
	vbox.offset_right = -20
	vbox.offset_bottom = -20
	panel.add_child(vbox)
	
	# Create instruction label
	var instruction_label = Label.new()
	instruction_label.text = "Press any key, mouse button, or gamepad input..."
	instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	instruction_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(instruction_label)
	overlay.instruction_label = instruction_label
	
	# Create current binding label
	var current_binding_label = Label.new()
	current_binding_label.text = "No current binding"
	current_binding_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	current_binding_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	vbox.add_child(current_binding_label)
	overlay.current_binding_label = current_binding_label
	
	# Add separator
	var separator = HSeparator.new()
	vbox.add_child(separator)
	
	# Create button container
	var button_container = HBoxContainer.new()
	button_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(button_container)
	
	# Create cancel button
	var cancel_button = Button.new()
	cancel_button.text = "Cancel"
	cancel_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button_container.add_child(cancel_button)
	overlay.cancel_button = cancel_button
	
	# Create clear button
	var clear_button = Button.new()
	clear_button.text = "Clear"
	clear_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button_container.add_child(clear_button)
	overlay.clear_button = clear_button
	
	# Connect button signals
	cancel_button.pressed.connect(overlay._on_cancel_pressed)
	clear_button.pressed.connect(overlay._on_clear_pressed)
	
	# Add to parent and set up
	parent.add_child(overlay)
	overlay.z_index = 100
	overlay.visible = false
	
	return overlay

static func create_input_listener_with_callback(parent: Node, on_input_received: Callable, on_cancelled: Callable = Callable()) -> InputListenerOverlay:
	"""Create an InputListenerOverlay with custom callbacks"""
	var overlay = create_input_listener(parent)
	
	# Connect custom callbacks
	overlay.input_received.connect(on_input_received)
	if on_cancelled.is_valid():
		overlay.cancelled.connect(on_cancelled)
	
	return overlay

static func create_simple_input_listener(parent: Node, action_name: String, on_complete: Callable) -> InputListenerOverlay:
	"""Create a simple input listener that automatically handles the input"""
	var overlay = create_input_listener(parent)
	
	# Connect to handle the input automatically
	overlay.input_received.connect(func(event: InputEvent):
		on_complete.call(action_name, event)
		overlay.queue_free()
	)
	
	overlay.cancelled.connect(func():
		overlay.queue_free()
	)
	
	# Start listening immediately
	overlay.start_listening(action_name)
	
	return overlay
