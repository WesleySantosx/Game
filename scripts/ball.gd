extends Area3D

signal collected(ball: Area3D)

var taken: bool = false
var elapsed: float = 0.0
var spawn_index: int = -1

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	elapsed += delta
	$Mesh.position.y = sin(elapsed * 2.0) * 0.08
	$Mesh.rotate_y(delta)

func _on_body_entered(body: Node3D) -> void:
	if taken or not body.is_in_group("player") or body.carried:
		return
	taken = true
	collected.emit(self)
	queue_free()
