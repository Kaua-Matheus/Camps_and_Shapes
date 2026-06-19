extends Node2D

const GATE_HEIGHT: float = 384.0
const GATE_WIDTH: float = 32.0
const GATE_Y: float = GATE_HEIGHT * 0.5

const GATES := [
	{"id": "snow", "name": "SnowGate", "x": 2304.0},
	{"id": "lava", "name": "LavaGate", "x": 4608.0},
]

var _gate_shapes: Array[CollisionShape2D] = []

func _ready() -> void:
	for gate_data in GATES:
		_create_gate(gate_data)
	_sync_gates()

func _physics_process(_delta: float) -> void:
	_sync_gates()

func _create_gate(gate_data: Dictionary) -> void:
	var gate := StaticBody2D.new()
	gate.name = str(gate_data.get("name", "Gate"))
	gate.collision_layer = 1
	gate.collision_mask = 0
	gate.position = Vector2(float(gate_data.get("x", 0.0)), GATE_Y)
	gate.visible = false

	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(GATE_WIDTH, GATE_HEIGHT)
	shape.shape = box
	gate.add_child(shape)

	add_child(gate)
	_gate_shapes.append(shape)

func _sync_gates() -> void:
	for index in range(_gate_shapes.size()):
		var gate_data: Dictionary = GATES[index]
		var shape := _gate_shapes[index]
		if shape == null:
			continue
		shape.disabled = BossManager.is_gate_unlocked(str(gate_data.get("id", "")))