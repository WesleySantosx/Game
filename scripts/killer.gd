
extends CharacterBody3D

@export var speed: float = 4.0
@export var detection_range: float = 15.0

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D

var player: Node3D = null
var gravity: float = 9.8


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player") as Node3D


func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return

	var distance_to_player = global_position.distance_to(
		player.global_position
	)

	if distance_to_player <= detection_range:
		navigation_agent.target_position = player.global_position

		if not navigation_agent.is_navigation_finished():
			var next_position = navigation_agent.get_next_path_position()
			var direction = next_position - global_position
			direction.y = 0.0
			direction = direction.normalized()

			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = 0.0
			velocity.z = 0.0
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	move_and_slide()
