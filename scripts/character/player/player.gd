class_name Player
extends CharacterBody2D

# Externals
const GAME_OVER_SCENE := "res://scenes/interface/game_over.tscn"

# Consts
const BASE_SPEED = 300.0

# Dash Override (preenchido pelo AbsorbComponent)
var dash_cd_override: float = -1.0
var dash_distance_multiplier: float = 1.0

# Absorb
var absorb_data: AbsorbResource
@onready var absorb_component: AbsorbComponent = $AbsorbComponent

# Nodes
@onready var animation: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_hit_box: Area2D = $AttackHitBox
@onready var attack_animation: AnimatedSprite2D = $AttackHitBox/AttackAnimation
@onready var swing_attack: AudioStreamPlayer2D = $SwingAttack

# Stats
@export var base_speed: float = BASE_SPEED
@export var speed: float = BASE_SPEED
@export var dash_speed: int = 700
@export var dash_time: float = 0.2
@export var max_hp: float = 100
@export var health: float
@export var attack_damage_percent := 20.0

var active_abilities: Array[String] = []
var default_frames: SpriteFrames

# Hitbox
var hitbox_offset: Vector2

# Direção
var move_direction: Vector2
var mouse_pos: Vector2

# Dash
var dash_timer := 0.0
var dash_direction := Vector2.ZERO

# ── Cooldowns (lidos pelo HUD, decrementados pelo HUD) ──────────────
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

# ── Invencibilidade ─────────────────────────────────────────────────
var _is_invincible: bool = false

const IFRAME_DURATION: float = 0.8
const BLINK_INTERVAL: float = 0.08
var _iframe_timer: float = 0.0
var _blink_timer: float = 0.0

# ── Freeze System ───────────────────────────────────────────────────
const SNOW_BIOME_X := 2304.0
const FREEZE_DELAY := 10.0
const CAMPFIRE_WARMUP := 3.0
const FREEZE_DAMAGE := 2
const FREEZE_TICK := 1.0

var _campfire_count: int = 0
var _freeze_timer: float = FREEZE_DELAY
var _campfire_warmup: float = 0.0
var _is_freezing: bool = false
var _freeze_tick_timer: float = FREEZE_TICK

# Injetados pelo PlayerHUD
var _freeze_label: Label = null
var _freeze_shader: ShaderMaterial = null
var _freeze_vignette_intensity: float = 0.0

# ── State Machine ────────────────────────────────────────────────────
enum PlayerState { idle, walk, attack, dash, attacked, dead }
var current_state: PlayerState


func _get_dash_cooldown() -> float:
	return dash_cd_override if dash_cd_override >= 0.0 else DASH_CD


func _ready() -> void:
	default_frames = animation.sprite_frames
	absorb_component.form_applied.connect(_on_form_applied)
	absorb_component.form_expired.connect(_on_form_expired)
	FormUnlockManager.form_unlocked.connect(_on_form_unlocked)

	health = max_hp
	hitbox_offset = attack_hit_box.position
	enter_idle_state()

	if SaveManager.is_continuing:
		_apply_save_data()


func _apply_save_data() -> void:
	var data := SaveManager.load_save()
	if data.is_empty():
		return
	var p: Dictionary = data.get("player", {})
	if p.has("pos_x") and p.has("pos_y"):
		global_position = Vector2(float(p["pos_x"]), float(p["pos_y"]))
	if p.has("health"):
		health = int(p["health"])


# ── Main Process ─────────────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	read_input()
	_update_freeze_system(delta)
	_update_iframes(delta)
	update_state(delta)
	move_and_slide()


# ── States: Enter ────────────────────────────────────────────────────
func enter_idle_state() -> void:
	attack_hit_box.monitoring = false
	current_state = PlayerState.idle
	switch_animation_attack()
	animation.play("idle")


func enter_walk_state() -> void:
	attack_hit_box.monitoring = false
	current_state = PlayerState.walk
	switch_animation_attack()
	animation.play("walk")


