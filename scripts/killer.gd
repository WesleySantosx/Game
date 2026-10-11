extends CharacterBody3D

@export var base_speed: float = 2.8
@export var facing_offset: float = PI
@export var detection_range: float = 40.0
@export var path_update_interval: float = 0.25
@export var turn_speed: float = 8.0

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var damage_area: Area3D = $DamageArea

var player: Node3D = null
var gravity: float = 9.8
var chasing: bool = false
var path_update_time: float = 0.0
var stun_remaining: float = 0.0
var speed: float = 2.8
var footstep_time: float = 0.0
var walk_phase: float = 0.0
var footsteps: AudioStreamPlayer3D


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player") as Node3D
	speed = base_speed
	footsteps = AudioStreamPlayer3D.new()
	add_child(footsteps)
	footsteps.stream = load("res://assets/audio/step.wav")
	footsteps.max_distance = 14.0
	footsteps.volume_db = -7.0


func set_anger(balls: int) -> void:
	speed = base_speed + float(balls) * 0.3
	if has_node("AngerLight"):
		$AngerLight.light_energy = float(balls) * 0.12


func stun(seconds: float) -> void:
	stun_remaining = maxf(stun_remaining, seconds)
	velocity.x = 0.0
	velocity.z = 0.0
	path_update_time = 0.0


func _physics_process(delta: float) -> void:
	stun_remaining = maxf(stun_remaining - delta, 0.0)
	velocity.x = 0.0
	velocity.z = 0.0
	# Espere o mapa de navegação sincronizar antes de pedir o primeiro caminho.
	var map := navigation_agent.get_navigation_map()
	if stun_remaining <= 0.0 and is_instance_valid(player) and NavigationServer3D.map_get_iteration_id(map) > 0:
		if global_position.distance_to(player.global_position) <= detection_range:
			chasing = true
		# Depois de encontrar o jogador, não abandona a caçada por distância.
		if chasing:
			path_update_time -= delta
			if path_update_time <= 0.0:
				navigation_agent.target_position = player.global_position
				path_update_time = path_update_interval
			var next_position := navigation_agent.get_next_path_position()
			if not navigation_agent.is_navigation_finished():
				var direction := next_position - global_position
				direction.y = 0.0
				direction = direction.normalized()
				velocity.x = direction.x * speed
				velocity.z = direction.z * speed
				if direction.length_squared() > 0.01:
					rotation.y = lerp_angle(
						rotation.y,
						atan2(-direction.x, -direction.z) + facing_offset,
						minf(turn_speed * delta, 1.0)
					)

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	move_and_slide()
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	if horizontal_speed > 0.2:
		walk_phase += delta * horizontal_speed * 3.0
		$Visual.position.y = absf(sin(walk_phase)) * 0.035
		footstep_time -= delta
		if footstep_time <= 0:
			footsteps.pitch_scale = randf_range(0.75, 0.95)
			footsteps.play()
			footstep_time = 1.5 / horizontal_speed
	else:
		$Visual.position.y = 0.0
	# A área detecta contato mesmo se o jogador estiver empurrando o Josias.
	if stun_remaining <= 0.0:
		_try_capture()


func _try_capture() -> void:
	for body in damage_area.get_overlapping_bodies():
		if body.is_in_group("player") and body.has_method("tomar_dano"):
			if body.tomar_dano():
				stun(1.2)
			break
