extends Node

const GOLEM_BOSS_SCENE = preload("res://entities/boss/mecha_stone_golem/golem_boss.tscn")
const GOBLIN_BOSS_SCENE = preload("res://entities/boss/goblin_boss/goblin_boss.tscn")

# --- Goblin Boss (fim do bioma de grama → libera passagem para neve) ---
const GOBLIN_TRIGGER_X: float = 1800.0
const GOBLIN_SPAWN_X: float = 2100.0
const GOBLIN_SPAWN_Y: float = 192.0
const GOBLIN_MAX_HP: int = 200
const GOBLIN_DAMAGE: float = 30.0
const GOBLIN_SPEED: int = 90
const GOBLIN_SCALE: float = 2.0

# --- Snow Boss (fim do bioma de neve → libera passagem para lava) ---
const SNOW_BOSS_TRIGGER_X: float = 3600.0
const SNOW_BOSS_SPAWN_X: float = 4300.0
const SNOW_BOSS_SPAWN_Y: float = 192.0
const SNOW_BOSS_MAX_HP: int = 240
const SNOW_BOSS_DAMAGE: float = 28.0
const SNOW_BOSS_SPEED: int = 95
const SNOW_BOSS_SCALE: float = 2.1

# --- Golem Boss (bioma de lava → libera passagem para lava) ---
const BOSS_TRIGGER_X: float = 6200.0
const BOSS_SPAWN_X: float = 6500.0
const BOSS_SPAWN_Y: float = 192.0
const BOSS_MAX_HP: int = 300
const BOSS_DAMAGE: float = 35.0
const BOSS_SPEED: int = 80
const BOSS_MELEE_RANGE: float = 65.0
const BOSS_AGGRO_RANGE: float = 220.0
const BOSS_SCALE: float = 2.5

# --- Goblin Boss State ---
var goblin_spawned: bool = false
var goblin_defeated: bool = false
var goblin_ref = null
var _goblin_canvas: CanvasLayer = null
var _goblin_hp_bar: ProgressBar = null

# --- Snow Boss State ---
var snow_boss_spawned: bool = false
var snow_boss_defeated: bool = false
var snow_boss_ref = null
var _snow_boss_canvas: CanvasLayer = null
var _snow_boss_hp_bar: ProgressBar = null

# --- Golem Boss State ---
var boss_spawned: bool = false
var boss_defeated: bool = false
var boss_ref = null
var _boss_canvas: CanvasLayer = null
var _boss_hp_bar: ProgressBar = null

var player_ref: Node2D = null
var gate_unlocks: Dictionary = {
	"snow": false,
	"lava": false,
}

var _debug_timer: float = 0.0

func _ready() -> void:
	print("[BossManager] Autoload iniciado.")

func _process(delta: float) -> void:
	if not is_instance_valid(player_ref):
		player_ref = get_tree().get_first_node_in_group("Player")
		if player_ref:
			print("[BossManager] Player encontrado.")
			if boss_defeated and player_ref.has_method("unlock_heal"):
				player_ref.unlock_heal()
		return

	# Goblin boss (bioma de grama)
	if not goblin_defeated:
		if goblin_spawned:
			_update_goblin_hp_bar()
		elif player_ref.global_position.x >= GOBLIN_TRIGGER_X:
			_spawn_goblin_boss()

	# Snow boss (bioma de neve)
	if not snow_boss_defeated:
		if snow_boss_spawned:
			_update_snow_boss_hp_bar()
		elif player_ref.global_position.x >= SNOW_BOSS_TRIGGER_X:
			_spawn_snow_boss()

	# Golem boss (bioma de lava)
	if not boss_defeated:
		_debug_timer += delta
		if _debug_timer >= 3.0:
			_debug_timer = 0.0
			print("[BossManager] Player X: %.0f | Trigger em: %.0f | Boss spawned: %s" % [player_ref.global_position.x, BOSS_TRIGGER_X, str(boss_spawned)])

		if boss_spawned:
			_update_boss_hp_bar()
		elif player_ref.global_position.x >= BOSS_TRIGGER_X and _is_lava_area_loaded():
			_spawn_boss()

# --- Goblin Boss ---

func _spawn_goblin_boss() -> void:
	goblin_spawned = true
	print("[BossManager] Goblin Boss spawning!")

	var boss := GOBLIN_BOSS_SCENE.instantiate()
	boss.max_health = GOBLIN_MAX_HP
	boss.health = GOBLIN_MAX_HP
	boss.damage_on_player = GOBLIN_DAMAGE
	boss.speed = GOBLIN_SPEED
	boss.scale = Vector2(GOBLIN_SCALE, GOBLIN_SCALE)

	get_tree().current_scene.add_child(boss)
	boss.global_position = Vector2(GOBLIN_SPAWN_X, GOBLIN_SPAWN_Y)

	goblin_ref = boss
	_create_goblin_hp_bar()

