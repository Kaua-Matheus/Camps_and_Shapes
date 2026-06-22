extends Node

signal form_unlocked(data: AbsorbResource)

@export var unlock_configs: Array[UnlockConfig] = []

var _kill_counts: Dictionary = {}
# Formas já desbloqueadas — crescem conforme o player mata inimigos
var unlocked_forms: Array[AbsorbResource] = []


func _ready() -> void:
	var goblin_config = UnlockConfig.new()
	goblin_config.enemy_type = "Goblin"
	goblin_config.kills_needed = 3
	goblin_config.form_to_unlock = load("res://entities/enemies/goblin/goblin_resource.tres")
	unlock_configs.append(goblin_config)

	var golem_config = UnlockConfig.new()
	golem_config.enemy_type = "Golem"
	golem_config.kills_needed = 1
	golem_config.form_to_unlock = load("res://entities/enemies/golem/golem_resource.tres")
	unlock_configs.append(golem_config)

	var wolf_config = UnlockConfig.new()
	wolf_config.enemy_type = "Wolf"
	wolf_config.kills_needed = 2
	wolf_config.form_to_unlock = load("res://entities/enemies/wolf/wolf_resource.tres")
	unlock_configs.append(wolf_config)


func register_kill(enemy_type: String) -> void:
	if enemy_type == "":
		return

	_kill_counts[enemy_type] = _kill_counts.get(enemy_type, 0) + 1
	print("Kill registrado — %s: %d" % [enemy_type, _kill_counts[enemy_type]])

	for config in unlock_configs:
		if config.enemy_type != enemy_type:
			continue
		if _kill_counts[enemy_type] < config.kills_needed:
			continue

		_kill_counts[enemy_type] = 0

		# Só adiciona se ainda não estiver na lista
		var already := unlocked_forms.any(func(f): return f.form_name == config.form_to_unlock.form_name)
		if not already:
			unlocked_forms.append(config.form_to_unlock)
			print("Forma desbloqueada: ", config.form_to_unlock.form_name)
			call_deferred("emit_signal", "form_unlocked", config.form_to_unlock)


func get_kills(enemy_type: String) -> int:
	return _kill_counts.get(enemy_type, 0)
