extends GolemBossState

@onready var pivot: Node2D = $"../../Pivot"

var can_transition: bool = false
var _laser_direction: Vector2 = Vector2.RIGHT
var _laser_hit_done: bool = false

func enter() -> void:
	super.enter()
	can_transition = false
	_laser_hit_done = false
	set_target()
	await play_animation("laser_cast")
	set_target()
	await play_laser_damage_window()
	can_transition = true

func play_animation(anim_name: StringName) -> void:
	if animation_player == null or not animation_player.has_animation(anim_name):
		return

	animation_player.play(anim_name)
	await animation_player.animation_finished

func set_target() -> void:
	if pivot == null or not is_instance_valid(player):
		return

	_laser_direction = (player.global_position - pivot.global_position).normalized()
	pivot.global_rotation = _laser_direction.angle()

func play_laser_damage_window() -> void:
	if animation_player == null or not animation_player.has_animation("laser"):
		return

	animation_player.play("laser")
	var elapsed := 0.0
	while animation_player.is_playing() and animation_player.current_animation == "laser":
		var t := animation_player.current_animation_position
		if t >= 1.08 and t <= 1.66:
			elapsed += get_physics_process_delta_time()
			if elapsed >= 0.18:
				elapsed = 0.0
				_apply_laser_damage()
		await get_tree().physics_frame

func _apply_laser_damage() -> void:
	if pivot == null:
		return
	if _laser_hit_done:
		return

	_laser_hit_done = boss.try_laser_hit(pivot.global_position, _laser_direction)

func transition() -> void:
	if can_transition:
		can_transition = false
		get_parent().change_state("Dash")
