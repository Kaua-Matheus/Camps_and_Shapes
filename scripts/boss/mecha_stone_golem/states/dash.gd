extends GolemBossState

var can_transition: bool = false

func enter() -> void:
	super.enter()
	can_transition = false
	boss.reset_dash_hit()

	if animation_player != null:
		animation_player.play("glowing")

	await dash()
	can_transition = true

func dash() -> void:
	if not is_instance_valid(player):
		return

	var tween := create_tween()
	tween.tween_property(boss, "global_position", player.global_position, 0.8)
	while tween.is_running():
		boss.try_dash_hit()
		await get_tree().physics_frame

	boss.try_dash_hit()

func transition() -> void:
	if can_transition:
		can_transition = false
		get_parent().change_state("Follow")
