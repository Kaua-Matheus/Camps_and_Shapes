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
var music := BackgroundMusic.get_node_or_null("AudioStreamPlayer2D")

func _ready() -> void:
	current_hp = max_hp
	health_bar.max_value = max_hp
	health_bar.value = current_hp
	_style_health_bar()
	
	music.play()
	go_to_idle_state()

func _physics_process(_delta: float) -> void:
	
	var direction_vector: Vector2 = Vector2(
		Input.get_action_strength("Right") - Input.get_action_strength("Left"),
		Input.get_action_strength("Down") - Input.get_action_strength("Up")
	).normalized()
	
	match status:
		PlayerState.idle:
			idle_state(_delta, direction_vector)
		PlayerState.walk:
			walk_state(_delta, direction_vector)
		PlayerState.attack:
			attack_state(_delta)
		#PlayerState.dead:
			#dead_state(delta)
			
	move_and_slide()


## Go To ##
func go_to_idle_state():
	status = PlayerState.idle
	animation.play("idle")
	
func go_to_walk_state():
	status = PlayerState.walk
	animation.play("walk")
	
func go_to_attack_state():
	status = PlayerState.attack
	animation.play("attack")
	velocity = Vector2.ZERO
	print("Atacou")
	
	
## State ##
func idle_state(_delta, direction_vector):
	move(_delta, direction_vector)
	
	if velocity != Vector2.ZERO:
		go_to_walk_state()
		return
	


func walk_state(_delta, direction_vector) -> void:
	
	move(_delta, direction_vector)
	
	if velocity == Vector2.ZERO:
		go_to_idle_state()
		return


func attack_state(_delta) -> void:
	if Input.get_action_strength("Attack"):
		go_to_attack_state()


func move(_delta: float, direction_vector):
	update_direction(direction_vector)
	
	velocity = direction_vector * speed


func update_direction(direction_vector):
	if direction_vector[0] > 0:
		animation.flip_h = false
	elif direction_vector[0] < 0:
		animation.flip_h = true







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
