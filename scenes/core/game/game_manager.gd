extends Node

enum GAME_STATE {
	NONE,
	GAME_INIT,
	GAME_SPLASH_SCREENS,
	GAME_MAIN_MENU,
	GAME_CHARACTER_CREATE,
	GAME_CHARACTER_SELECT,
	GAME_START,
	GAME_PLAY_READY,
	GAME_PLAY,
	GAME_SAVE,
	GAME_RESTORE,
	GAME_PAUSED,
	GAME_OVER,
	GAME_VICTORY,
	GAME_QUIT
}

var game_state: GAME_STATE = GAME_STATE.NONE
var previous_game_state: GAME_STATE = GAME_STATE.NONE
var is_paused: bool = false
var how_many_players: int = 1

signal state_changed(state: GAME_STATE)
signal paused_toggled(is_paused: bool)
signal on_pause
signal on_unpause

func set_state(new_game_state: GAME_STATE):
	if new_game_state != game_state:
		previous_game_state = game_state
		game_state = new_game_state
		state_changed.emit(game_state)

func get_state_name(state: GAME_STATE):
	match state:
		GAME_STATE.NONE:
			return "NONE"
		GAME_STATE.GAME_INIT:
			return "GAME_INIT"
		GAME_STATE.GAME_SPLASH_SCREENS:
			return "GAME_SPLASH_SCREENS"
		GAME_STATE.GAME_MAIN_MENU:
			return "GAME_MAIN_MENU"
		GAME_STATE.GAME_CHARACTER_CREATE:
			return "GAME_CHARACTER_CREATE"
		GAME_STATE.GAME_CHARACTER_SELECT:
			return "GAME_CHARACTER_SELECT"
		GAME_STATE.GAME_START:
			return "GAME_START"
		GAME_STATE.GAME_PLAY:
			return "GAME_PLAY"
		GAME_STATE.GAME_SAVE:
			return "GAME_SAVE"
		GAME_STATE.GAME_RESTORE:
			return "GAME_RESTORE"
		GAME_STATE.GAME_PAUSED:
			return "GAME_PAUSED"
		GAME_STATE.GAME_OVER:
			return "GAME_OVER"
		GAME_STATE.GAME_VICTORY:
			return "GAME_VICTORY"
		_:
			return "ERROR"

func pause():
	is_paused = true
	get_tree().paused = is_paused
	set_state(GAME_STATE.GAME_PAUSED)
	paused_toggled.emit(true)
	on_pause.emit()

func unpause():
	is_paused = false
	get_tree().paused = is_paused
	set_state(previous_game_state)
	paused_toggled.emit(false)
	on_unpause.emit()
	
func toggle_pause():
	if is_paused:
		unpause()
	else:
		pause()

func reset_scene():
	set_state(GAME_STATE.GAME_PLAY_READY)
	get_tree().reload_current_scene()
	
func quit():
	set_state(GAME_STATE.GAME_QUIT)
	get_tree().quit()
	
func reset():
	pass
