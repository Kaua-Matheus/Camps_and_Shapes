extends Control

const MAIN_MENU_SCENE := "res://scenes/main_menu.tscn"
const GAME_SCENE := "res://entities/character/player.tscn"

func _on_btn_continue_pressed() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)

func _on_btn_quit_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
