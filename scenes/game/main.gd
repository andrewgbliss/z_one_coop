extends Node2D

func _ready() -> void:
	GameManager.state_changed.connect(_on_game_state_changed)
	GameManager.set_state(GameManager.GAME_STATE.GAME_INIT)
	SceneManager.finished.connect(_on_scene_finished)

func _on_scene_finished(transition_name: String):
	match transition_name:
		"SponserSplashScreen":
			GameManager.set_state(GameManager.GAME_STATE.GAME_MAIN_MENU)

func _on_game_state_changed(state: GameManager.GAME_STATE):
	match state:
		GameManager.GAME_STATE.GAME_INIT:
			GameManager.set_state(GameManager.GAME_STATE.GAME_MAIN_MENU)
		GameManager.GAME_STATE.GAME_SPLASH_SCREENS:
			SceneManager.transition_play("BrandSplashScreen")
		GameManager.GAME_STATE.GAME_MAIN_MENU:
			UiManager.game_menus.push("MainMenu")
		GameManager.GAME_STATE.GAME_PLAY:
			SceneManager.goto_scene("res://scenes/game/levels/overworld.tscn")
