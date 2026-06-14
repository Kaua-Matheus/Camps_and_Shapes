extends GolemBossState

var _hit_done: bool = false

func enter() -> void:
	super.enter()
	_hit_done = false
	if animation_player != null:
		animation_player.play("melee_attack")

func transition() -> void:
	if animation_player != null and animation_player.current_animation == "melee_attack":
		var t := animation_player.current_animation_position
		if t >= 0.75 and not _hit_done:
			boss.try_melee_hit()
			_hit_done = true
		elif t < 0.75:
			_hit_done = false

	if boss.direction.length() > boss.melee_range:
		get_parent().change_state("Follow")
