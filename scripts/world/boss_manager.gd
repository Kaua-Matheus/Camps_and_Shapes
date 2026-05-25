extends Node

const GOLEM_SCENE = preload("res://entities/enemies/golem.tscn")

const BOSS_TRIGGER_X: float = 2000.0
const BOSS_MAX_HP: int = 300
const BOSS_DAMAGE: float = 35.0
const BOSS_SPEED: int = 80
const BOSS_MELEE_RANGE: float = 100.0
const BOSS_SCALE: float = 2.5

var boss_spawned: bool = false
var boss_defeated: bool = false
var boss_ref = null
var player_ref: Node2D = null

var _boss_canvas: CanvasLayer = null
var _boss_hp_bar: ProgressBar = null
var _debug_timer: float = 0.0

func _ready() -> void:
	print("[BossManager] Autoload iniciado.")

func _process(delta: float) -> void:
	if not is_instance_valid(player_ref):
		player_ref = get_tree().get_first_node_in_group("Player")
		if player_ref:
			print("[BossManager] Player encontrado.")
		return

	_debug_timer += delta
	if _debug_timer >= 3.0:
		_debug_timer = 0.0
		print("[BossManager] Player X: %.0f | Trigger em: %.0f | Boss spawned: %s" % [player_ref.global_position.x, BOSS_TRIGGER_X, str(boss_spawned)])

	if boss_spawned:
		_update_boss_hp_bar()
		return

	if player_ref.global_position.x >= BOSS_TRIGGER_X:
		_spawn_boss()

func _spawn_boss() -> void:
	boss_spawned = true
	print("[BossManager] Boss spawning!")

	var boss := GOLEM_SCENE.instantiate()
	boss.max_hp = BOSS_MAX_HP
	boss.damage_percent = BOSS_DAMAGE
	boss.speed = BOSS_SPEED
	boss.melee_range = BOSS_MELEE_RANGE
	boss.scale = Vector2(BOSS_SCALE, BOSS_SCALE)
	boss.modulate = Color(1.0, 0.25, 0.25)

	var mid_y := (WaveManager.MAP_MIN_Y + WaveManager.MAP_MAX_Y) / 2.0
	get_tree().current_scene.add_child(boss)
	boss.global_position = Vector2(BOSS_TRIGGER_X + 200.0, mid_y)

	boss_ref = boss
	_create_boss_hp_bar()

func _create_boss_hp_bar() -> void:
	_boss_canvas = CanvasLayer.new()
	_boss_canvas.layer = 10
	get_tree().current_scene.add_child(_boss_canvas)

	# Âncora top-right: offsets negativos = distância da borda direita/superior
	# Mesmo tamanho do player bar (width=160, height=16, margin=8)
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
		_boss_hp_bar.value = boss_ref.current_hp

func reset() -> void:
	boss_spawned = false
	boss_defeated = false
	boss_ref = null
	player_ref = null
	if _boss_canvas != null and is_instance_valid(_boss_canvas):
		_boss_canvas.queue_free()
	_boss_canvas = null
	_boss_hp_bar = null
