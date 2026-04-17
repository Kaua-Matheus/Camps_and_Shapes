extends CharacterBody2D

const GAME_OVER_SCENE := "res://scenes/interface/game_over.tscn"

@export var speed: int = 300
@export var max_hp: int = 100

var current_hp: int
var is_dead: bool = false

@onready var animation: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: ProgressBar = $HUD/HealthBar

# State Machine
enum PlayerState {
	idle,
	walk,
	attack,
	#dead
}

var status: PlayerState

func _ready() -> void:
	current_hp = max_hp
	health_bar.max_value = max_hp
	health_bar.value = current_hp
	_style_health_bar()

func _physics_process(_delta: float) -> void:
	move()

#func attack() -> void:
	#if Input.get_action_strength("Attack"):
		

func move() -> void:
	var direction_vector: Vector2 = Vector2(
		Input.get_action_strength("Right") - Input.get_action_strength("Left"),
		Input.get_action_strength("Down") - Input.get_action_strength("Up")
	).normalized()
	
	velocity = direction_vector * speed
	
	if velocity != Vector2.ZERO:
		go_to_walk_state()
	else:
		go_to_idle_state()
	
	move_and_slide()
	
func go_to_idle_state():
	status = PlayerState.idle
	animation.play("idle")d
	
func go_to_walk_state():
	status = PlayerState.walk
	animation.play("walk")

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
