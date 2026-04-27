extends Control

const SAVE_FILE := "user://save.dat"
const GAME_SCENE := "res://scenes/maps/level.tscn"

func _ready() -> void:
	self.visible = false
	pass
	
func resume():
	process_mode = Node.PROCESS_MODE_PAUSABLE
	self.visible = false
	get_tree().paused = false

func pause():
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	self.visible = true
	get_tree().paused = true


func testEsc():
	if Input.is_action_just_pressed("Menu") and get_tree().paused == false:
		pause()
	elif Input.is_action_just_pressed("Menu") and get_tree().paused == true:
		resume()
	
func _on_btn_continue_pressed() -> void:
	resume()

func _on_btn_quit_pressed() -> void:
	get_tree().quit()

func _process(_delta: float) -> void:
	testEsc()
