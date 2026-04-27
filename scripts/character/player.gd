extends CharacterBody2D

const GAME_OVER_SCENE := "res://scenes/interface/game_over.tscn"

@export var speed: int = 300
@export var max_hp: int = 100
@export var dash_speed: int = 700
@export var dash_time: float = 0.2
@export var dash_cooldown: float = 0.5

var current_hp: int
var is_dead: bool = false
var hitbox_offset: Vector2
var direction_vector: Vector2

var last_dash_direction := Vector2.ZERO
var last_dash_input_time := 0.0
var is_dashing := false
var dash_timer := 0.0
var dash_direction := Vector2.ZERO
var dash_cooldown_timer := 0.0

# Animation
@onready var animation: AnimatedSprite2D = $AnimatedSprite2D

# Health Bar
@onready var health_bar: ProgressBar = $HUD/HealthBar

# Attack
@onready var attack_hit_box: Area2D = $AttackHitBox
@onready var swing_attack: AudioStreamPlayer2D = $SwingAttack
@export var damage_percent: float = 20.0


# State Machine
enum PlayerState {
	idle,
	walk,
	attack,
	#dead
}

var status: PlayerState
#var music := BackgroundMusic.get_node_or_null("AudioStreamPlayer2D")

func _ready() -> void:
	
	# Hp
	current_hp = max_hp
	health_bar.max_value = max_hp
	health_bar.value = current_hp
	_style_health_bar()
	
	# Initialise hitbox offset
	hitbox_offset = attack_hit_box.position
	
	#music.play()
	go_to_idle_state()

func _physics_process(delta: float) -> void:
		
	direction_vector = Vector2(
		Input.get_action_strength("Right") - Input.get_action_strength("Left"),
		Input.get_action_strength("Down") - Input.get_action_strength("Up")
	).normalized()
	

	handle_dash_input()
	handle_dash(delta)

	match status:
		PlayerState.idle:
			idle_state(delta)
		PlayerState.walk:
			walk_state(delta)
		PlayerState.attack:
			attack_state(delta)
		#PlayerState.dead:
			#dead_state(delta)

	move_and_slide()

func handle_dash_input():
	if Input.is_action_just_pressed("Dash"):
		if direction_vector != Vector2.ZERO:
			start_dash(direction_vector)
			
func start_dash(dir: Vector2):
	if is_dashing or dash_cooldown_timer > 0:
		return
	is_dashing = true
	dash_timer = dash_time
	dash_direction = dir

func handle_dash(delta):
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta

	if is_dashing:
		velocity = dash_direction * dash_speed
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
			dash_cooldown_timer = dash_cooldown
			velocity = Vector2.ZERO

## Go To ##
func go_to_idle_state():
	attack_hit_box.monitoring = false
	status = PlayerState.idle
	animation.play("idle")

func go_to_walk_state():
	attack_hit_box.monitoring = false
	status = PlayerState.walk
	animation.play("walk")

func go_to_attack_state():
	attack_hit_box.monitoring = true
	status = PlayerState.attack
	animation.play("attack")
	velocity = Vector2.ZERO

	
## State ##
func idle_state(_delta):
	move(_delta)
	
	if velocity != Vector2.ZERO:
		go_to_walk_state()
		return
		
	if Input.get_action_strength("Attack"):
		go_to_attack_state()


func walk_state(_delta) -> void:
	move(_delta)
	
	if velocity == Vector2.ZERO:
		go_to_idle_state()
		return
		
	if Input.get_action_strength("Attack"):
		go_to_attack_state()


func attack_state(_delta) -> void:
	update_hitbox_offset()
	
	swing_attack.play() # Fix: Too long
	
	if animation.frame == 3:
		go_to_idle_state()


func move(_delta: float):
	if is_dashing:
		return
	update_direction()
	
	velocity = direction_vector * speed


func update_direction():
	update_hitbox_offset()
	
	match  direction_vector:
		Vector2.LEFT:
			animation.flip_h = true
		Vector2.RIGHT:
			animation.flip_h = false


func update_hitbox_offset() -> void:
	var x := hitbox_offset.x
	var y := hitbox_offset.y

	match direction_vector:
		Vector2.LEFT:
			attack_hit_box.position = Vector2(-x, y)
		Vector2.RIGHT:
			attack_hit_box.position = Vector2(x, y)
		Vector2.UP:
			attack_hit_box.position = Vector2(y, -x)
		Vector2.DOWN:
			attack_hit_box.position = Vector2(-y, x)



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
	#if music:
		#music.stop()
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

# Attack the enemy
func attack_body_entered(body: Node2D) -> void:
	print(body.get_groups())
	if body.is_in_group("Enemy"):
		body.take_damage_percent(damage_percent)
