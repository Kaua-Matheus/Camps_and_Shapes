class_name Player
extends Character

const GAME_OVER_SCENE := "res://scenes/interface/game_over.tscn"

# Consts
const BASE_SPEED = 300.0

# Dash Override
var dash_cd_override: float = -1.0      # -1 = usa DASH_CD padrão
var dash_distance_multiplier: float = 1.0

var absorb_data : AbsorbResource

@onready var absorb_component: AbsorbComponent = $AbsorbComponent

@export var base_speed: float = BASE_SPEED
@export var speed: float = BASE_SPEED

@export var dash_speed: int = 700
@export var dash_time: float = 0.2

var active_abilities: Array[String] = []
var default_frames: SpriteFrames  # salvo no _ready

# Hitbox Var
var hitbox_offset: Vector2

# Direction Vector
var move_direction: Vector2
var mouse_pos: Vector2

# Dash
var last_dash_direction := Vector2.ZERO
var last_dash_input_time := 0.0

var dash_timer := 0.0
var dash_direction := Vector2.ZERO

# Cooldowns
const DASH_CD: float = 5.0
const HEAL_CD: float = 8.0
const DAMAGE_CD: float = 12.0

const HEAL_AMOUNT: int = 30
const DAMAGE_BOOST_DURATION: float = 4.0
const DAMAGE_BOOST_MULTIPLIER: float = 2.0

var heal_unlocked: bool = false

var _dash_cd: float = 0.0
var _heal_cd: float = 0.0
var _damage_cd: float = 0.0
var _damage_boost_remaining: float = 0.0
var _damage_boosted: bool = false
var _skill_overlays: Array = []
var _skill_labels: Array = []
var _heal_lock_overlay: ColorRect = null
var _heal_lock_label: Label = null

# Animation
@onready var animation: AnimatedSprite2D = $AnimatedSprite2D

# Health Bar
@onready var health_bar: ProgressBar = $HUD/HealthBar

# Attack
@onready var attack_hit_box: Area2D = $AttackHitBox
@onready var swing_attack: AudioStreamPlayer2D = $SwingAttack


# ─── State Machine ─────────────────────────────────────────────────
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

var current_state: PlayerState



# onde você calcula o cooldown do dash:
func _get_dash_cooldown() -> float:
	return dash_cd_override if dash_cd_override >= 0.0 else DASH_CD


func _ready() -> void:
	
	# Absorb
	default_frames = $AnimatedSprite2D.sprite_frames
	absorb_component.form_applied.connect(_on_form_applied)
	absorb_component.form_expired.connect(_on_form_expired)
	FormUnlockManager.form_unlocked.connect(_on_form_unlocked)
	
	
	health = max_hp
	health_bar.max_value = max_hp
	health_bar.value = health
	_style_health_bar()
	hitbox_offset = attack_hit_box.position
	enter_idle_state()

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
	if p.has("health"):
		health = int(p["health"])
		health_bar.value = health

# Main Process
func _physics_process(delta: float) -> void:

	read_input()

	update_cooldowns(delta)
	
	_update_skill_hud()

	update_state(delta)

	move_and_slide()


## Go To ##
func enter_idle_state():
	attack_hit_box.monitoring = false
	current_state = PlayerState.idle
	animation.play("idle")

func enter_walk_state():
	attack_hit_box.monitoring = false
	current_state = PlayerState.walk
	animation.play("walk")

func enter_dash_state():
	current_state = PlayerState.dash

	dash_direction = move_direction
	dash_timer = dash_time
	
	# Added for dash override
	dash_direction = dash_direction * dash_distance_multiplier

	animation.play("dash")

func enter_attack_state():
	attack_hit_box.monitoring = true
	current_state = PlayerState.attack	
	animation.play("attack")
	swing_attack.play()
	velocity = Vector2.ZERO
	
func enter_death_state():
	attack_hit_box.monitoring = false
	current_state = PlayerState.dead
	animation.play("death")
	velocity = Vector2.ZERO

	
## State ##
func idle_state(delta):
	move(delta)
	
	if velocity != Vector2.ZERO:
		enter_walk_state()
		return
		
	if Input.get_action_strength("Dash") and _dash_cd <= 0.0:
		enter_dash_state()
		return
		
	if Input.get_action_strength("Attack"):
		enter_attack_state()
		return


func walk_state(delta) -> void:
	move(delta)
	
	if velocity == Vector2.ZERO:
		enter_idle_state()
		return
		
	if Input.get_action_strength("Dash") and _dash_cd <= 0.0:
		enter_dash_state()
		return
		
	if Input.get_action_strength("Attack"):
		enter_attack_state()

func dash_state(delta):
	velocity = dash_direction * dash_speed
	dash_timer -= delta
	
	if dash_timer <= 0:
		_dash_cd = _get_dash_cooldown()
		if move_direction == Vector2.ZERO:
			enter_idle_state()
		else:
			enter_walk_state()

func attack_state(_delta) -> void:
	update_hitbox_offset()
	
	# return to idle when animation finished
	if animation.frame == 3:
		enter_idle_state()
		return

func attacked_state(_delta):
	pass

func dead_state(_delta):
	is_dead = true
	
	if animation.frame == 7:
		get_tree().change_scene_to_file.call_deferred(GAME_OVER_SCENE)
		return


func read_input():
	move_direction = Input.get_vector(
		"Left",
		"Right",
		"Up",
		"Down"
	)

