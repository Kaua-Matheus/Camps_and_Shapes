# Wolf
extends Enemy

var player_ref: Node2D = null

@export var speed: int = 100
@export var melee_range: float = 40.0

@export var damage_on_player: float = 20.0

var distance: Vector2
var direction: Vector2
var distance_length: float

var damage_cooldown: float = 1.5
var damage_timer: float = 0.0

func _ready() -> void:	
	enter_idle_state()


func _physics_process(delta: float) -> void:
	damage_timer -= delta * damage_cooldown
	update_state(delta)
	move_and_slide()


# ── States: Tick ─────────────────────────────────────────────────────
func idle_state(_delta):
	if is_instance_valid(player_ref):
		enter_walk_state()
		return
	else:
		velocity = Vector2.ZERO
		enter_idle_state()
		return

func walk_state(_delta):
	distance = player_ref.global_position - global_position
	direction = distance.normalized()
	distance_length = distance.length()
	
	animation.flip_h = true if direction.x < 0 else false

	if distance_length <= melee_range:
		enter_attack_state()
		if damage_timer <= 0.0:
			player_ref.take_damage(damage_on_player)
			damage_timer = damage_cooldown
	
	else:
		velocity = speed * direction

func attack_state(_delta: float) -> void:
	if animation.animation == "attack" and not animation.is_playing():
		enter_walk_state()

func dead_state(_delta: float) -> void:
	if animation.animation == "death" and not animation.is_playing():
		die()


func update_state(delta: float):

	match current_state:
		EnemyState.idle: idle_state(delta)
		EnemyState.walk: walk_state(delta)
		EnemyState.attack: attack_state(delta)
		EnemyState.dead: dead_state(delta)


func player_body_entered(body: Node2D) -> void:
	print(body.get_groups())
	if body.is_in_group("Player"):
		player_ref = body


func player_body_exited(_body: Node2D) -> void:
	pass
