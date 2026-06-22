extends Node

const GOLEM_SCENE = preload("res://entities/enemies/golem/golem.tscn")
const WOLF_SCENE = preload("res://entities/enemies/wolf/wolf.tscn")
const GOBLIN_SCENE = preload("res://entities/enemies/goblin/goblin.tscn")

var enemy_pool = [
	{
		"scene": GOLEM_SCENE,
		"weight": 50
	},
	{
		"scene": WOLF_SCENE,
		"weight": 30
	},
	{
		"scene": GOBLIN_SCENE,
		"weight": 20
	}
]


const WAVE_INTERVAL: float = 12.0

# Quantidade
const MAX_ENEMIES: int = 20

var active_enemies: Array[Node] = []

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
var player_ref: Player = null
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
			BossManager.load_progress(data.get("boss", {}))
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
		if get_enemy_count() >= MAX_ENEMIES:
			break
		_spawn_enemy(_get_random_enemy(), _get_spawn_position())


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


func _spawn_enemy(scene: PackedScene, pos: Vector2):

	var enemy = scene.instantiate()
	get_tree().current_scene.add_child(enemy)
	enemy.global_position = pos
	active_enemies.append(enemy)
	enemy.tree_exited.connect(
		func():
			active_enemies.erase(enemy)
	)


func _clean_enemy_list():

	for enemy in active_enemies.duplicate():

		if not is_instance_valid(enemy):
			active_enemies.erase(enemy)


func get_enemy_count() -> int:
	_clean_enemy_list()
	return active_enemies.size()


func _get_random_enemy():

	var total_weight := 0

	for enemy in enemy_pool:
		total_weight += enemy.weight

	var random_value = randi_range(0, total_weight)
	var current_weight := 0

	for enemy in enemy_pool:
		current_weight += enemy.weight
		if random_value <= current_weight:
			return enemy.scene
			
	return GOBLIN_SCENE
