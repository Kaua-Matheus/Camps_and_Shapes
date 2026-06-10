class_name Enemy
extends CharacterBody2D
#extends Enemy

## --- Signals ---
signal died(enemy_type: String)


## --- Consts ---

## --- Export Vars ---
@export var absorb_data: AbsorbResource
@export var enemy_type: String = "Goblin"  # ex: "golem", "slime"

## --- Consts ---

## --- Vars ---
var health: int = 20

func on_absorbed_by_player() -> void:
	# opcional: animação de morte, efeito visual, etc.
	queue_free()

# --- Damage and Kill ---
func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		die()

func die() -> void:
	emit_signal("died", enemy_type)
	print("O sinal foi emitido")
	queue_free()
