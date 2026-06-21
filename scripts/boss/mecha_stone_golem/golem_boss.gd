class_name GolemBoss
extends CharacterBody2D

signal died(enemy_type: String)

@export var max_health: int = 300
@export var speed: int = 80
@export var aggro_range: float = 460.0
@export var melee_range: float = 30.0
@export var damage_percent: float = 35.0
@export var melee_cooldown: float = 0.875
@export var dash_damage: int = 28
@export var dash_hit_range: float = 42.0
@export var laser_damage: int = 24
@export var laser_range: float = 520.0
@export var laser_width: float = 22.0
@export var enemy_type: String = "Golem Boss"

@onready var progress_bar: ProgressBar = find_child("ProgressBar", true, false) as ProgressBar
@onready var sprite: Sprite2D = $Sprite2D
@onready var fsm: Node = $FiniteStateMachine

var health: int = -1
var direction: Vector2 = Vector2.ZERO
var player_ref: Node2D = null

var _damage_timer: float = 0.0
var _dash_hit_done: bool = false
var _dead: bool = false

func _ready() -> void:
	add_to_group("Enemy")
	if health <= 0:
		health = max_health
	_update_health_bar()
	if progress_bar != null:
		progress_bar.visible = false
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	if _dead:
		return

	update_player_direction()
	_damage_timer = max(_damage_timer - delta, 0.0)

	if direction == Vector2.ZERO:
		velocity = Vector2.ZERO
	else:
		velocity = direction.normalized() * speed
		sprite.flip_h = direction.x < 0.0

	move_and_slide()

func update_player_direction() -> void:
	if not is_instance_valid(player_ref):
		player_ref = get_tree().get_first_node_in_group("Player") as Node2D

	if is_instance_valid(player_ref):
		direction = player_ref.global_position - global_position
	else:
		direction = Vector2.ZERO

func try_melee_hit() -> void:
	update_player_direction()
	if _damage_timer > 0.0:
		return
	if not is_instance_valid(player_ref):
		return
	if direction.length() > melee_range:
		return
	if _damage_player(int(round(damage_percent))):
		_damage_timer = melee_cooldown

func reset_dash_hit() -> void:
	_dash_hit_done = false

func try_dash_hit() -> void:
	if _dash_hit_done:
		return

	update_player_direction()
	if not is_instance_valid(player_ref):
		return
	if direction.length() > dash_hit_range:
		return
	if _damage_player(dash_damage):
		_dash_hit_done = true

func try_laser_hit(origin: Vector2, beam_direction: Vector2) -> bool:
	if beam_direction == Vector2.ZERO:
		return false

	update_player_direction()
	if not is_instance_valid(player_ref):
		return false

	var to_player := player_ref.global_position - origin
	var laser_dir := beam_direction.normalized()
	var forward_distance := to_player.dot(laser_dir)
	if forward_distance < 0.0 or forward_distance > laser_range:
		return false

	var closest_point := origin + laser_dir * forward_distance
	var distance_to_beam := player_ref.global_position.distance_to(closest_point)
	if distance_to_beam > laser_width:
		return false

	return _damage_player(laser_damage)

func take_damage(amount: float) -> void:
	if _dead:
		return

	health = max(health - int(round(amount)), 0)
	_update_health_bar()

	if health <= 0:
		die()

func die() -> void:
	if _dead:
		return

	_dead = true
	velocity = Vector2.ZERO
	set_physics_process(false)
	emit_signal("died", enemy_type)

	if fsm != null and fsm.has_method("change_state"):
		fsm.change_state("Death")
	else:
		finish_death()

func finish_death() -> void:
	get_tree().change_scene_to_file("res://scenes/interface/cutscene_ending.tscn")

func _damage_player(amount: int) -> bool:
	if not is_instance_valid(player_ref):
		return false
	if not player_ref.has_method("take_damage"):
		return false

	player_ref.take_damage(amount)
	return true

func _update_health_bar() -> void:
	if progress_bar == null:
		return

	progress_bar.max_value = max_health
	progress_bar.value = health
