extends CharacterBody2D

@onready var animation: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $HitBox

# Raycast
@onready var wall_detector: RayCast2D = $WallDetector
@onready var ground_detector: RayCast2D = $GroundDetector
@onready var player_detector: RayCast2D = $PlayerDetector

# Bone
const ROCK = preload("uid://b6tgl8mkre3l2")
@onready var bone_start_position: Node2D = $BoneStartPosition

enum SkeletonState {
	idle,
	walk,
	attack,
	dead
}

const SPEED = 20.0
const JUMP_VELOCITY = -250.0

var status: SkeletonState

var direction = 1
var can_throw = true

func _ready() -> void:
	go_to_idle_state()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	match status:
		SkeletonState.idle:
			idle_state(delta)
		#SkeletonState.walk:
			#walk_state(delta)
		#SkeletonState.attack:
			#attack_state(delta)
		#SkeletonState.dead:
			#dead_state(delta)

	move_and_slide()
	
	
func go_to_idle_state():
	status = SkeletonState.idle
	animation.play("idle")
	
#func go_to_walk_state():
	#status = SkeletonState.walk
	#animation.play("walk")
	#
#func go_to_attack_state():
	#status = SkeletonState.attack
	#animation.play("attack")
	#velocity = Vector2.ZERO
	#can_throw = true
	#
#func go_to_dead_state():
	#status = SkeletonState.dead
	#animation.play("dead")
	#velocity = Vector2.ZERO
	#hitbox.process_mode = Node.PROCESS_MODE_DISABLED
	
	
func idle_state(_delta):
	pass
	
#func walk_state(_delta):
	#if animation.frame == 3 or animation.frame == 4:
		#velocity.x = SPEED * direction
	#else:
		#velocity.x = 0
	#
	#if wall_detector.is_colliding():
		#scale.x *= -1
		#direction *= -1
		#
	#if not ground_detector.is_colliding():
		#scale.x *= -1
		#direction *= -1
		#
	#if player_detector.is_colliding():
		#go_to_attack_state()
		#return
	#
#func dead_state(_delta):
	#pass
#
#func attack_state(_delta):
	#if animation.frame == 2 and can_throw:
		#throw_bone()
		#can_throw = false
#
#func take_damage():
	#go_to_dead_state()
#
#func throw_bone():
	#var new_bone = ROCK.instantiate()
	#add_sibling(new_bone)
	#new_bone.position = bone_start_position.global_position
	#new_bone.set_direction(self.direction)
#
#func _on_animated_sprite_2d_animation_finished() -> void:
	#if animation.animation == "attack":
		#go_to_walk_state()
		#return
