extends CharacterBody2D

const GAME_OVER_SCENE := "res://scenes/interface/game_over.tscn"

@export var speed: int = 300
@export var max_hp: int = 100
@export var dash_speed: int = 700
@export var dash_time: float = 0.2

var current_hp: int
var is_dead: bool = false

# Hitbox Var
var hitbox_offset: Vector2

# Direction Vector
var direction_vector: Vector2

# Dash
var last_dash_direction := Vector2.ZERO
var last_dash_input_time := 0.0
var is_dashing := false
var dash_timer := 0.0
var dash_direction := Vector2.ZERO

# Cooldowns
const DASH_CD: float = 5.0
const HEAL_CD: float = 8.0
const DAMAGE_CD: float = 12.0

const HEAL_AMOUNT: int = 30
const DAMAGE_BOOST_DURATION: float = 4.0
const DAMAGE_BOOST_MULTIPLIER: float = 2.0

var _dash_cd: float = 0.0
var _heal_cd: float = 0.0
var _damage_cd: float = 0.0
var _damage_boost_remaining: float = 0.0
var _damage_boosted: bool = false
var _skill_overlays: Array = []
var _skill_labels: Array = []

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
	# Player Inflicts
	idle,
	walk,
	attack,
	dash,
	
	# Player Inflicted
	attacked,
	dead,
}

var status: PlayerState

func _ready() -> void:
	current_hp = max_hp
	health_bar.max_value = max_hp
	health_bar.value = current_hp
	_style_health_bar()
	hitbox_offset = attack_hit_box.position
	go_to_idle_state()

	if SaveManager.is_continuing:
		_apply_save_data()
	_setup_skill_hud()

func _apply_save_data() -> void:
	var data := SaveManager.load_save()
	if data.is_empty():
		return
	var p: Dictionary = data.get("player", {})
	if p.has("pos_x") and p.has("pos_y"):
		global_position = Vector2(float(p["pos_x"]), float(p["pos_y"]))
	if p.has("current_hp"):
		current_hp = int(p["current_hp"])
		health_bar.value = current_hp

# Main Process
func _physics_process(delta: float) -> void:
		
	direction_vector = Vector2(
		Input.get_action_strength("Right") - Input.get_action_strength("Left"),
		Input.get_action_strength("Down") - Input.get_action_strength("Up")
	).normalized()
	

	handle_dash_input()
	handle_dash(delta)
	_handle_skills(delta)

	match status:
		# Movement
		PlayerState.idle:
			idle_state(delta)
		PlayerState.walk:
			walk_state(delta)
		PlayerState.dash:
			dash_state(delta)
			
		# Attack
		PlayerState.attack:
			attack_state(delta)
		
		# Attacked
		PlayerState.attacked:
			attacked_state(delta)
		
		# Death
		PlayerState.dead:
			dead_state(delta)

	move_and_slide()

func handle_dash_input():
	if Input.is_action_just_pressed("Dash"):
		if direction_vector != Vector2.ZERO:
			start_dash(direction_vector)
			
func start_dash(dir: Vector2):
	if is_dashing or _dash_cd > 0.0:
		return
	is_dashing = true
	dash_timer = dash_time
	dash_direction = dir

func handle_dash(delta):
	if is_dashing:
		velocity = dash_direction * dash_speed
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
			_dash_cd = DASH_CD
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

func go_to_dash_state():
	pass

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
		
	if Input.get_action_strength("Dash"):
		go_to_dash_state()
		return
		
	if Input.get_action_strength("Attack"):
		go_to_attack_state()
		return


func walk_state(_delta) -> void:
	move(_delta)
	
	if velocity == Vector2.ZERO:
		go_to_idle_state()
		return
		
	if Input.get_action_strength("Dash"):
		go_to_dash_state()
		return
		
	if Input.get_action_strength("Attack"):
		go_to_attack_state()

func dash_state(_delta):
	pass

func attack_state(_delta) -> void:
	update_hitbox_offset()
	
	swing_attack.play() # Fix: Too long
	
	# return to idle when animation finished
	if animation.frame == 3:
		go_to_idle_state()
		return

func attacked_state(_delta):
	pass

func dead_state(_delta):
	pass


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


