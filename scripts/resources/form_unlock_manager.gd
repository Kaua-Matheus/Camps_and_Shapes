extends Node

signal form_unlocked(data: AbsorbResource)

@export var unlock_configs: Array[UnlockConfig] = []

var _kill_counts: Dictionary = {}  # { "golem": 3, "slime": 1 }

func _ready() -> void:
	# Goblin Config
	var goblin_config = UnlockConfig.new()
	goblin_config.enemy_type = "Goblin"
	goblin_config.kills_needed = 3
	goblin_config.form_to_unlock = load("res://entities/enemies/goblin/goblin_resource.tres")
	unlock_configs.append(goblin_config)
	
	# Golem Config
	var golem_config = UnlockConfig.new()
	golem_config.enemy_type = "Golem"
	golem_config.kills_needed = 3
	golem_config.form_to_unlock = load("res://entities/enemies/golem/golem_resource.tres")
	unlock_configs.append(golem_config)
	
	# Wolf Config
	var wolf_config = UnlockConfig.new()
	wolf_config.enemy_type = "Wolf"
	wolf_config.kills_needed = 2
	wolf_config.form_to_unlock = load("res://entities/enemies/wolf/wolf_resource.tres")
	unlock_configs.append(wolf_config)
	
	for config in unlock_configs:
		print(config.enemy_type)
	
func register_kill(enemy_type: String) -> void:
	print("Inimigo morto (register kill): ", enemy_type)
	
	if enemy_type == "":
		return

	_kill_counts[enemy_type] = _kill_counts.get(enemy_type, 0) + 1

	for config in unlock_configs:
		if config.enemy_type == enemy_type:
			if _kill_counts[enemy_type] >= config.kills_needed:
				print("Forma desbloqueada ", enemy_type)
				
				_kill_counts[enemy_type] = 0
				
				call_deferred("emit_signal", "form_unlocked", config.form_to_unlock)

func get_kills(enemy_type: String) -> int:
	return _kill_counts.get(enemy_type, 0)
