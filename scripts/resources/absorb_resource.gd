class_name AbsorbResource
extends Resource

@export var form_name: String = ""
@export var sprite_frames: SpriteFrames  # AnimatedSprite2D frames
@export var speed: float = 200.0
@export var duration: float = 10.0       # segundos antes de expirar
@export var abilities: Array[String] = [] # ex: ["dash", "wall_jump"]

@export var move_behavior: Script        # script que sobrescreve _physics_process

@export var dash_cooldown_override: float = -1.0  # -1 = usa o padrão do player
@export var dash_distance_multiplier: float = 1.0
