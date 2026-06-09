extends Node

signal form_unlocked(data: AbsorbResource)

@export var unlock_configs: Array[UnlockConfig] = []

var _kill_counts: Dictionary = {}  # { "golem": 3, "slime": 1 }

func register_kill(enemy_type: String) -> void:
	if enemy_type == "":
		return

	_kill_counts[enemy_type] = _kill_counts.get(enemy_type, 0) + 1

	for config in unlock_configs:
		if config.enemy_type == enemy_type:
			if _kill_counts[enemy_type] >= config.kills_needed:
				emit_signal("form_unlocked", config.form_to_unlock)
				_kill_counts[enemy_type] = 0  # reseta o contador

func get_kills(enemy_type: String) -> int:
	return _kill_counts.get(enemy_type, 0)
