extends Node2D

# no spawner ou no _ready do mapa
func _ready() -> void:
	for enemy in get_tree().get_nodes_in_group("Enemy"):
		print("Inimigo encontrado: ", enemy.enemy_type)
		enemy.died.connect(FormUnlockManager.register_kill)