func enter_dash_state() -> void:
	current_state = PlayerState.dash
	dash_direction = move_direction * dash_distance_multiplier
	dash_timer = dash_time
	_is_invincible = true
	switch_animation_attack()
	animation.play("dash")


func enter_attack_state() -> void:
	current_state = PlayerState.attack
	attack_hit_box.monitoring = true
	animation.play("attack")
	switch_animation_attack()
	swing_attack.play()
	velocity = Vector2.ZERO


func enter_death_state() -> void:
	current_state = PlayerState.dead
	attack_hit_box.monitoring = false
	animation.play("death")
	switch_animation_attack()
	velocity = Vector2.ZERO


# ── States: Tick ─────────────────────────────────────────────────────
func idle_state(delta: float) -> void:
	move(delta)
	if velocity != Vector2.ZERO:
		enter_walk_state(); return
	if Input.get_action_strength("Dash") and _dash_cd <= 0.0:
		enter_dash_state(); return
	if Input.get_action_strength("Attack"):
		enter_attack_state()


func walk_state(delta: float) -> void:
	move(delta)
	if velocity == Vector2.ZERO:
		enter_idle_state(); return
	if Input.get_action_strength("Dash") and _dash_cd <= 0.0:
		enter_dash_state(); return
	if Input.get_action_strength("Attack"):
		enter_attack_state()


func dash_state(delta: float) -> void:
	velocity = dash_direction * dash_speed
	dash_timer -= delta
	if dash_timer <= 0:
		_dash_cd = _get_dash_cooldown()
		_is_invincible = false
		if move_direction == Vector2.ZERO:
			enter_idle_state()
		else:
			enter_walk_state()


func attack_state(_delta: float) -> void:
	update_hitbox_offset()
	if animation.animation == "attack" and not animation.is_playing():
		enter_idle_state()


func attacked_state(_delta: float) -> void:
	pass


func dead_state(_delta: float) -> void:
	if animation.animation == "death" and not animation.is_playing():
		get_tree().change_scene_to_file.call_deferred(GAME_OVER_SCENE)


func update_state(delta: float) -> void:
	match current_state:
		PlayerState.idle:    idle_state(delta)
		PlayerState.walk:    walk_state(delta)
		PlayerState.attack:  attack_state(delta)
		PlayerState.dash:    dash_state(delta)
		PlayerState.dead:    dead_state(delta)


# ── Movement ─────────────────────────────────────────────────────────
func read_input() -> void:
	move_direction = Input.get_vector("Left", "Right", "Up", "Down")


func move(_delta: float) -> void:
	update_direction()
	velocity = move_direction * speed


func update_direction() -> void:
	update_hitbox_offset()
	mouse_pos = get_global_mouse_position()
	animation.flip_h = mouse_pos.x < global_position.x


func update_hitbox_offset() -> void:
	mouse_pos = get_global_mouse_position()
	var direction := (mouse_pos - global_position).normalized()
	attack_hit_box.position = direction * hitbox_offset.x


# ── Combat ───────────────────────────────────────────────────────────
func take_damage(amount: int) -> void:
	if current_state == PlayerState.dead:
		return
	if _is_invincible or _iframe_timer > 0.0:
		return
	health = max(health - amount, 0)
	_iframe_timer = IFRAME_DURATION
	if health <= 0:
		enter_death_state()


func attack_body_entered(body: Node2D) -> void:
	if body.is_in_group("Enemy"):
		var dmg := attack_damage_percent * (DAMAGE_BOOST_MULTIPLIER if _damage_boosted else 1.0)
		body.take_damage(dmg)


func switch_animation_attack() -> void:
	match current_state:
		PlayerState.attack:
			attack_animation.play("attack")
			attack_animation.look_at(mouse_pos)
		_:
			attack_animation.play("aim")
			attack_animation.rotation = 0.0


# ── Skills (chamadas pelo HUD) ───────────────────────────────────────
func _use_heal() -> void:
	health = min(health + HEAL_AMOUNT, max_hp)
	_heal_cd = HEAL_CD


