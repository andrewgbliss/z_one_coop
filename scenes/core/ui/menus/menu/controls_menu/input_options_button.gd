class_name InputOptionsButton extends OptionButton

@export_enum("Movement", "Aim", "Facing", "Attack") var type: String

func _init() -> void:
	#GameManager.user_config.loaded.connect(_on_user_config_loaded)
	pass

func _ready() -> void:
	add_item("Default", 0)
	add_item("Mouse", 1)
	add_item("Keyboard", 2)
	add_item("Joystick", 3)
	add_item("Touch", 4)
	add_item("AI", 5)
	
func _on_user_config_loaded(data) -> void:
	_set_default_index(data)
	item_selected.connect(_on_option_button_item_selected)

func _set_default_index(_data) -> void:
	pass
	#var selected_index = 0
	#match type:
		#"Aim":
			#match GameManager.user_config.aim_type:
				#UserConfig.AimType.DEFAULT:
					#selected_index = 0
				#UserConfig.AimType.MOUSE:
					#selected_index = 1
				#UserConfig.AimType.KEYBOARD:
					#selected_index = 2
				#UserConfig.AimType.JOYSTICK:
					#selected_index = 3
				#UserConfig.AimType.TOUCH:
					#selected_index = 4
				#UserConfig.AimType.AI:
					#selected_index = 5
		#"Movement":
			#match GameManager.user_config.movement_type:
				#UserConfig.MovementType.DEFAULT:
					#selected_index = 0
				#UserConfig.MovementType.MOUSE:
					#selected_index = 1
				#UserConfig.MovementType.KEYBOARD:
					#selected_index = 2
				#UserConfig.MovementType.JOYSTICK:
					#selected_index = 3
				#UserConfig.MovementType.TOUCH:
					#selected_index = 4
				#UserConfig.MovementType.AI:
					#selected_index = 5
		#"Facing":
			#match GameManager.user_config.facing_type:
				#UserConfig.FacingType.DEFAULT:
					#selected_index = 0
				#UserConfig.FacingType.MOUSE:
					#selected_index = 1
				#UserConfig.FacingType.KEYBOARD:
					#selected_index = 2
				#UserConfig.FacingType.JOYSTICK:
					#selected_index = 3
				#UserConfig.FacingType.TOUCH:
					#selected_index = 4
				#UserConfig.FacingType.AI:
					#selected_index = 5
		#"Attack":
			#match GameManager.user_config.attack_type:
				#UserConfig.AttackType.DEFAULT:
					#selected_index = 0
				#UserConfig.AttackType.MOUSE:
					#selected_index = 1
				#UserConfig.AttackType.KEYBOARD:
					#selected_index = 2
				#UserConfig.AttackType.JOYSTICK:
					#selected_index = 3
				#UserConfig.AttackType.TOUCH:
					#selected_index = 4
				#UserConfig.AttackType.AI:
					#selected_index = 5
	#select(selected_index)

func _on_option_button_item_selected(_index: int) -> void:
	pass
	#match type:
		#"Aim":
			#GameManager.user_config.aim_type = UserConfig.AimType.values()[index]
		#"Movement":
			#GameManager.user_config.movement_type = UserConfig.MovementType.values()[index]
		#"Facing":
			#GameManager.user_config.facing_type = UserConfig.FacingType.values()[index]
		#"Attack":
			#GameManager.user_config.attack_type = UserConfig.AttackType.values()[index]
	#GameManager.user_config.save_to_file()
