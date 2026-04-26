extends CharacterBody2D

var player_ref = null

@onready var animation: AnimatedSprite2D = $AnimatedSprite2D

@export var max_hp: int = 20
var current_hp: int

var is_dead: bool = false

enum GolemState {
	idle,
	walk,
	attack,
	#dead
}

const SPEED = 100
const MELEE_RANGE: float = 40.0

@export var damage_percent: float = 20.0
var damage_cooldown: float = 1.5
var damage_timer: float = 0.0

var status: GolemState

func _ready() -> void:
	
	# Hp
	current_hp = max_hp
	
	go_to_idle_state()


func _physics_process(delta: float) -> void:
	damage_timer -= delta * damage_cooldown

	if player_ref != null:
		go_to_walk_state()
		var distance: Vector2 = player_ref.global_position - global_position
		var direction: Vector2 = distance.normalized()
		var distance_length: float = distance.length()

		if distance_length <= MELEE_RANGE:
			velocity = Vector2.ZERO
			if damage_timer <= 0.0:
				player_ref.take_damage_percent(damage_percent)
				damage_timer = damage_cooldown
		else:
			velocity = SPEED * direction

	else:
		velocity = Vector2.ZERO
		go_to_idle_state()

	#match status:
		#GolemState.idle:
			#idle_state(delta)
		#GolemState.walk:
			#walk_state(delta)
		#GolemState.attack:
			#attack_state(delta)
		##GolemState.dead:
			##dead_state(delta)

	move_and_slide()
	
	
func go_to_idle_state():
	status = GolemState.idle
	animation.play("idle")
	
func go_to_walk_state():
	status = GolemState.walk
	animation.play("walk")
	
#func go_to_attack_state():
	#status = GolemState.attack
	##animation.play("attack")
	#velocity = Vector2.ZERO
	#can_throw = true
	
#func go_to_dead_state():
	#status = GolemState.dead
	#animation.play("dead")
	#velocity = Vector2.ZERO
	#hitbox.process_mode = Node.PROCESS_MODE_DISABLED
	
	
func idle_state(_delta):
	pass
	
		
func die() -> void:
	is_dead = true
	queue_free()
	
	
func take_damage(amount: int) -> void:
	if is_dead:
		return
	current_hp = max(current_hp - amount, 0)
	if current_hp <= 0:
		die()

func take_damage_percent(percent: float) -> void:
	take_damage(int(max_hp * percent / 20.0))


func player_body_entered(body: Node2D) -> void:
	print(body.get_groups())
	if body.is_in_group("Player"):
		player_ref = body


func player_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_ref = null