func _use_damage_boost() -> void:
	_damage_boosted = true
	_damage_boost_remaining = DAMAGE_BOOST_DURATION
	_damage_cd = DAMAGE_CD
	animation.modulate = Color(1.4, 0.7, 0.2)


func has_ability(ability: String) -> bool:
	return active_abilities.has(ability)


# ── Absorb ───────────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Activate"):
		if absorb_data != null:
			absorb_component.absorb(absorb_data)


func _on_form_applied(data: AbsorbResource) -> void:
	print("Forma absorvida: ", data.form_name)


func _on_form_expired() -> void:
	enter_idle_state()


func _on_form_unlocked(data: AbsorbResource) -> void:
	absorb_data = data


# ── Iframes ──────────────────────────────────────────────────────────
func _update_iframes(delta: float) -> void:
	if _iframe_timer <= 0.0:
		animation.modulate.a = 1.0
		return

	_iframe_timer -= delta
	_blink_timer -= delta
	if _blink_timer <= 0.0:
		_blink_timer = BLINK_INTERVAL
		animation.modulate.a = 0.3 if animation.modulate.a > 0.5 else 1.0

	if _iframe_timer <= 0.0:
		_iframe_timer = 0.0
		animation.modulate.a = 1.0


# ── Freeze System ────────────────────────────────────────────────────
func _update_freeze_system(delta: float) -> void:
	if current_state == PlayerState.dead:
		return

	var in_snow := global_position.x >= SNOW_BIOME_X
	if not in_snow:
		if _is_freezing:
			_is_freezing = false
			if not _damage_boosted:
				animation.modulate = Color.WHITE
		_freeze_timer = FREEZE_DELAY
		_campfire_warmup = 0.0
		_freeze_tick_timer = FREEZE_TICK
		if is_instance_valid(_freeze_label):
			_freeze_label.visible = false
		_update_vignette(0.0, delta)
		return

	var near_fire := _campfire_count > 0

	if near_fire:
		_campfire_warmup += delta
		if _is_freezing:
			_is_freezing = false
			if not _damage_boosted:
				animation.modulate = Color.WHITE
		if _campfire_warmup >= CAMPFIRE_WARMUP:
			_freeze_timer = FREEZE_DELAY
			_campfire_warmup = CAMPFIRE_WARMUP
	else:
		_campfire_warmup = 0.0
		_freeze_timer -= delta
		if _freeze_timer <= 0.0:
			_freeze_timer = 0.0
			_is_freezing = true

	if _is_freezing:
		animation.modulate = Color(0.6, 0.8, 1.0)
		_freeze_tick_timer -= delta
		if _freeze_tick_timer <= 0.0:
			_freeze_tick_timer = FREEZE_TICK
			take_damage(FREEZE_DAMAGE)
		_update_vignette(1.0, delta)
	else:
		if not _damage_boosted:
			animation.modulate = Color.WHITE
		_update_vignette(0.0, delta)

	if is_instance_valid(_freeze_label):
		if in_snow and not near_fire and not _is_freezing and _freeze_timer < FREEZE_DELAY:
			_freeze_label.text = "Frio: %ds" % ceili(_freeze_timer)
			_freeze_label.visible = true
		elif _is_freezing:
			_freeze_label.text = "CONGELANDO!"
			_freeze_label.visible = true
		elif near_fire and _campfire_warmup < CAMPFIRE_WARMUP:
			_freeze_label.text = "Aquecendo: %ds" % ceili(CAMPFIRE_WARMUP - _campfire_warmup)
			_freeze_label.visible = true
		else:
			_freeze_label.visible = false


func enter_campfire_range() -> void:
	_campfire_count += 1


func exit_campfire_range() -> void:
	_campfire_count = max(_campfire_count - 1, 0)
	if _campfire_count == 0:
		_campfire_warmup = 0.0


func _update_vignette(target_intensity: float, delta: float) -> void:
	if not is_instance_valid(_freeze_shader):
		return
	_freeze_vignette_intensity = move_toward(_freeze_vignette_intensity, target_intensity, delta * 1.5)
	_freeze_shader.set_shader_parameter("intensity", _freeze_vignette_intensity)
