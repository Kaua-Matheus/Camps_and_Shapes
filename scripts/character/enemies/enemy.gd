class_name Enemy
extends CharacterBody2D


# Only one enum, extended by the mother class
## --- Declaratives ---
enum EnemyState { idle, walk, attack, dead }


## --- Signals ---
signal died(enemy_type: String)


## --- Export Vars ---
@export var absorb_data: AbsorbResource
@export var enemy_type: String = ""  # ex: "golem", "slime"

## --- OnReady Vars ---
@onready var animation: AnimatedSprite2D = $AnimatedSprite2D

### --- Inner Stats ---
var health: int = 40
var current_state: EnemyState


## --- Enter In (Functions) ---
func enter_idle_state():
	current_state = EnemyState.idle
	animation.play("idle")
	
func enter_walk_state():
	current_state = EnemyState.walk
	animation.play("walk")
	
func enter_attack_state():
	current_state = EnemyState.attack
	animation.play("attack")
	velocity = Vector2.ZERO
	
func enter_dead_state():
	current_state = EnemyState.dead
	animation.play("death")
	velocity = Vector2.ZERO


# --- Damage and Kill ---
func take_damage(amount: int) -> void:
	health -= amount
	if current_state == EnemyState.dead:
		return
	if health <= 0:
		enter_dead_state()


func die() -> void:
	emit_signal("died", enemy_type)
	print("%s morreu.." % [enemy_type])
	queue_free()
