class_name WolfBoss
extends CharacterBody2D

signal died(enemy_type: String)

@export var max_health: int = 200
@export var speed: int = 90
@export var aggro_range: float = 400.0
@export var melee_range: float = 40.0
@export var damage_on_player: float = 30.0
@export var melee_cooldown: float = 1.5
@export var enemy_type: String = "Wolf Boss"

@onready var animation: AnimatedSprite2D = $AnimatedSprite2D

var health: int = -1
var player_ref: Node2D = null
var _damage_timer: float = 0.0
var _dead: bool = false

func _ready() -> void:
	add_to_group("Enemy")
	if health <= 0:
		health = max_health
	animation.play("idle")

func _physics_process(delta: float) -> void:
	if _dead:
		return
	_damage_timer = max(_damage_timer - delta, 0.0)
	_find_player()
	_move_and_attack()
	move_and_slide()

func _find_player() -> void:
	if not is_instance_valid(player_ref):
		player_ref = get_tree().get_first_node_in_group("Player") as Node2D

func _move_and_attack() -> void:
	if not is_instance_valid(player_ref):
		velocity = Vector2.ZERO
		if animation.animation != &"idle":
			animation.play("idle")
		return

	var dist: Vector2 = player_ref.global_position - global_position
	var dist_len: float = dist.length()

	if dist_len > aggro_range:
		velocity = Vector2.ZERO
		if animation.animation != &"idle":
			animation.play("idle")
		return

	animation.flip_h = dist.x < 0.0

	if dist_len <= melee_range:
		velocity = Vector2.ZERO
		if not animation.is_playing() or animation.animation != &"attack":
			animation.play("attack")
		if _damage_timer <= 0.0:
			player_ref.take_damage(damage_on_player)
			_damage_timer = melee_cooldown
	else:
		velocity = dist.normalized() * speed
		if animation.animation != &"walk":
			animation.play("walk")

func take_damage(amount: float) -> void:
	if _dead:
		return
	health = max(health - int(round(amount)), 0)
	if health <= 0:
		die()

func die() -> void:
	if _dead:
		return
	_dead = true
	velocity = Vector2.ZERO
	set_physics_process(false)
	emit_signal("died", enemy_type)
	animation.play("death")
	await animation.animation_finished
	queue_free()
