class_name Character
extends CharacterBody2D

@export var max_hp := 1000
@export var attack_damage_percent := 20.0

var health := 0
var is_dead := false

func _ready():
	health = max_hp

func take_damage(amount: int):
	if is_dead:
		return

	health = max(health - amount, 0)

	if health <= 0:
		die()

func die():
	is_dead = true
