extends GolemBossState

var can_transition: bool = false

func enter() -> void:
	super.enter()
	can_transition = false

	if animation_player != null:
		animation_player.play("armor_buff")
		await animation_player.animation_finished

	can_transition = true

func transition() -> void:
	if can_transition:
		can_transition = false
		get_parent().change_state("Follow")
