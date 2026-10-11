extends "res://scripts/killer.gd"

signal captured
var carrying: bool = false
var delivery_target: Node3D

func chase_target() -> Vector3:
	if carrying and is_instance_valid(delivery_target):
		return delivery_target.global_position
	return super.chase_target()


func _try_capture() -> void:
	if carrying or not is_instance_valid(player) or player.invulneravel or player.carried:
		return
	for body in damage_area.get_overlapping_bodies():
		if body == player:
			# Dá tempo para o jogador fugir antes de outra captura do Ruan.
			stun(0.0)
			captured.emit()
			break
