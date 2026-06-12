class_name Campfire
extends Node2D

const CAMPFIRE_SHEET := preload("res://exterior tilesets/Campfire_Sheet.png")
const FRAME_COUNT := 7
const FPS := 8.0

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var warm_zone: Area2D = $WarmZone

func _ready() -> void:
	_setup_animation()
	warm_zone.body_entered.connect(_on_body_entered)
	warm_zone.body_exited.connect(_on_body_exited)
	anim_sprite.play("burn")

func _setup_animation() -> void:
	var frames := SpriteFrames.new()
	frames.add_animation("burn")
	frames.set_animation_loop("burn", true)
	frames.set_animation_speed("burn", FPS)

	var frame_w: int = CAMPFIRE_SHEET.get_width() / FRAME_COUNT
	var frame_h: int = CAMPFIRE_SHEET.get_height()

	for i in FRAME_COUNT:
		var atlas := AtlasTexture.new()
		atlas.atlas = CAMPFIRE_SHEET
		atlas.region = Rect2(i * frame_w, 0, frame_w, frame_h)
		frames.add_frame("burn", atlas)

	anim_sprite.sprite_frames = frames

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.enter_campfire_range()

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		body.exit_campfire_range()
