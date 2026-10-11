extends SceneTree

const GAME = preload("res://scenes/main.tscn")

func _initialize() -> void:
	call_deferred("run")


func check(value: bool, explanation: String) -> void:
	if not value:
		push_error("FAIL: " + explanation)
		quit(1)
		assert(value, explanation)


func fresh(start: bool = true) -> Node:
	paused = false
	if current_scene:
		var previous := current_scene
		current_scene = null
		previous.free()
	var main := GAME.instantiate()
	get_root().add_child(main)
	current_scene = main
	if start:
		main.start_game()
	return main


func collect_one(main: Node) -> void:
	check(main.spawned_balls.size() > 0, "Nao ha bola para coletar")
	main.spawned_balls[0]._on_body_entered(main.player)


func run() -> void:
	var main := fresh(false)
	var original_time: float = main.time_left
	for frame in 30:
		await physics_frame
	check(main.state == main.State.MENU and main.time_left == original_time, "Menu iniciou o relogio")
	check(not main.player.is_physics_processing() and not main.josias.is_physics_processing(), "Inimigos ativos no menu")
	main.hud.show_instructions()
	main.hud.show_menu()
	main.hud.start_requested.emit()
	check(main.state == main.State.PLAYING and main.spawned_balls.size() == 7, "Botao Jogar nao iniciou")
	for frame in 5:
		await physics_frame
	var map: RID = main.get_world_3d().navigation_map
	for marker in main.get_node("BallSpawns").get_children():
		var path := NavigationServer3D.map_get_path(map, main.player.global_position, marker.global_position, true)
		check(path.size() > 1 and path[path.size() - 1].distance_to(marker.global_position) < 0.8, "Marcador inacessivel: " + marker.name)
	var rescue_path := NavigationServer3D.map_get_path(map, main.player.global_position, Vector3(2, 0.5, 14.8), true)
	check(rescue_path.size() > 1 and rescue_path[rescue_path.size() - 1].distance_to(Vector3(2, 0.5, 14.8)) < 0.8, "Cela inacessivel")
	print("PASS: menu, inicio, todos os pontos de bola e acesso a cela.")
	main.josias.set_physics_process(false)
	var initial_speed: float = main.josias.speed
	for i in 5:
		collect_one(main)
	check(not main.ruan_spawned and main.josias.speed > initial_speed, "Raiva ou entrada antecipada do Ruan")
	collect_one(main)
	check(main.ruan_spawned and is_instance_valid(main.ruan), "Ruan nao entrou na sexta bola")
	main.ruan.set_physics_process(false)
	collect_one(main)
	check(main.balls_collected == 7 and not main.game_over and main.serjo.unlocked, "Setima bola encerrou sem resgatar")
	for frame in 3:
		await physics_frame
	main.player.global_position = Vector3(0, 0.05, 5)
	main.player.invulneravel = false
	main.player.tempo_invulneravel = 0
	main.ruan.global_position = Vector3(0.7, 0, 5)
	main.ruan.speed = 0
	main.ruan.stun_remaining = 0
	main.ruan.set_physics_process(true)
	for frame in 20:
		await physics_frame
		if main.balls_collected == 5:
			break
	check(main.balls_collected == 5 and main.player.vidas == 3, "Ruan nao roubou exatamente 2 bolas sem dano")
	check(main.josias.stun_remaining > 3 and main.player.invulneravel, "Ruan nao atordoou o Josias ou protegeu o jogador")
	check(main.player.global_position.distance_to(main.josias.global_position) <= 3.2, "Ruan nao levou o jogador para perto do Josias")
	for frame in 3:
		await physics_frame
	check(main.spawned_balls.size() == 2, "Bolas perdidas pelo Ruan nao voltaram")
	main.ruan.set_physics_process(false)
	main.ruan.global_position = Vector3(13.4, 0, -6.7)
	print("PASS: raiva, sexta bola, Ruan por contato, roubo, teleporte e atordoamento.")
	main.player.global_position = Vector3(0, 0.05, 5)
	main.player.velocity = Vector3.ZERO
	main.player.invulneravel = false
	main.player.tempo_invulneravel = 0
	main.josias.global_position = Vector3(0.7, 0, 5)
	main.josias.stun_remaining = 0
	main.josias.set_physics_process(true)
	for frame in 30:
		await physics_frame
		if main.player.vidas == 2:
			break
	check(main.player.vidas == 2 and main.balls_collected == 0, "Josias nao causou dano e zerou as bolas: vidas=%s player=%s josias=%s" % [main.player.vidas, main.player.global_position, main.josias.global_position])
	check(not main.player.tomar_dano(), "Invulnerabilidade permitiu dano repetido")
	for frame in 30:
		await physics_frame
	check(main.spawned_balls.size() == 7 and main.player.vidas == 2, "Redistribuicao ou protecao incorreta")
	var before_pause: float = main.time_left
	var immunity: float = main.player.tempo_invulneravel
	var enemy_position: Vector3 = main.josias.global_position
	main.pause_game()
	for frame in 60:
		await physics_frame
	check(main.time_left == before_pause and main.player.tempo_invulneravel == immunity, "Pausa nao congelou os tempos")
	check(main.josias.global_position == enemy_position, "Josias andou durante a pausa")
	main.resume_game()
	for frame in 600:
		await physics_frame
		if main.state == main.State.ENDED:
			break
	check(main.player.vidas == 0 and main.state == main.State.ENDED, "Terceira captura nao terminou")
	check(main.has_node("BasketEnding"), "Cinematica da cesta ausente")
	check(not main.player.controls_enabled and not main.josias.is_physics_processing(), "Controles ativos depois da derrota")
	check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "Mouse preso na derrota")
	print("PASS: dano, protecao, sete bolas redistribuidas, pausa e derrota com cesta.")
	main.restart_game()
	await process_frame
	await process_frame
	main = current_scene
	check(main.state == main.State.PLAYING and main.player.vidas == 3 and main.balls_collected == 0, "Reinicio incorreto")
	main.return_to_menu()
	await process_frame
	await process_frame
	check(current_scene.state == current_scene.State.MENU, "Volta ao menu falhou")
	print("PASS: reinicio e volta ao menu.")
	main = fresh()
	main.josias.set_physics_process(false)
	for i in 7:
		collect_one(main)
	main.ruan.set_physics_process(false)
	main.player.global_position = Vector3(2, 0.05, 14.8)
	for frame in 3:
		await physics_frame
	check(main._can_reach_cage(), "Interacao com a cela bloqueada")
	var interact := InputEventKey.new()
	interact.physical_keycode = KEY_E
	interact.pressed = true
	main._unhandled_input(interact)
	for frame in 100:
		await physics_frame
	check(main.serjo.freed and main.state == main.State.ENDED, "Resgate com E nao venceu")
	check(not main.player.controls_enabled, "Jogador ativo depois da vitoria")
	print("PASS: sete bolas, interacao E, porta abre, Serjo sai e vitoria.")
	main = fresh(false)
	main.round_seconds = 0.1
	main.time_left = 0.1
	main.start_game()
	for frame in 20:
		await physics_frame
	check(main.state == main.State.ENDED and main.time_left == 0, "Tempo limite nao encerrou a partida")
	check(not main.serjo.prisoner.visible, "Final de tempo nao atualizou o Serjo")
	print("PASS: final por tempo limite.")
	main = fresh()
	# Confirma a perseguição real atravessando os corredores, sem teleporte do inimigo.
	for frame in 2400:
		await physics_frame
		if main.player.vidas < 3:
			break
	check(main.player.vidas == 2, "Perseguicao desde o ponto inicial nao alcancou o jogador")
	print("PASS: Josias percorre o labirinto e captura o jogador.")
	print("TODOS OS TESTES PASSARAM.")
	current_scene.free()
	current_scene = null
	await process_frame
	await process_frame
	# O áudio roda em uma thread de tempo real, mesmo com --fixed-fps.
	OS.delay_msec(100)
	quit(0)
