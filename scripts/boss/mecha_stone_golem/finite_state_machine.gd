extends Node2D

var current_state: GolemBossState
var previous_state: GolemBossState

func _ready() -> void:
	if get_child_count() == 0:
		return

	current_state = get_child(0) as GolemBossState
	previous_state = current_state

	if current_state != null:
		current_state.enter()

func change_state(state_name: StringName) -> void:
	var next_state := get_node_or_null(NodePath(String(state_name))) as GolemBossState
	if next_state == null:
		push_warning("Boss state not found: %s" % String(state_name))
		return
	if next_state == current_state:
		return

	previous_state = current_state
	if previous_state != null:
		previous_state.exit()

	current_state = next_state
	current_state.enter()