# Player Attack Hitbox
func update_hitbox_offset() -> void:
	# Change the hitbox depending on player direction
	
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


# ─── Player Take Damage ─────────────────────────────────────────────────

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
	get_tree().change_scene_to_file.call_deferred(GAME_OVER_SCENE)


# ─── Health HUD ─────────────────────────────────────────────────

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
		var dmg := damage_percent * (DAMAGE_BOOST_MULTIPLIER if _damage_boosted else 1.0)
		body.take_damage_percent(dmg)

# ─── Skills ────────────────────────────────────────────────────

func _handle_skills(delta: float) -> void:
	_dash_cd = max(_dash_cd - delta, 0.0)
	_heal_cd = max(_heal_cd - delta, 0.0)
	_damage_cd = max(_damage_cd - delta, 0.0)
	_damage_boost_remaining = max(_damage_boost_remaining - delta, 0.0)

	if _damage_boosted and _damage_boost_remaining <= 0.0:
		_damage_boosted = false
		animation.modulate = Color.WHITE

	if Input.is_action_just_pressed("Skill_Heal") and _heal_cd <= 0.0:
		_use_heal()

	if Input.is_action_just_pressed("Skill_Damage") and _damage_cd <= 0.0:
		_use_damage_boost()

	_update_skill_hud()

func _use_heal() -> void:
	current_hp = min(current_hp + HEAL_AMOUNT, max_hp)
	health_bar.value = current_hp
	_heal_cd = HEAL_CD

func _use_damage_boost() -> void:
	_damage_boosted = true
	_damage_boost_remaining = DAMAGE_BOOST_DURATION
	_damage_cd = DAMAGE_CD
	animation.modulate = Color(1.4, 0.7, 0.2)

# ─── Skill HUD ─────────────────────────────────────────────────

func _setup_skill_hud() -> void:
	var hud: CanvasLayer = $HUD
	var colors := [Color(0.2, 0.5, 1.0, 0.9), Color(0.2, 0.78, 0.3, 0.9), Color(0.9, 0.3, 0.2, 0.9)]
	var ready_texts := ["DASH", "HEAL", "DMG+"]
	var key_hints := ["RMB", "[ 1 ]", "[ 2 ]"]
	var icon_size := 40
	var gap := 4
	var start_x := 8
	var start_y := 28

	for i in range(3):
		var x := start_x + i * (icon_size + gap)

		var bg := ColorRect.new()
		bg.position = Vector2(x, start_y)
		bg.size = Vector2(icon_size, icon_size)
		bg.color = colors[i]
		hud.add_child(bg)

		var overlay := ColorRect.new()
		overlay.position = Vector2(x, start_y)
		overlay.size = Vector2(icon_size, 0.0)
		overlay.color = Color(0.0, 0.0, 0.0, 0.78)
		hud.add_child(overlay)
		_skill_overlays.append(overlay)

		var hint := Label.new()
		hint.position = Vector2(x, start_y + icon_size - 12)
		hint.size = Vector2(icon_size, 12)
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
		hint.add_theme_font_size_override("font_size", 7)
		hint.text = key_hints[i]
		hud.add_child(hint)

		var lbl := Label.new()
		lbl.position = Vector2(x, start_y)
		lbl.size = Vector2(icon_size, icon_size - 12)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_color_override("font_color", Color.WHITE)
		lbl.add_theme_font_size_override("font_size", 9)
		lbl.text = ready_texts[i]
		hud.add_child(lbl)
		_skill_labels.append(lbl)

func _update_skill_hud() -> void:
	if _skill_overlays.is_empty():
		return
	var timers := [_dash_cd, _heal_cd, _damage_cd]
	var max_cds := [DASH_CD, HEAL_CD, DAMAGE_CD]
	var ready_texts := ["DASH", "HEAL", "DMG+"]
	var icon_size := 40.0

	for i in range(3):
		var t: float = timers[i]
		var overlay: ColorRect = _skill_overlays[i]
		var lbl: Label = _skill_labels[i]
		if t > 0.0:
			overlay.size.y = (t / max_cds[i]) * icon_size
			lbl.text = str(ceili(t))
		else:
			overlay.size.y = 0.0
			lbl.text = ready_texts[i]
