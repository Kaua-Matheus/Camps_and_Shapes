extends Node

const SAVE_PATH := "user://save.dat"
const AUTO_SAVE_INTERVAL: float = 30.0

var is_continuing: bool = false
var _auto_save_timer: float = 0.0

func _process(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("Player")
	if player == null:
		_auto_save_timer = 0.0
		return
	_auto_save_timer += delta
	if _auto_save_timer >= AUTO_SAVE_INTERVAL:
		_auto_save_timer = 0.0
		save_game()

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func save_game() -> void:
	var player := get_tree().get_first_node_in_group("Player")
	if player == null:
		return
	var data := {
		"player": {
			"pos_x": player.global_position.x,
			"pos_y": player.global_position.y,
			"health": player.health
		},
		"wave": {
			"current_wave": WaveManager.current_wave,
			"wave_timer": WaveManager.wave_timer
		},
		"boss": {
			"boss_defeated": BossManager.boss_defeated,
			"gate_unlocks": BossManager.gate_unlocks
		}
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("[SaveManager] Falha ao abrir arquivo de save: " + str(FileAccess.get_open_error()))
		return
	file.store_string(JSON.stringify(data))
	file.close()
	print("[SaveManager] Salvo — onda %d, HP %d" % [WaveManager.current_wave, player.health])

func load_save() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return {}
	var text := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary:
		return parsed
	return {}
