extends "res://scripts/killer.gd"

signal captured


func _try_capture() -> void:
	if not is_instance_valid(player) or player.invulneravel:
		return
	for body in damage_area.get_overlapping_bodies():
		if body == player:
			# Dá tempo para o jogador fugir antes de outra captura do Ruan.
			stun(8.0)
			captured.emit()
			break
