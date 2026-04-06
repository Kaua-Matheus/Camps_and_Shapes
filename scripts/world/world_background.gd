extends Node2D

const WORLD_WIDTH: int = 3840
const WORLD_HEIGHT: int = 384
const TREE_ZONE_HEIGHT: int = 80

# Grass palette
const GRASS_BASE    := Color("#4d8a38")
const GRASS_LIGHT   := Color("#5ea348")
const GRASS_DARK    := Color("#3a6d28")
const GRASS_ACCENT  := Color("#a8c84a")

# Tree/forest palette
const FOREST_FLOOR     := Color("#1a3a0a")
const TREE_DARK        := Color("#254f12")
const TREE_MID         := Color("#2e6a18")
const TREE_LIGHT       := Color("#3d8a22")
const TREE_HIGHLIGHT   := Color("#52a830")


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	_draw_grass_plain()
	_draw_tree_zone(0)
	_draw_tree_zone(WORLD_HEIGHT - TREE_ZONE_HEIGHT)


func _draw_grass_plain() -> void:
	var play_y := TREE_ZONE_HEIGHT
	var play_h := WORLD_HEIGHT - TREE_ZONE_HEIGHT * 2

	draw_rect(Rect2(0, play_y, WORLD_WIDTH, play_h), GRASS_BASE)

	var rng := RandomNumberGenerator.new()
	rng.seed = 54321

	for _i in range(3500):
		var x := rng.randi_range(0, WORLD_WIDTH - 2)
		var y := rng.randi_range(play_y, play_y + play_h - 3)
		var roll := rng.randf()

		if roll < 0.35:
			# Grass blade (tall, lighter)
			draw_rect(Rect2(x, y, 2, 3), GRASS_LIGHT)
		elif roll < 0.55:
			# Grass blade (short, darker)
			draw_rect(Rect2(x, y, 1, 2), GRASS_DARK)
		elif roll < 0.62:
			# Small wildflower
			draw_rect(Rect2(x, y, 2, 2), GRASS_ACCENT)
			draw_rect(Rect2(x, y - 1, 1, 1), Color("#f0f040"))
		elif roll < 0.65:
			# Pebble
			draw_rect(Rect2(x, y, 3, 2), Color("#8a8a6a"))


func _draw_tree_zone(zone_y: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = zone_y * 7 + 11111

	# Dark forest floor
	draw_rect(Rect2(0, zone_y, WORLD_WIDTH, TREE_ZONE_HEIGHT), FOREST_FLOOR)

	# Ground texture (root patterns and dirt)
	for _i in range(600):
		var x := rng.randi_range(0, WORLD_WIDTH - 1)
		var y := rng.randi_range(zone_y, zone_y + TREE_ZONE_HEIGHT - 1)
		var w := rng.randi_range(4, 12)
		draw_rect(Rect2(x, y, w, 1), Color("#243510"))

	# Main row of trees — centered in zone
	var main_center := zone_y + TREE_ZONE_HEIGHT / 2
	var x := -35
	while x < WORLD_WIDTH + 35:
		var cx := x + rng.randi_range(-10, 10)
		var cy := main_center + rng.randi_range(-15, 15)
		var r  := rng.randi_range(24, 36)

		draw_circle(Vector2(cx + 4, cy + 5), r,        Color(0, 0, 0, 0.25)) # shadow
		draw_circle(Vector2(cx,     cy),     r,        TREE_DARK)
		draw_circle(Vector2(cx,     cy),     r * 0.78, TREE_MID)
		draw_circle(Vector2(cx - 3, cy - 3), r * 0.50, TREE_LIGHT)
		draw_circle(Vector2(cx - 5, cy - 5), r * 0.22, TREE_HIGHLIGHT)

		x += rng.randi_range(38, 56)

	# Secondary smaller trees to fill visual gaps
	rng.seed = zone_y * 3 + 22222
	var secondary_y := zone_y + (TREE_ZONE_HEIGHT / 4 if zone_y == 0 else TREE_ZONE_HEIGHT * 3 / 4)
	x = -20
	while x < WORLD_WIDTH + 20:
		var cx := x + rng.randi_range(-6, 6)
		var cy := secondary_y + rng.randi_range(-10, 10)
		var r  := rng.randi_range(14, 22)

		draw_circle(Vector2(cx + 3, cy + 3), r,        Color(0, 0, 0, 0.20))
		draw_circle(Vector2(cx,     cy),     r,        TREE_DARK)
		draw_circle(Vector2(cx,     cy),     r * 0.75, TREE_MID)
		draw_circle(Vector2(cx - 2, cy - 3), r * 0.45, TREE_LIGHT)

		x += rng.randi_range(28, 40)
