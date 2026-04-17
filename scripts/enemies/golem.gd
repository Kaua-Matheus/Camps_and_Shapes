extends CharacterBody2D

var player_ref = null

@onready var animation: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $HitBox

# Raycast
@onready var wall_detector: RayCast2D = $WallDetector
@onready var ground_detector: RayCast2D = $GroundDetector

# Bone
const ROCK = preload("uid://b6tgl8mkre3l2")
@onready var rock_start_position: Node2D = $RockStartPosition

enum GolemState {
	idle,
	walk,
	attack,
	#dead
}

const SPEED = 100
const MELEE_RANGE: float = 40.0

@export var damage_percent: float = 20.0
var damage_cooldown: float = 1.5
var damage_timer: float = 0.0

var status: GolemState

var can_throw = true

#func _ready() -> void:
	#go_to_walk_state()

func _physics_process(delta: float) -> void:
	damage_timer -= delta * damage_cooldown

	if player_ref != null:
		go_to_walk_state()
		var distance: Vector2 = player_ref.global_position - global_position
		var direction: Vector2 = distance.normalized()
		var distance_length: float = distance.length()

		if distance_length <= MELEE_RANGE:
			velocity = Vector2.ZERO
			if damage_timer <= 0.0:
				player_ref.take_damage_percent(damage_percent)
				damage_timer = damage_cooldown
		else:
			velocity = SPEED * direction

	else:
		velocity = Vector2.ZERO
		go_to_idle_state()

	#match status:
		#GolemState.idle:
			#idle_state(delta)
		#GolemState.walk:
			#walk_state(delta)
		#GolemState.attack:
			#attack_state(delta)
		##GolemState.dead:
			##dead_state(delta)

	move_and_slide()
	
	
func go_to_idle_state():
	status = GolemState.idle
	animation.play("idle")
	
func go_to_walk_state():
	status = GolemState.walk
	animation.play("walk")
	
#func go_to_attack_state():
	#status = GolemState.attack
	##animation.play("attack")
	#velocity = Vector2.ZERO
	#can_throw = true
	
#func go_to_dead_state():
	#status = GolemState.dead
	#animation.play("dead")
	#velocity = Vector2.ZERO
	#hitbox.process_mode = Node.PROCESS_MODE_DISABLED
	
	
func idle_state(_delta):
	pass
	
#func walk_state(_delta):
	#velocity.x = SPEED * direction
	#
	#if wall_detector.is_colliding():
		#scale.x *= -1
		#direction *= -1
		
	#if not ground_detector.is_colliding():
		#scale.x *= -1
		#direction *= -1
	
#func dead_state(_delta):
	#pass
#
#func attack_state(_delta):
	#throw_rock()
	#can_throw = false
#
#func take_damage():
	#go_to_dead_state()
#
#func throw_rock():
	#var new_rock = ROCK.instantiate()
	#add_sibling(new_rock)
	#new_rock.position = rock_start_position.global_position
	#new_rock.set_direction(self.direction)
#
#func _on_animated_sprite_2d_animation_finished() -> void:
	#if animation.animation == "attack":
		#go_to_walk_state()
		#return

func on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_ref = body

func on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_ref = null
