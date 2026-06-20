extends CanvasLayer

# Player Target
var target: Node2D

# Health Bar
@onready var health_bar: ProgressBar = $HealthBar

# Skills
var _skill_overlays: Array = []
var _skill_labels: Array = []

# Heal
var _heal_lock_overlay: ColorRect = null
var _heal_lock_label: Label = null
var heal_unlocked: bool = false


func _ready() -> void:
	target = get_target()
	if target != null:
		health_bar.max_value = target.max_hp
		health_bar.value = target.health
	else:
		pass


func _process(_delta: float) -> void:
	target = get_target()
	if target != null:
		health_bar.value = target.health
	else:
		pass


func get_target():
	var nodes = get_tree().get_nodes_in_group("Player")
	if nodes.size() == 0:
		push_error("Player not found")
		return

	return nodes[0]


# Health
func _style_health_bar() -> void:
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.8, 0.1, 0.1)
	fill.set_corner_radius_all(3)
	health_bar.add_theme_stylebox_override("fill", fill)

	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.15, 0.15, 0.15, 0.85)
	bg.set_corner_radius_all(3)
	health_bar.add_theme_stylebox_override("background", bg)


# Skills
func _setup_skill_hud() -> void:
	var hud: CanvasLayer = $HUD
	var colors := [Color(0.2, 0.5, 1.0, 0.9), Color(0.2, 0.78, 0.3, 0.9), Color(0.9, 0.3, 0.2, 0.9)]
	var ready_texts := ["DASH", "HEAL", "DMG+"]
	var key_hints := ["RMB", "[ 1 ]", "[ 2 ]"]
	var icon_size := 40
	var gap := 4
	var start_x := 8
	var start_y := 28

	for i in range(3):
		var x := start_x + i * (icon_size + gap)

		var bg := ColorRect.new()
		bg.position = Vector2(x, start_y)
		bg.size = Vector2(icon_size, icon_size)
		bg.color = colors[i]
		hud.add_child(bg)

		var overlay := ColorRect.new()
		overlay.position = Vector2(x, start_y)
		overlay.size = Vector2(icon_size, 0.0)
		overlay.color = Color(0.0, 0.0, 0.0, 0.78)
		hud.add_child(overlay)
		_skill_overlays.append(overlay)

		var hint := Label.new()
		hint.position = Vector2(x, start_y + icon_size - 12)
		hint.size = Vector2(icon_size, 12)
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
		hint.add_theme_font_size_override("font_size", 7)
		hint.text = key_hints[i]
		hud.add_child(hint)

		var lbl := Label.new()
		lbl.position = Vector2(x, start_y)
		lbl.size = Vector2(icon_size, icon_size - 12)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_color_override("font_color", Color.WHITE)
		lbl.add_theme_font_size_override("font_size", 9)
		lbl.text = ready_texts[i]
		hud.add_child(lbl)
		_skill_labels.append(lbl)

		if i == 1:
			var lock_bg := ColorRect.new()
			lock_bg.position = Vector2(x, start_y)
			lock_bg.size = Vector2(icon_size, icon_size)
			lock_bg.color = Color(0.0, 0.0, 0.0, 0.78)
			hud.add_child(lock_bg)
			_heal_lock_overlay = lock_bg

			var lock_lbl := Label.new()
			lock_lbl.position = Vector2(x, start_y)
			lock_lbl.size = Vector2(icon_size, icon_size)
			lock_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lock_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			lock_lbl.add_theme_color_override("font_color", Color.WHITE)
			lock_lbl.add_theme_font_size_override("font_size", 9)
			lock_lbl.text = "LOCK"
			hud.add_child(lock_lbl)
			_heal_lock_label = lock_lbl


func unlock_heal() -> void:
	heal_unlocked = true
	if is_instance_valid(_heal_lock_overlay):
		_heal_lock_overlay.visible = false
	if is_instance_valid(_heal_lock_label):
		_heal_lock_label.visible = false


func _update_skill_hud() -> void:
	if _skill_overlays.is_empty():
		return
	var timers := [target._dash_cd, target._heal_cd, target._damage_cd]
	var max_cds := [target.DASH_CD, target.HEAL_CD, target.DAMAGE_CD]
	var ready_texts := ["DASH", "HEAL", "DMG+"]
	var icon_size := 40.0

	for i in range(3):
		var t: float = timers[i]
		var overlay: ColorRect = _skill_overlays[i]
		var lbl: Label = _skill_labels[i]
		if t > 0.0:
			overlay.size.y = (t / max_cds[i]) * icon_size
			lbl.text = str(ceili(t))
		else:
			overlay.size.y = 0.0
			lbl.text = ready_texts[i]


func _handle_skills(delta: float) -> void:
	target._dash_cd = max(target._dash_cd - delta, 0.0)
	target._heal_cd = max(target._heal_cd - delta, 0.0)
	target._damage_cd = max(target._damage_cd - delta, 0.0)
	target._damage_boost_remaining = max(target._damage_boost_remaining - delta, 0.0)

	if target._damage_boosted and target._damage_boost_remaining <= 0.0:
		target._damage_boosted = false
		target.animation.modulate = Color.WHITE

	if Input.is_action_just_pressed("Skill_Heal") and target._heal_cd <= 0.0 and heal_unlocked:
		target._use_heal()

	if Input.is_action_just_pressed("Skill_Damage") and target._damage_cd <= 0.0:
		target._use_damage_boost()

	_update_skill_hud()
