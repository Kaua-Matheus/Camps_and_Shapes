extends Control

const SAVE_FILE := "user://save.dat"
const GAME_SCENE := "res://scenes/maps/level.tscn"
const OPTION_SCENE := "res://scenes/interface/options.tscn"

func _ready() -> void:
	$MenuButtons/BtnContinue.disabled = not FileAccess.file_exists(SAVE_FILE)

func _on_btn_new_game_pressed() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)

func _on_btn_continue_pressed() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)
	
func _on_btn_options_pressed() -> void:
	get_tree().change_scene_to_file(OPTION_SCENE)

func _on_btn_quit_pressed() -> void:
	get_tree().quit()
