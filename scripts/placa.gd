extends Node2D

@onready var label = $Label

func _ready():
	label.visible = false

func _on_area_2d_body_entered(body):
	label.visible = true

func _on_area_2d_body_exited(body):
	label.visible = false
