class_name AbsorbComponent
extends Node

signal form_applied(data: AbsorbResource)
signal form_expired

var current_data: AbsorbResource = null
var _timer: float = 0.0
var _active: bool = false

var _player: CharacterBody2D  # referência ao player pai

func _ready() -> void:
	_player = get_parent() as CharacterBody2D
	if _player == null:
		push_error("AbsorbComponent precisa ser filho de um CharacterBody2D. Pai atual: " + get_parent().get_class())

func absorb(data: AbsorbResource) -> void:
	if _active:
		revert()           # cancela forma anterior se ainda ativa
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
	
	_player.dash_cd_override = -1.0
	_player.dash_distance_multiplier = 1.0
	
	_restore_defaults()
	emit_signal("form_expired")

func _process(delta: float) -> void:
	if not _active:
		return
	_timer -= delta
	if _timer <= 0.0:
		revert()
	if _active and int(_timer) != int(_timer + delta):  # imprime só uma vez por segundo
		print("Tempo restante: ", int(_timer), "s")

func _apply_visuals() -> void:
	var sprite = _player.get_node("AnimatedSprite2D")
	sprite.sprite_frames = current_data.sprite_frames
	print("Sprite alterado para: ", current_data.form_name)

func _apply_stats() -> void:
	_player.speed = current_data.speed
	_player.active_abilities = current_data.abilities.duplicate()
	
	if current_data.dash_cooldown_override >= 0.0:
		_player.dash_cd_override = current_data.dash_cooldown_override
	if current_data.dash_distance_multiplier != 1.0:
		_player.dash_distance_multiplier = current_data.dash_distance_multiplier
		
	print("Velocidade agora: ", _player.speed)
	print("Habilidades: ", _player.active_abilities)

func _restore_defaults() -> void:
	_player.speed = _player.base_speed
	_player.active_abilities.clear()
	# restaura sprite padrão
	_player.get_node("AnimatedSprite2D").sprite_frames = _player.default_frames

func get_time_remaining() -> float:
	return max(_timer, 0.0)
