extends Node

const GOLEM_SCENE = preload("res://entities/enemies/golem.tscn")

const WAVE_INTERVAL: float = 12.0

const MAP_MIN_X: float = 80.0
const MAP_MAX_X: float = 3760.0
const MAP_MIN_Y: float = 90.0
const MAP_MAX_Y: float = 295.0
const MIN_SPAWN_DIST: float = 200.0

const MINI_MAX_HP: int = 8
const MINI_DAMAGE: float = 10.0
const MINI_SPEED: int = 130
const MINI_MELEE_RANGE: float = 28.0
const MINI_SCALE: float = 0.6

var current_wave: int = 0
var wave_timer: float = 0.0
var player_ref: Node2D = null
var _last_countdown: int = -1

func _process(delta: float) -> void:
	if not is_instance_valid(player_ref):
		player_ref = get_tree().get_first_node_in_group("Player")
		if player_ref == null:
			return
		_last_countdown = -1
		if SaveManager.is_continuing:
			var data := SaveManager.load_save()
			var wd: Dictionary = data.get("wave", {})
			current_wave = int(wd.get("current_wave", 0))
			wave_timer = float(wd.get("wave_timer", 0.0))
			SaveManager.is_continuing = false
		else:
			current_wave = 0
			wave_timer = 0.0
			BossManager.reset()
			_spawn_wave()
		return

	wave_timer += delta
	var seconds_left: int = int(WAVE_INTERVAL - wave_timer)
	if seconds_left != _last_countdown:
		_last_countdown = seconds_left
		print("[WaveManager] Próxima onda em %d s" % seconds_left)
	if wave_timer >= WAVE_INTERVAL:
		wave_timer = 0.0
		_last_countdown = -1
		_spawn_wave()

func _spawn_wave() -> void:
	current_wave += 1
	var count: int = 1 + current_wave * 2
	print("[WaveManager] Onda %d — %d mini golems" % [current_wave, count])
	for i in range(count):
		_spawn_mini_golem(_get_spawn_position())

func _get_spawn_position() -> Vector2:
	var pos := Vector2.ZERO
	for _attempt in range(30):
		pos = Vector2(
			randf_range(MAP_MIN_X, MAP_MAX_X),
			randf_range(MAP_MIN_Y, MAP_MAX_Y)
		)
		if not is_instance_valid(player_ref) or pos.distance_to(player_ref.global_position) >= MIN_SPAWN_DIST:
			return pos
	return pos

func _spawn_mini_golem(pos: Vector2) -> void:
	var mini := GOLEM_SCENE.instantiate()
	mini.health = MINI_MAX_HP
	mini.damage_on_player = MINI_DAMAGE
	mini.speed = MINI_SPEED
	mini.melee_range = MINI_MELEE_RANGE
	get_tree().current_scene.add_child(mini)
	mini.global_position = pos
	mini.scale = Vector2(MINI_SCALE, MINI_SCALE)
