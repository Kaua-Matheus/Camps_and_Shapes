extends GolemBossState

func enter() -> void:
	super.enter()
	boss.set_physics_process(false)

	if animation_player != null and animation_player.has_animation("death"):
		animation_player.play("death")
		await animation_player.animation_finished

	if animation_player != null and animation_player.has_animation("boss_slained"):
		animation_player.play("boss_slained")
	else:
		boss.finish_death()
