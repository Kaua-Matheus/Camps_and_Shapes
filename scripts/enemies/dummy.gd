extends CharacterBody2D


func _physics_process(_delta: float) -> void:
	pass


func _on_detection_area_body_entered(body: Node2D) -> void:
	print(body)
	print(body.get_groups())


func _on_detection_area_area_entered(area: Area2D) -> void:
	print(area)
	print(area.get_groups())
