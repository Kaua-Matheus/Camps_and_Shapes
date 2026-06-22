class_name AbsorbComponent
extends Node

signal form_applied(data: AbsorbResource)
signal form_expired

# Cooldown após o término de cada transformação
const FORM_COOLDOWN: float = 15.0
var _form_cd: float = 0.0

var current_data: AbsorbResource = null
var _timer: float = 0.0
var _active: bool = false

var _player: CharacterBody2D


func _ready() -> void:
	_player = get_parent() as CharacterBody2D
	if _player == null:
		push_error("AbsorbComponent precisa ser filho de um CharacterBody2D. Pai: " + get_parent().get_class())


func _process(delta: float) -> void:
	# Decrementa o cooldown pós-forma
	if _form_cd > 0.0:
		_form_cd = max(_form_cd - delta, 0.0)

	if not _active:
		return

	_timer -= delta
	if _timer <= 0.0:
		revert()


func absorb(data: AbsorbResource) -> void:
	if _form_cd > 0.0:
		print("Forma em cooldown! Aguarde %.1fs" % _form_cd)
		return

	if _active:
		revert()

	current_data = data
	_timer = data.duration
	_active = true
	_apply_visuals()
	_apply_stats()
	emit_signal("form_applied", data)


func revert() -> void:
	if not _active:
		return
	_active = false
	current_data = null
	_form_cd = FORM_COOLDOWN   # inicia cooldown ao expirar

	_player.dash_cd_override = -1.0
	_player.dash_distance_multiplier = 1.0

	_restore_defaults()
	emit_signal("form_expired")


func _apply_visuals() -> void:
	var sprite = _player.get_node("AnimatedSprite2D")
	sprite.sprite_frames = current_data.sprite_frames


func _apply_stats() -> void:
	_player.speed = current_data.speed
	_player.active_abilities = current_data.abilities.duplicate()

	if current_data.dash_cooldown_override >= 0.0:
		_player.dash_cd_override = current_data.dash_cooldown_override
	if current_data.dash_distance_multiplier != 1.0:
		_player.dash_distance_multiplier = current_data.dash_distance_multiplier


func _restore_defaults() -> void:
	_player.speed = _player.base_speed
	_player.active_abilities.clear()
	_player.get_node("AnimatedSprite2D").sprite_frames = _player.default_frames


func get_time_remaining() -> float:
	return max(_timer, 0.0)


func get_form_cooldown() -> float:
	return _form_cd


func is_on_cooldown() -> bool:
	return _form_cd > 0.0


func is_transformed() -> bool:
	return _active
