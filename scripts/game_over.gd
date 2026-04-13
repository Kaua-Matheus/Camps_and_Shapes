extends Control

const MAIN_MENU_SCENE := "res://scenes/interface/main_menu.tscn"
const GAME_SCENE := "res://scenes/maps/world.tscn"

func _on_btn_continue_pressed() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)

func _on_btn_quit_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
