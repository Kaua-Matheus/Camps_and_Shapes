extends GolemBossState

@onready var collision: CollisionShape2D = $"../../PlayerDetection/CollisionShape2D"
@onready var progress_bar: ProgressBar = owner.find_child("ProgressBar", true, false) as ProgressBar

var player_entered: bool = false:
	set(value):
		player_entered = value
		if collision != null:
			collision.set_deferred("disabled", value)
		if progress_bar != null:
			progress_bar.set_deferred("visible", value)

func enter() -> void:
	super.enter()
	if animation_player != null:
		animation_player.play("idle")

func transition() -> void:
	if not player_entered and is_instance_valid(player) and boss.direction.length() <= boss.aggro_range:
		player_entered = true

	if player_entered:
		get_parent().change_state("Follow")

func _on_player_detection_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_entered = true
