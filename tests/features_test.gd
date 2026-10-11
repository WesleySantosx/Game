extends SceneTree

const GAME = preload("res://scenes/main.tscn")

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, description: String) -> void:
	if not value:
		push_error("FAIL: " + description)
		quit(1)
		assert(value, description)

func fresh() -> Node:
	paused = false
	if current_scene:
		current_scene.free()
	var main := GAME.instantiate()
	root.add_child(main)
	current_scene = main
	main.start_game()
	main.josias.set_physics_process(false)
	return main

func collect(main: Node, count: int) -> void:
	for i in count:
		main.spawned_balls[0]._on_body_entered(main.player)
	if is_instance_valid(main.ruan):
		main.ruan.set_physics_process(false)

func pass_check(features: Node) -> void:
	features.start_check()
	features.skill_progress = features.skill_start + features.skill_width / 2.0
	check(features.handle_key(KEY_SPACE), "Espaco nao resolveu habilidade")

func run() -> void:
	check(InputMap.action_get_events("sprint")[0].physical_keycode == KEY_SHIFT, "Shift mal configurado")
	for count in [0, 1, 3, 5, 7]:
		var main := fresh()
		collect(main, count)
		main.player.invulneravel = false
		main.player.tempo_invulneravel = 0
		check(main.player.tomar_dano(), "Contato nao aceito")
		var lost: int = maxi(1, floori(float(count) / 2)) if count > 0 else 0
		check(main.balls_collected == count - lost, "Arredondamento primeira pancada: %d" % count)
		check(main.spawned_balls.size() + main.balls_collected == 7, "Conservacao das bolas")
		main.player.invulneravel = false
		main.player.tempo_invulneravel = 0
		main.player.tomar_dano()
		check(main.balls_collected == 0 and main.spawned_balls.size() == 7, "Segunda pancada nao tirou tudo")
	print("PASS: primeira pancada 0/1/3/5/7, arredondamento, segunda tira tudo e total de sete.")
	var main := fresh()
	var f: Node = main.features
	check(f.items.size() == 3, "Tres melhorias nao surgiram")
	var map: RID = main.get_world_3d().navigation_map
	for frame in 4:
		await physics_frame
	for item in f.items:
		var path := NavigationServer3D.map_get_path(map, main.player.global_position, item.global_position, true)
		check(path.size() > 1 and path[path.size() - 1].distance_to(item.global_position) < 1, "Melhoria inacessivel")
	check(f.equip_item(f.items[0]) and f.equip_item(f.items[0]), "Equipar primeira e segunda melhoria")
	check(not f.equip_item(f.items[0]), "Terceira melhoria ultrapassou limite")
	check(f.equip_item(f.items[0], 0), "Troca de slot falhou")
	check(main.player.upgrades.size() == 2 and f.items.size() == 1, "Troca apagou item ou criou slot extra")
	main.player.upgrades.assign(["shoes"])
	main.player.global_position = Vector3(0, 0.05, 5)
	main.player.rotation = Vector3.ZERO
	Input.action_press("move_forward")
	Input.action_press("sprint")
	for frame in 8:
		await physics_frame
	check(absf(Vector2(main.player.velocity.x, main.player.velocity.z).length() - 7.08) < 0.1, "Tenis nao aumentou a velocidade em 18%")
	Input.action_release("move_forward")
	Input.action_release("sprint")
	main.player.upgrades.assign(["lungs", "hand"])
	main.player.stamina = 0
	main.player.stamina_delay = 0
	for frame in 60:
		await physics_frame
	check(main.player.stamina > 32 and main.player.stamina < 36, "Pulmao nao regenera 34/s")
	main.player.upgrades.clear()
	main.player.stamina = 0
	for frame in 60:
		await physics_frame
	check(main.player.stamina > 19 and main.player.stamina < 22, "Stamina base nao regenera 20/s")
	main.player.stamina = 100
	Input.action_press("move_forward")
	Input.action_press("sprint")
	for frame in 320:
		await physics_frame
	Input.action_release("move_forward")
	Input.action_release("sprint")
	check(main.player.stamina < 26, "Sprint nao consome stamina ou ignora exaustao: stamina=%s mouse=%s" % [main.player.stamina, Input.mouse_mode])
	main.player.upgrades.assign(["hand"])
	f.reveal_ball()
	var ball: Node3D = f.revealed_ball
	check(is_instance_valid(ball) and f.hand_cooldown == 45 and f.reveal_time == 6, "Mao nao revelou bola")
	f.reveal_ball()
	check(f.revealed_ball == ball, "Mao ignorou recarga")
	main.pause_game()
	var cooldown: float = f.hand_cooldown
	for frame in 30:
		await physics_frame
	check(f.hand_cooldown == cooldown, "Recarga da mao corre na pausa")
	main.resume_game()
	print("PASS: melhorias acessiveis, dois slots, troca, stamina, pulmao, mao e pausa das recargas.")
	main = fresh()
	f = main.features
	collect(main, 6)
	main.player.global_position = Vector3(-4, 0.05, 7.2)
	for frame in 3:
		await physics_frame
	check(f.near_fat(), "Fat inacessivel")
	check(f.trade_life(), "Fat nao trocou cinco bolas")
	check(main.player.vidas == 4 and main.balls_collected == 1 and main.spawned_balls.size() == 6, "Troca perdeu bolas erradas ou nao deu vida")
	collect(main, 5)
	check(not f.trade_life() and main.player.vidas == 4, "Troca de vida repetida permitida")
	# Sementes fixas cobrem oferta e recusa sem teste probabilístico instável.
	var offer_seed: int = 0
	var refusal_seed: int = 0
	for number in range(1, 100):
		seed(number)
		if randf() <= f.FAT_CHANCE:
			offer_seed = number
		else:
			refusal_seed = number
	seed(refusal_seed)
	f.try_fat_gun()
	check(f.skill_context == "" and f.fat_attempts == 1, "Recusa de oferta incorreta")
	f.try_fat_gun()
	check(f.fat_attempts == 1, "Fat ignorou recarga")
	f.fat_cooldown = 0
	seed(offer_seed)
	f.try_fat_gun()
	check(f.skill_context == "fat" and f.fat_attempts == 2, "Oferta sortuda nao iniciou desafio")
	f.start_check()
	f.skill_progress = 0
	f.handle_key(KEY_SPACE)
	check(not f.gun_owned and f.skill_context == "", "Erro no teste deu arma")
	f.fat_cooldown = 0
	f.try_fat_gun()
	check(f.fat_attempts == 2 and f.skill_context == "", "Fat permitiu terceira tentativa")
	f.skill_context = "fat"
	pass_check(f)
	pass_check(f)
	check(f.gun_owned and f.ammo == 3 and main.player.upgrades.size() == 0, "Dois arremessos nao deram arma separada")
	main.player.global_position = Vector3(0, 0.05, 5)
	main.player.rotation = Vector3.ZERO
	main.player.head.rotation = Vector3.ZERO
	main.josias.global_position = Vector3(0, 0.05, 2)
	main.josias.stun_remaining = 0
	for frame in 3:
		await physics_frame
	f.fire()
	check(f.ammo == 2 and f.gun_cooldown == 12, "Disparo nao gastou municao")
	f.fire()
	check(f.ammo == 2, "Arma ignorou recarga")
	main.pause_game()
	for frame in 30:
		await physics_frame
	check(f.gun_cooldown == 12 and main.josias.stun_remaining == 0, "Projetil ou recarga continuou na pausa")
	main.resume_game()
	for frame in 30:
		await physics_frame
	check(main.josias.stun_remaining > 4, "Projetil nao atordoou Josias")
	# Parede entre o jogador e o Josias deve bloquear o projétil.
	var blocker := StaticBody3D.new()
	main.add_child(blocker)
	blocker.global_position = Vector3(0, 1.2, 3.5)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2, 3, 0.2)
	shape.shape = box
	blocker.add_child(shape)
	for frame in 3:
		await physics_frame
	f.gun_cooldown = 0
	main.josias.stun_remaining = 0
	f.fire()
	for frame in 45:
		await physics_frame
	check(main.josias.stun_remaining == 0, "Arma atravessou parede")
	print("PASS: troca de vida unica, RNG da oferta, recarga, falha/acerto do desafio, arma e colisao com parede.")
	main = fresh()
	f = main.features
	collect(main, 6)
	main.player.global_position = Vector3(0, 0.05, 5)
	main.ruan.global_position = Vector3(0.6, 0.05, 5)
	main._on_ruan_capture()
	check(main.player.carried and is_instance_valid(f.carry_visual), "Transporte sem modelo ao lado")
	check(not main.player.tomar_dano(), "Dano durante transporte")
	var count: int = main.balls_collected
	main.spawned_balls[0]._on_body_entered(main.player)
	check(main.balls_collected == count, "Coletou bola enquanto carregado")
	f.start_check()
	f.skill_progress = 0
	f.handle_key(KEY_SPACE)
	check(f.wiggles == 0, "Falha deixou progresso negativo")
	pass_check(f)
	pass_check(f)
	main.pause_game()
	var carry_clock: float = f.carry_time
	for frame in 30:
		await physics_frame
	check(f.carry_time == carry_clock, "Transporte continuou na pausa")
	main.resume_game()
	pass_check(f)
	check(not main.player.carried and main.balls_collected == count, "Escape roubou bolas")
	check(main.player.collision_layer == 1 and main.player.collision_mask == 3 and main.ruan.stun_remaining == 6, "Escape nao restaurou colisao ou atordoamento")
	main._on_ruan_capture()
	main.time_left = 0.01
	for frame in 3:
		await physics_frame
	check(main.state == main.State.ENDED and not main.hud.skill_panel.visible, "Tempo acabou no transporte e deixou habilidade aberta")
	print("PASS: escape com tres acertos, falha, protecao, sem coleta durante transporte, pausa e timeout.")
	print("TODOS OS TESTES DE MELHORIAS PASSARAM.")
	current_scene.free()
	current_scene = null
	await process_frame
	await process_frame
	OS.delay_msec(100)
	quit(0)
