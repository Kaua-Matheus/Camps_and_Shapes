extends CharacterBody2D

const GAME_OVER_SCENE := "res://scenes/game_over.tscn"

@export var speed: int = 300
@export var max_hp: int = 100

var current_hp: int

func _ready() -> void:
	current_hp = max_hp

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
	current_hp -= amount
	if current_hp <= 0:
		die()

func die() -> void:
	get_tree().change_scene_to_file(GAME_OVER_SCENE)
