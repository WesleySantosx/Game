extends CharacterBody3D

@export var speed: float = 4.0
@export var detection_range: float = 40.0
@export var path_update_interval: float = 0.25
@export var turn_speed: float = 8.0

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D

var player: Node3D = null
var gravity: float = 9.8
var chasing: bool = false
var path_update_time: float = 0.0


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player") as Node3D


func _physics_process(delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	# Espere o mapa de navegação sincronizar antes de pedir o primeiro caminho.
	var map := navigation_agent.get_navigation_map()
	if is_instance_valid(player) and NavigationServer3D.map_get_iteration_id(map) > 0:
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
					rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), minf(turn_speed * delta, 1.0))

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	move_and_slide()
