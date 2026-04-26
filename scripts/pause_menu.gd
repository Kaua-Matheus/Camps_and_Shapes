extends Control

const SAVE_FILE := "user://save.dat"
const GAME_SCENE := "res://scenes/maps/level.tscn"

func _ready() -> void:
	$MenuButtons/BtnContinue.disabled = not FileAccess.file_exists(SAVE_FILE)

func _on_btn_continue_pressed() -> void:
	#get_tree().change_scene_to_file(GAME_SCENE)
	# Add get_tree.paused = false
	pass

func _on_btn_quit_pressed() -> void:
	get_tree().quit()
