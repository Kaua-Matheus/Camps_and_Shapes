extends Node

signal form_unlocked(data: AbsorbResource)

@export var unlock_configs: Array[UnlockConfig] = []

var _kill_counts: Dictionary = {}  # { "golem": 3, "slime": 1 }

func _ready() -> void:
	print("Inicializando configuracao do goblin")
	var goblin_config = UnlockConfig.new()
	goblin_config.enemy_type = "Goblin"
	goblin_config.kills_needed = 3
	goblin_config.form_to_unlock = load("res://entities/enemies/goblin_resource.tres")
	unlock_configs.append(goblin_config)
	
	for config in unlock_configs:
		print(config.enemy_type)
	
func register_kill(enemy_type: String) -> void:
	print("Inimigo morto (register kill): ", enemy_type)
	
	if enemy_type == "":
		return

	_kill_counts[enemy_type] = _kill_counts.get(enemy_type, 0) + 1
	print("_kill_counts ", _kill_counts[enemy_type])
	print(get_kills(enemy_type))
	
	print(unlock_configs)

	for config in unlock_configs:
		if config.enemy_type == enemy_type:
			if _kill_counts[enemy_type] >= config.kills_needed:
				print("Forma desbloqueada")
				
				_kill_counts[enemy_type] = 0
				
				call_deferred("emit_signal", "form_unlocked", config.form_to_unlock)

func get_kills(enemy_type: String) -> int:
	return _kill_counts.get(enemy_type, 0)
