extends Control

const NEXT_SCENE := "res://scenes/main_menu.tscn"
const MIN_LOAD_TIME := 2.0

const TIPS: Array[String] = [
	"Absorva inimigos com pouca vida para desbloquear novas formas!",
	"Conquiste acampamentos para garantir seu ponto de retorno.",
	"Use Q/E para alternar entre as formas desbloqueadas.",
	"Sua vida só é recuperada nos acampamentos conquistados.",
	"O botão direito usa a habilidade especial da forma ativa.",
	"Derrote o boss final no castelo para recuperar suas memórias.",
	"Cada forma absorvida possui um cooldown após ser utilizada.",
]

var _elapsed: float = 0.0
var _load_progress: float = 0.0
var _loading_done: bool = false
var _transitioning: bool = false

var _tip_timer: float = 0.0
var _tip_index: int = 0

var _dot_timer: float = 0.0
var _dot_count: int = 1

@onready var progress_bar: ProgressBar = $ProgressBar
@onready var percent_label: Label = $PercentLabel
@onready var tip_label: Label = $TipLabel
@onready var loading_label: Label = $LoadingLabel
@onready var slime_sprite: TextureRect = $SlimeContainer/SlimeSprite

func _ready() -> void:
	modulate.a = 0.0
	ResourceLoader.load_threaded_request(NEXT_SCENE)
	tip_label.text = "Dica: " + TIPS[0]
	_start_slime_animation()

	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.6)

func _process(delta: float) -> void:
	_elapsed += delta
	_tip_timer += delta
	_dot_timer += delta

	# Animate loading dots
	if _dot_timer >= 0.45:
		_dot_timer = 0.0
		_dot_count = (_dot_count % 3) + 1
		loading_label.text = "Carregando Veldora" + ".".repeat(_dot_count)

	# Cycle tips with fade transition
	if _tip_timer >= 3.5:
		_tip_timer = 0.0
		_tip_index = (_tip_index + 1) % TIPS.size()
		_animate_tip_change()

	# Poll loading progress
	if not _loading_done:
		var progress: Array = []
		var status := ResourceLoader.load_threaded_get_status(NEXT_SCENE, progress)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			_loading_done = true
			_load_progress = 1.0
		elif status == ResourceLoader.THREAD_LOAD_IN_PROGRESS and not progress.is_empty():
			_load_progress = progress[0]

	# Smooth bar animation
	var current := progress_bar.value / 100.0
	var target := _load_progress
	progress_bar.value = lerpf(current, target, 0.12) * 100.0
	percent_label.text = str(int(progress_bar.value)) + "%"

	if _loading_done and progress_bar.value >= 99.0 and _elapsed >= MIN_LOAD_TIME and not _transitioning:
		_transition()

func _animate_tip_change() -> void:
	var tween := create_tween()
	tween.tween_property(tip_label, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func(): tip_label.text = "Dica: " + TIPS[_tip_index])
	tween.tween_property(tip_label, "modulate:a", 1.0, 0.3)

func _transition() -> void:
	_transitioning = true
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	await tween.finished
	var scene := ResourceLoader.load_threaded_get(NEXT_SCENE) as PackedScene
	get_tree().change_scene_to_packed(scene)

func _start_slime_animation() -> void:
	slime_sprite.pivot_offset = Vector2(40.0, 40.0)

	var tween := create_tween().set_loops()

	# Rise: stretch vertically
	tween.parallel().tween_property(slime_sprite, "position:y", -14.0, 0.38)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(slime_sprite, "scale", Vector2(0.88, 1.14), 0.38)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	# Fall: compress vertically
	tween.parallel().tween_property(slime_sprite, "position:y", 0.0, 0.32)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(slime_sprite, "scale", Vector2(1.0, 1.0), 0.32)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)

	# Impact squash
	tween.tween_property(slime_sprite, "scale", Vector2(1.18, 0.80), 0.08)\
		.set_ease(Tween.EASE_OUT)

	# Recovery
	tween.tween_property(slime_sprite, "scale", Vector2(1.0, 1.0), 0.14)\
		.set_ease(Tween.EASE_IN_OUT)

	# Pause at ground
	tween.tween_interval(0.18)
