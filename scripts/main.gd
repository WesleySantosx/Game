extends Node3D

const BALL_SCENE = preload("res://scenes/ball.tscn")
const TOTAL_BALLS: int = 7

var balls_collected: int = 0


func _ready() -> void:
	spawn_balls()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_R:
		get_tree().reload_current_scene()


func spawn_balls() -> void:
	# Pega os marcadores que você colocou no mapa.
	var points: Array[Marker3D] = []

	for child in $BallSpawns.get_children():
		if child is Marker3D:
			points.append(child)

	# Precisamos de pelo menos um ponto para cada bola.
	if points.size() < TOTAL_BALLS:
		push_error("Coloque pelo menos 7 Marker3D dentro de BallSpawns.")
		return

	# Embaralha os pontos para variar a cada partida.
	points.shuffle()

	for i in range(TOTAL_BALLS):
		# Cria uma cópia da cena da bola.
		var ball = BALL_SCENE.instantiate()

		# Conecta a coleta dessa bola ao contador.
		ball.collected.connect(_on_ball_collected)

		# Coloca a bola na cena e na posição do marcador.
		add_child(ball)
		ball.global_position = points[i].global_position


func _on_ball_collected() -> void:
	balls_collected += 1
	$HUD/Counter.text = "Bolas: %d / %d" % [
		balls_collected, TOTAL_BALLS
	]

	if balls_collected == TOTAL_BALLS:
		$HUD/Message.text = "Pegou todas as bolas!"
	else:
		$HUD/Message.text = "Boa! Continua procurando."