func _create_goblin_hp_bar() -> void:
	_goblin_canvas = CanvasLayer.new()
	_goblin_canvas.layer = 10
	get_tree().current_scene.add_child(_goblin_canvas)

	_goblin_hp_bar = ProgressBar.new()
	_goblin_hp_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_goblin_hp_bar.offset_left = -168.0
	_goblin_hp_bar.offset_top = 8.0
	_goblin_hp_bar.offset_right = -8.0
	_goblin_hp_bar.offset_bottom = 24.0
	_goblin_hp_bar.max_value = GOBLIN_MAX_HP
	_goblin_hp_bar.value = GOBLIN_MAX_HP
	_goblin_hp_bar.show_percentage = false
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = Color(0.1, 0.6, 0.1)
	_goblin_hp_bar.add_theme_stylebox_override("fill", fill_style)
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.05, 0.2, 0.05)
	_goblin_hp_bar.add_theme_stylebox_override("background", bg_style)
	_goblin_canvas.add_child(_goblin_hp_bar)

	var label := Label.new()
	label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	label.offset_left = -168.0
	label.offset_top = 8.0
	label.offset_right = -8.0
	label.offset_bottom = 24.0
	label.text = "GOBLIN CHEFE"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	_goblin_canvas.add_child(label)

func _update_goblin_hp_bar() -> void:
	if not is_instance_valid(goblin_ref):
		if _goblin_canvas != null and is_instance_valid(_goblin_canvas):
			_goblin_canvas.queue_free()
		_goblin_canvas = null
		_goblin_hp_bar = null
		if not goblin_defeated:
			goblin_defeated = true
			unlock_gate("snow")
		return

	if _goblin_hp_bar != null:
		_goblin_hp_bar.value = goblin_ref.health

# --- Snow Boss ---

func _spawn_snow_boss() -> void:
	snow_boss_spawned = true
	print("[BossManager] Snow Boss spawning!")

	var boss := GOBLIN_BOSS_SCENE.instantiate()
	boss.max_health = SNOW_BOSS_MAX_HP
	boss.health = SNOW_BOSS_MAX_HP
	boss.damage_on_player = SNOW_BOSS_DAMAGE
	boss.speed = SNOW_BOSS_SPEED
	boss.scale = Vector2(SNOW_BOSS_SCALE, SNOW_BOSS_SCALE)

	get_tree().current_scene.add_child(boss)
	boss.global_position = Vector2(SNOW_BOSS_SPAWN_X, SNOW_BOSS_SPAWN_Y)

	snow_boss_ref = boss
	_create_snow_boss_hp_bar()

func _create_snow_boss_hp_bar() -> void:
	_snow_boss_canvas = CanvasLayer.new()
	_snow_boss_canvas.layer = 10
	get_tree().current_scene.add_child(_snow_boss_canvas)

	_snow_boss_hp_bar = ProgressBar.new()
	_snow_boss_hp_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_snow_boss_hp_bar.offset_left = -168.0
	_snow_boss_hp_bar.offset_top = 8.0
	_snow_boss_hp_bar.offset_right = -8.0
	_snow_boss_hp_bar.offset_bottom = 24.0
	_snow_boss_hp_bar.max_value = SNOW_BOSS_MAX_HP
	_snow_boss_hp_bar.value = SNOW_BOSS_MAX_HP
	_snow_boss_hp_bar.show_percentage = false
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = Color(0.45, 0.75, 1.0)
	_snow_boss_hp_bar.add_theme_stylebox_override("fill", fill_style)
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.08, 0.14, 0.22)
	_snow_boss_hp_bar.add_theme_stylebox_override("background", bg_style)
	_snow_boss_canvas.add_child(_snow_boss_hp_bar)

	var label := Label.new()
	label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	label.offset_left = -168.0
	label.offset_top = 8.0
	label.offset_right = -8.0
	label.offset_bottom = 24.0
	label.text = "BOSS DA NEVE"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	_snow_boss_canvas.add_child(label)

func _update_snow_boss_hp_bar() -> void:
	if not is_instance_valid(snow_boss_ref):
		if _snow_boss_canvas != null and is_instance_valid(_snow_boss_canvas):
			_snow_boss_canvas.queue_free()
		_snow_boss_canvas = null
		_snow_boss_hp_bar = null
		if not snow_boss_defeated:
			snow_boss_defeated = true
			unlock_gate("lava")
		return

	if _snow_boss_hp_bar != null:
		_snow_boss_hp_bar.value = snow_boss_ref.health

# --- Golem Boss (original) ---

