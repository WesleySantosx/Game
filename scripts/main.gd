extends Node3D

var balls_collected: int = 0

func _ready() -> void:
	$Ball.collected.connect(_on_ball_collected)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_R:
		get_tree().reload_current_scene()

func _on_ball_collected() -> void:
	balls_collected += 1
	$HUD/Counter.text = "Bolas: %d / 7" % balls_collected
	$HUD/Message.text = "Boa! A coleta funciona. Aperte R para testar de novo."