func update_state(delta: float):

	match current_state:

		PlayerState.idle:
			idle_state(delta)

		PlayerState.walk:
			walk_state(delta)

		PlayerState.attack:
			attack_state(delta)

		PlayerState.dash:
			dash_state(delta)

		PlayerState.dead:
			dead_state(delta)


func move(_delta: float):
	#if is_dashing:
		#return
		
	update_direction()
	
	velocity = move_direction * speed


func update_direction():
	update_hitbox_offset()
	
	mouse_pos = get_global_mouse_position()
	animation.flip_h = mouse_pos.x < global_position.x
	
	# Old Move (Based in Direction)
	#if move_direction.x < 0:
		#animation.flip_h = true
	#elif move_direction.x > 0:
		#animation.flip_h = false


# Cooldowns
func update_cooldowns(delta: float):

	_dash_cd = max(_dash_cd - delta, 0.0)
	_heal_cd = max(_heal_cd - delta, 0.0)
	_damage_cd = max(_damage_cd - delta, 0.0)

# Player Attack Hitbox
func update_hitbox_offset() -> void:
	
	mouse_pos = get_global_mouse_position()
	var direction := (mouse_pos - global_position).normalized()
	
	attack_hit_box.position = direction * hitbox_offset.x
	
	# Old Attack Hitbox (Based in Direction)
	#var x := hitbox_offset.x
	#var y := hitbox_offset.y

	#match move_direction:
		#Vector2.LEFT:
			#attack_hit_box.position = Vector2(-x, y)
		#Vector2.RIGHT:
			#attack_hit_box.position = Vector2(x, y)
		#Vector2.UP:
			#attack_hit_box.position = Vector2(y, -x)
		#Vector2.DOWN:
			#attack_hit_box.position = Vector2(-y, x)


# ─── Player Take Damage ─────────────────────────────────────────────────

func take_damage(amount: int) -> void:
	if is_dead:
		return
	health = max(health - amount, 0)
	health_bar.value = health
	if health <= 0:
		enter_death_state()

#func take_attack_damage_percent(percent: float) -> void:
	#take_damage(int(max_hp * percent / 100.0))



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
		var dmg := attack_damage_percent * (DAMAGE_BOOST_MULTIPLIER if _damage_boosted else 1.0)
		body.take_damage(dmg)

# ─── Skills ────────────────────────────────────────────────────

# Need fix, player can't use heal
func _handle_skills(delta: float) -> void:
	_dash_cd = max(_dash_cd - delta, 0.0)
	_heal_cd = max(_heal_cd - delta, 0.0)
	_damage_cd = max(_damage_cd - delta, 0.0)
	_damage_boost_remaining = max(_damage_boost_remaining - delta, 0.0)

	if _damage_boosted and _damage_boost_remaining <= 0.0:
		_damage_boosted = false
		animation.modulate = Color.WHITE

	if Input.is_action_just_pressed("Skill_Heal") and _heal_cd <= 0.0 and heal_unlocked:
		_use_heal()

	if Input.is_action_just_pressed("Skill_Damage") and _damage_cd <= 0.0:
		_use_damage_boost()

	_update_skill_hud()

func _use_heal() -> void:
	health = min(health + HEAL_AMOUNT, max_hp)
	health_bar.value = health
	_heal_cd = HEAL_CD

func _use_damage_boost() -> void:
	_damage_boosted = true
	_damage_boost_remaining = DAMAGE_BOOST_DURATION
	_damage_cd = DAMAGE_CD
	animation.modulate = Color(1.4, 0.7, 0.2)


# ─── Absorb Context ─────────────────────────────────────────────────

func has_ability(ability: String) -> bool:
	return active_abilities.has(ability)

# Absorb Input
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Activate"):  # Espaço
		if absorb_data == null:
			print("Can't absorb for now.")
		else:
			absorb_component.absorb(absorb_data)
	

func _on_form_applied(data: AbsorbResource) -> void:
	print("Forma absorvida: ", data.form_name)
	# atualiza HUD, toca animação, etc.

func _on_form_expired() -> void:
	print("Forma expirou!")
	enter_idle_state()
	
# For some reason, when absorb an enemy, the character can't move	
func _on_form_unlocked(data: AbsorbResource) -> void:
	print("A nova forma esta desbloqueada")
	absorb_data = data
	#absorb_component.absorb(data)


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

		if i == 1:
			var lock_bg := ColorRect.new()
			lock_bg.position = Vector2(x, start_y)
			lock_bg.size = Vector2(icon_size, icon_size)
			lock_bg.color = Color(0.0, 0.0, 0.0, 0.78)
			hud.add_child(lock_bg)
			_heal_lock_overlay = lock_bg

			var lock_lbl := Label.new()
			lock_lbl.position = Vector2(x, start_y)
			lock_lbl.size = Vector2(icon_size, icon_size)
			lock_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lock_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			lock_lbl.add_theme_color_override("font_color", Color.WHITE)
			lock_lbl.add_theme_font_size_override("font_size", 9)
			lock_lbl.text = "LOCK"
			hud.add_child(lock_lbl)
			_heal_lock_label = lock_lbl

func unlock_heal() -> void:
	heal_unlocked = true
	if is_instance_valid(_heal_lock_overlay):
		_heal_lock_overlay.visible = false
	if is_instance_valid(_heal_lock_label):
		_heal_lock_label.visible = false

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