func _spawn_boss() -> void:
	boss_spawned = true
	print("[BossManager] Boss spawning!")

	var boss := GOLEM_BOSS_SCENE.instantiate()
	boss.max_health = BOSS_MAX_HP
	boss.health = BOSS_MAX_HP
	boss.damage_percent = BOSS_DAMAGE
	boss.speed = BOSS_SPEED
	boss.melee_range = BOSS_MELEE_RANGE
	boss.aggro_range = BOSS_AGGRO_RANGE
	boss.scale = Vector2(BOSS_SCALE, BOSS_SCALE)
	boss.dash_hit_range *= BOSS_SCALE
	boss.laser_width *= BOSS_SCALE
	boss.laser_range *= BOSS_SCALE

	get_tree().current_scene.add_child(boss)
	boss.global_position = Vector2(BOSS_SPAWN_X, BOSS_SPAWN_Y)

	boss_ref = boss
	_create_boss_hp_bar()

func _is_lava_area_loaded() -> bool:
	var scene := get_tree().current_scene
	return scene != null and scene.find_child("LavaTerrain", true, false) != null

func _create_boss_hp_bar() -> void:
	_boss_canvas = CanvasLayer.new()
	_boss_canvas.layer = 10
	get_tree().current_scene.add_child(_boss_canvas)

	_boss_hp_bar = ProgressBar.new()
	_boss_hp_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_boss_hp_bar.offset_left = -168.0
	_boss_hp_bar.offset_top = 8.0
	_boss_hp_bar.offset_right = -8.0
	_boss_hp_bar.offset_bottom = 24.0
	_boss_hp_bar.max_value = BOSS_MAX_HP
	_boss_hp_bar.value = BOSS_MAX_HP
	_boss_hp_bar.show_percentage = false
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = Color(0.75, 0.1, 0.1)
	_boss_hp_bar.add_theme_stylebox_override("fill", fill_style)
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.2, 0.05, 0.05)
	_boss_hp_bar.add_theme_stylebox_override("background", bg_style)
	_boss_canvas.add_child(_boss_hp_bar)

	var label := Label.new()
	label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	label.offset_left = -168.0
	label.offset_top = 8.0
	label.offset_right = -8.0
	label.offset_bottom = 24.0
	label.text = "GOLEM CHEFE"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	_boss_canvas.add_child(label)

func _update_boss_hp_bar() -> void:
	if not is_instance_valid(boss_ref):
		if _boss_canvas != null and is_instance_valid(_boss_canvas):
			_boss_canvas.queue_free()
		_boss_canvas = null
		_boss_hp_bar = null
		if not boss_defeated and is_instance_valid(player_ref):
			boss_defeated = true
			player_ref.unlock_heal()
		return

	if _boss_hp_bar != null:
		_boss_hp_bar.value = boss_ref.health

# --- Gate Control ---

func is_gate_unlocked(gate_id: String) -> bool:
	return bool(gate_unlocks.get(gate_id, false))

func unlock_gate(gate_id: String) -> void:
	if gate_id == "":
		return
	if is_gate_unlocked(gate_id):
		return
	gate_unlocks[gate_id] = true
	print("[BossManager] Gate unlocked: %s" % gate_id)

# --- Save / Load ---

func load_progress(data: Dictionary) -> void:
	if data.is_empty():
		return

	var saved_unlocks: Variant = data.get("gate_unlocks", {})
	if saved_unlocks is Dictionary:
		for gate_id in gate_unlocks.keys():
			gate_unlocks[gate_id] = bool(saved_unlocks.get(gate_id, gate_unlocks[gate_id]))

	if data.has("boss_defeated"):
		boss_defeated = bool(data["boss_defeated"])

	# Inferir derrota do goblin boss pelo estado do portão de neve
	if gate_unlocks.get("snow", false):
		goblin_defeated = true
		goblin_spawned = true

	# Inferir derrota do boss da neve pelo estado do portão de lava
	if gate_unlocks.get("lava", false):
		snow_boss_defeated = true
		snow_boss_spawned = true

func reset() -> void:
	goblin_spawned = false
	goblin_defeated = false
	goblin_ref = null
	snow_boss_spawned = false
	snow_boss_defeated = false
	snow_boss_ref = null
	if _goblin_canvas != null and is_instance_valid(_goblin_canvas):
		_goblin_canvas.queue_free()
	_goblin_canvas = null
	_goblin_hp_bar = null
	if _snow_boss_canvas != null and is_instance_valid(_snow_boss_canvas):
		_snow_boss_canvas.queue_free()
	_snow_boss_canvas = null
	_snow_boss_hp_bar = null

	boss_spawned = false
	boss_defeated = false
	boss_ref = null
	_debug_timer = 0.0
	player_ref = null
	gate_unlocks = {
		"snow": false,
		"lava": false,
	}
	if _boss_canvas != null and is_instance_valid(_boss_canvas):
		_boss_canvas.queue_free()
	_boss_canvas = null
	_boss_hp_bar = null
