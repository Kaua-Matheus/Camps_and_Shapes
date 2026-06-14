extends GolemBossState

func enter() -> void:
	super.enter()
	if animation_player != null:
		animation_player.play("idle")

func transition() -> void:
	var distance := boss.direction.length()

	if distance < boss.melee_range:
		get_parent().change_state("MeleeAttack")
	elif distance > 130.0:
		get_parent().change_state("LaserBeam")

#extends GolemBossState
#
#func enter() -> void:
	#super.enter()
	#boss.set_physics_process(true)
	#if animation_player != null:
		#animation_player.play("idle")
#
#func exit() -> void:
	#super.exit()
	#boss.set_physics_process(false)
#
#func transition() -> void:
	#var distance := boss.direction.length()
#
	#if distance < boss.melee_range:
		#get_parent().change_state("MeleeAttack")
	#elif distance > 130.0:
		#get_parent().change_state("LaserBeam")
		
