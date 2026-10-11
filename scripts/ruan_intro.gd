extends CanvasLayer

@export var duration: float = 2.5
var animation: Tween

func _ready() -> void:
	$Image.hide()

func play_intro() -> void:
	if animation and animation.is_running():
		animation.kill()
	$Image.show()
	$Image.modulate.a = 0.0
	animation = create_tween()
	animation.tween_property($Image, "modulate:a", 1.0, 0.12)
	animation.tween_interval(maxf(0.0, duration - 0.5))
	animation.tween_property($Image, "modulate:a", 0.0, 0.38)
	animation.tween_callback($Image.hide)
