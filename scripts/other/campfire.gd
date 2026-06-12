class_name Campfire
extends Node2D

const FPS := 8.0
const FRAME_COUNT := 5

@onready var sprite: Sprite2D = $Sprite2D
@onready var warm_zone: Area2D = $WarmZone

var _frame_timer: float = 0.0

func _ready() -> void:
	warm_zone.body_entered.connect(_on_body_entered)
	warm_zone.body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	_frame_timer += delta
	if _frame_timer >= 1.0 / FPS:
		_frame_timer -= 1.0 / FPS
		sprite.frame = (sprite.frame + 1) % FRAME_COUNT

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.enter_campfire_range()

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		body.exit_campfire_range()
