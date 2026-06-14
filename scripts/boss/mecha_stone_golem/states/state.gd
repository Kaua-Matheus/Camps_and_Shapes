class_name GolemBossState
extends Node2D

@onready var debug_label: Label = owner.find_child("debug", true, false) as Label
@onready var player: Node2D = get_tree().get_first_node_in_group("Player") as Node2D
@onready var animation_player: AnimationPlayer = owner.find_child("AnimationPlayer", true, false) as AnimationPlayer
@onready var boss: GolemBoss = owner as GolemBoss

func _ready() -> void:
	set_physics_process(false)

func enter() -> void:
	player = get_tree().get_first_node_in_group("Player") as Node2D
	set_physics_process(true)

func exit() -> void:
	set_physics_process(false)

func transition() -> void:
	pass

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("Player") as Node2D
	if boss != null:
		boss.update_player_direction()

	transition()

	if debug_label != null:
		debug_label.text = name
