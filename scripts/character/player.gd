extends CharacterBody2D

@export var speed: int = 300

func _physics_process(_delta: float) -> void:
	move()
	
func move() -> void:
	var direction_vector: Vector2 = Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	).normalized()
	
	velocity = direction_vector * speed
	move_and_slide()
