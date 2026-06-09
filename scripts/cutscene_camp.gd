extends CanvasLayer

@onready var background = $Background
@onready var fade = $Fade
@onready var dialogue_text = $DialogueBox/DialogueText
@onready var audio_player = $AudioStreamPlayer

var dialogues = [
	"VOCÊ!",
	"Este pequeno e aventureiro slime se encontra em um também pequeno acampamento",
	"Em direção ao castelo do rei para ter uma audiência com ele",
	"Mal sabia este slime os perigos que ele e sua fiel espada enfrentariam..."
]

var current_dialogue = 0
var text_speed = 0.04

var is_typing = false
var full_text = ""

func _ready():
	dialogue_text.text = ""

	fade.modulate.a = 1.0

	var tween = create_tween()
	tween.tween_property(fade, "modulate:a", 0.0, 2.0)

	await tween.finished

	show_dialogue(dialogues[current_dialogue])


func show_dialogue(text):
	is_typing = true
	full_text = text

	dialogue_text.text = text
	dialogue_text.visible_characters = 0

	for i in text.length():
		dialogue_text.visible_characters += 1

		if text[i] != " ":
			audio_player.pitch_scale = randf_range(0.95, 1.05)
			audio_player.play()

		await get_tree().create_timer(text_speed).timeout

		if not is_typing:
			break

	dialogue_text.visible_characters = text.length()
	is_typing = false


func _input(event):
	if event.is_action_pressed("ui_accept"):

		if is_typing:
			is_typing = false
			return

		current_dialogue += 1

		if current_dialogue >= dialogues.size():
			end_cutscene()
			return

		show_dialogue(dialogues[current_dialogue])


func end_cutscene():
	var tween = create_tween()

	tween.tween_property(fade, "modulate:a", 1.0, 1.5)

	await tween.finished

	get_tree().change_scene_to_file("res://scenes/maps/level.tscn")
