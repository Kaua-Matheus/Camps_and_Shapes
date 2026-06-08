class_name Golem
extends Character

var player_ref = null

@onready var animation: AnimatedSprite2D = $AnimatedSprite2D

var current_hp: int

enum GolemState {
	idle,
	walk,
	attack,
	#dead
}

var current_state: GolemState

@export var speed: int = 100
@export var melee_range: float = 40.0

@export var damage_percent: float = 20.0

var distance: Vector2
var direction: Vector2
var distance_length: float

var damage_cooldown: float = 1.5
var damage_timer: float = 0.0

func _ready() -> void:
	
	# Hp
	current_hp = max_hp
	
	enter_idle_state()


func _physics_process(delta: float) -> void:
	damage_timer -= delta * damage_cooldown

	update_state(delta)

	move_and_slide()
	
	
func enter_idle_state():
	current_state = GolemState.idle
	animation.play("idle")
	
func enter_walk_state():
	current_state = GolemState.walk
	animation.play("walk")
	
#func enter_attack_state():
	#current_state = GolemState.attack
	##animation.play("attack")
	#velocity = Vector2.ZERO
	#can_throw = true
	
#func enter_dead_state():
	#current_state = GolemState.dead
	#animation.play("dead")
	#velocity = Vector2.ZERO
	#hitbox.process_mode = Node.PROCESS_MODE_DISABLED
	
	
func idle_state(_delta):
	if is_instance_valid(player_ref):
		enter_walk_state()
		return
	else:
		velocity = Vector2.ZERO
		enter_idle_state()
		return
	
func walk_state(_delta):
	distance = player_ref.global_position - global_position
	direction = distance.normalized()
	distance_length = distance.length()

	if distance_length <= melee_range:
		velocity = Vector2.ZERO
		if damage_timer <= 0.0:
			player_ref.take_attack_damage_percent(damage_percent)
			damage_timer = damage_cooldown
	
	else:
		velocity = speed * direction
	
		
func die() -> void:
	is_dead = true
	queue_free()
	
	
func take_damage(amount: int) -> void:
	if is_dead:
		return
	current_hp = max(current_hp - amount, 0)
	if current_hp <= 0:
		die()

func take_attack_damage_percent(percent: float) -> void:
	take_damage(int(max_hp * percent / 20.0))


func update_state(delta: float):
	
	match current_state:

		GolemState.idle:
			idle_state(delta)

		GolemState.walk:
			walk_state(delta)


func player_body_entered(body: Node2D) -> void:
	print(body.get_groups())
	if body.is_in_group("Player"):
		player_ref = body


func player_body_exited(_body: Node2D) -> void:
	pass
