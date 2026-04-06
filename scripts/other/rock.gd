extends Area2D

@onready var animation: AnimatedSprite2D = $AnimatedSprite2D

var speed = 110
var direction: int


func _process(delta: float) -> void:
	position.x += speed * delta * direction


func set_direction(skeleton_direction):
	self.direction = skeleton_direction
	animation.flip_h = skeleton_direction < 0


# Bone Exclusion by Time
func _on_self_destruct_timer_timeout() -> void:
	queue_free()


# Bone Exclusion by Collision Player
func _on_area_entered(_area: Area2D) -> void:
	queue_free()
	
	
# Bone Exclusion by Collision Wall
func _on_body_entered(_body: Node2D) -> void:
	queue_free()
