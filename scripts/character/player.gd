extends CharacterBody2D

const GAME_OVER_SCENE := "res://scenes/interface/game_over.tscn"

@export var speed: int = 300
@export var max_hp: int = 100

var current_hp: int
var is_dead: bool = false

@onready var health_bar: ProgressBar = $HUD/HealthBar

func _ready() -> void:
	current_hp = max_hp
	health_bar.max_value = max_hp
	health_bar.value = current_hp
	_style_health_bar()

func _physics_process(_delta: float) -> void:
	move()

func move() -> void:
	var direction_vector: Vector2 = Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	).normalized()

	velocity = direction_vector * speed
	move_and_slide()

func take_damage(amount: int) -> void:
	if is_dead:
		return
	current_hp = max(current_hp - amount, 0)
	health_bar.value = current_hp
	if current_hp <= 0:
		die()

func take_damage_percent(percent: float) -> void:
	take_damage(int(max_hp * percent / 100.0))

func die() -> void:
	is_dead = true
	var music := BackgroundMusic.get_node_or_null("AudioStreamPlayer2D")
	if music:
		music.stop()
	get_tree().change_scene_to_file.call_deferred(GAME_OVER_SCENE)

func _style_health_bar() -> void:
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.8, 0.1, 0.1)
	fill.set_corner_radius_all(3)
	health_bar.add_theme_stylebox_override("fill", fill)

	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.15, 0.15, 0.15, 0.85)
	bg.set_corner_radius_all(3)
	health_bar.add_theme_stylebox_override("background", bg)
