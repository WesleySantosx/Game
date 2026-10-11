extends Node3D

const BALL_SCENE = preload("res://scenes/ball.tscn")
const TOTAL_BALLS: int = 7
const RUAN_SCENE = preload("res://scenes/ruan.tscn")
const RUAN_INTRO_SCENE = preload("res://scenes/ruan_intro.tscn")

var balls_collected: int = 0
var ruan_spawned: bool = false


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
	elif balls_collected == 6:
		spawn_ruan()
		$HUD/Message.text = "O Ruan apareceu! Falta uma bola."
	else:
		$HUD/Message.text = "Boa! Continua procurando."


func spawn_ruan() -> void:
	if ruan_spawned:
		return
	ruan_spawned = true
	# Usa um ponto livre do mapa, longe do jogador.
	var spawn_point: Marker3D = $BallSpawns.get_child(0)
	for point in $BallSpawns.get_children():
		if point is Marker3D and point.global_position.distance_squared_to($Player.global_position) > spawn_point.global_position.distance_squared_to($Player.global_position):
			spawn_point = point
	var ruan = RUAN_SCENE.instantiate()
	ruan.name = "Ruan"
	add_child(ruan)
	ruan.global_position = Vector3(spawn_point.global_position.x, 0.0, spawn_point.global_position.z)
	var target = Vector3($Player.global_position.x, 0.0, $Player.global_position.z)
	if ruan.global_position.distance_to(target) > 0.1:
		ruan.look_at(target, Vector3.UP)
	var intro = RUAN_INTRO_SCENE.instantiate()
	add_child(intro)
	intro.play_intro()
