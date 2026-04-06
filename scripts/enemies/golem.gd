extends CharacterBody2D

@onready var animation: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $HitBox

# Raycast
@onready var wall_detector: RayCast2D = $WallDetector
@onready var ground_detector: RayCast2D = $GroundDetector
@onready var player_detector: RayCast2D = $PlayerDetector

# Bone
const ROCK = preload("uid://b6tgl8mkre3l2")
@onready var rock_start_position: Node2D = $RockStartPosition

enum GolemState {
	idle,
	walk,
	attack,
	#dead
}

const SPEED = 20.0
const JUMP_VELOCITY = -250.0

var status: GolemState

var direction = 1
var can_throw = true

func _ready() -> void:
	go_to_walk_state()

func _physics_process(delta: float) -> void:
	#if not is_on_floor():
		#velocity += get_gravity() * delta
		
	match status:
		GolemState.idle:
			idle_state(delta)
		GolemState.walk:
			walk_state(delta)
		#GolemState.attack:
			#attack_state(delta)
		#GolemState.dead:
			#dead_state(delta)

	move_and_slide()
	
	
func go_to_idle_state():
	status = GolemState.idle
	animation.play("idle")
	
func go_to_walk_state():
	status = GolemState.walk
	animation.play("walk")
	
func go_to_attack_state():
	status = GolemState.attack
	#animation.play("attack")
	velocity = Vector2.ZERO
	can_throw = true
	
#func go_to_dead_state():
	#status = GolemState.dead
	#animation.play("dead")
	#velocity = Vector2.ZERO
	#hitbox.process_mode = Node.PROCESS_MODE_DISABLED
	
	
func idle_state(_delta):
	pass
	
func walk_state(_delta):
	velocity.x = SPEED * direction
	
	if wall_detector.is_colliding():
		scale.x *= -1
		direction *= -1
		
	#if not ground_detector.is_colliding():
		#scale.x *= -1
		#direction *= -1
		
	if player_detector.is_colliding():
		go_to_attack_state()
		return
	
#func dead_state(_delta):
	#pass
#
func attack_state(_delta):
	throw_rock()
	can_throw = false
#
#func take_damage():
	#go_to_dead_state()
#
func throw_rock():
	var new_rock = ROCK.instantiate()
	add_sibling(new_rock)
	new_rock.position = rock_start_position.global_position
	new_rock.set_direction(self.direction)
#
#func _on_animated_sprite_2d_animation_finished() -> void:
	#if animation.animation == "attack":
		#go_to_walk_state()
		#return
