extends Area3D

signal collected

var taken: bool = false
var elapsed: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	elapsed += delta
	$Mesh.position.y = sin(elapsed * 2.0) * 0.08
	$Mesh.rotate_y(delta)

func _on_body_entered(body: Node3D) -> void:
	if taken or not body.is_in_group("player"):
		return
	taken = true
	collected.emit()
	queue_free()
