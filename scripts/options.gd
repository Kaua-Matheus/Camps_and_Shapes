extends Control

const MAIN_MENU_SCENE := "res://scenes/interface/main_menu.tscn"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
func _on_btn_voltar_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
