extends Node3D

enum State { MENU, PLAYING, PAUSED, ENDING, ENDED }

const BALL_SCENE = preload("res://scenes/ball.tscn")
const RUAN_SCENE = preload("res://scenes/ruan_enemy.tscn")
const RUAN_INTRO_SCENE = preload("res://scenes/ruan_intro.tscn")
const BASKET_ENDING = preload("res://scenes/basket_ending.tscn")
const TOTAL_BALLS: int = 7

@export var round_seconds: float = 300.0
var state: State = State.MENU
var balls_collected: int = 0
var held_indices: Array[int] = []
var ruan_spawned: bool = false
var game_over: bool = false
var time_left: float = 300.0
var spawned_balls: Array[Node] = []
var ruan: CharacterBody3D
var ambient: AudioStreamPlayer

@onready var player = $Player
@onready var josias = $Josias
@onready var serjo = $Serjo
@onready var hud = $HUD


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	player.process_mode = Node.PROCESS_MODE_PAUSABLE
	josias.process_mode = Node.PROCESS_MODE_PAUSABLE
	serjo.process_mode = Node.PROCESS_MODE_PAUSABLE
	player.vidas_alteradas.connect(_on_player_hurt)
	player.morreu.connect(_on_player_died)
	hud.start_requested.connect(start_game)
	hud.resume_requested.connect(resume_game)
	hud.restart_requested.connect(restart_game)
	hud.menu_requested.connect(return_to_menu)
	hud.quit_requested.connect(quit_game)
	time_left = round_seconds
	_setup_ambient()
	player.set_controls_enabled(false)
	josias.set_physics_process(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if get_tree().has_meta("start_immediately"):
		get_tree().remove_meta("start_immediately")
		start_game()
	else:
		hud.show_menu()


func start_game() -> void:
	if state != State.MENU:
		return
	state = State.PLAYING
	game_over = false
	get_tree().paused = false
	player.set_controls_enabled(true)
	josias.set_physics_process(true)
	josias.set_anger(0)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	hud.show_game()
	hud.message.text = "Encontre 7 bolas e liberte o Serjo na cela iluminada de verde."
	spawn_balls()
	_update_hud()


func _physics_process(delta: float) -> void:
	if state != State.PLAYING:
		return
	time_left = maxf(0.0, time_left - delta)
	if time_left <= 0.0:
		_finish("timeout")
		return
	_update_hud()
	if _can_reach_cage():
		hud.prompt.text = "[E] Libertar o Serjo" if balls_collected == 7 else "Serjo precisa das 7 bolas (%d / 7)" % balls_collected
	else:
		hud.prompt.text = ""


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.physical_keycode:
		KEY_ESCAPE:
			if state == State.PLAYING:
				pause_game()
			elif state == State.PAUSED:
				resume_game()
		KEY_R:
			if state != State.MENU:
				restart_game()
		KEY_E:
			if state == State.PLAYING and _can_reach_cage():
				if balls_collected == 7:
					_finish("rescue")
				else:
					hud.message.text = "Ainda faltam %d bolas para abrir a cela!" % (7 - balls_collected)
		KEY_F11:
			var mode := DisplayServer.window_get_mode()
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if mode == DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)


func pause_game() -> void:
	state = State.PAUSED
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	hud.show_pause()


func resume_game() -> void:
	state = State.PLAYING
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	hud.show_game()


func restart_game() -> void:
	get_tree().paused = false
	get_tree().set_meta("start_immediately", true)
	get_tree().reload_current_scene()


func return_to_menu() -> void:
	get_tree().paused = false
	if get_tree().has_meta("start_immediately"):
		get_tree().remove_meta("start_immediately")
	get_tree().reload_current_scene()


func _exit_tree() -> void:
	for audio in find_children("*", "AudioStreamPlayer", true, false):
		audio.stop()
	for audio in find_children("*", "AudioStreamPlayer3D", true, false):
		audio.stop()


func quit_game() -> void:
	get_tree().paused = false
	_exit_tree()
	await get_tree().create_timer(0.15).timeout
	get_tree().quit()


func spawn_balls() -> void:
	if game_over:
		return
	var points := $BallSpawns.get_children()
	var available: Array[int] = []
	var distant: Array[int] = []
	for i in points.size():
		if not held_indices.has(i):
			available.append(i)
			if points[i].global_position.distance_to(player.global_position) > 1.5:
				distant.append(i)
	var remaining := TOTAL_BALLS - balls_collected
	if available.size() < remaining:
		push_error("Coloque pelo menos 7 marcadores em BallSpawns.")
		return
	if distant.size() >= remaining:
		available = distant
	available.shuffle()
	for i in remaining:
		var ball = BALL_SCENE.instantiate()
		ball.spawn_index = available[i]
		ball.process_mode = Node.PROCESS_MODE_PAUSABLE
		ball.collected.connect(_on_ball_collected)
		add_child(ball)
		ball.global_position = points[available[i]].global_position
		spawned_balls.append(ball)


func clear_balls() -> void:
	for ball in spawned_balls:
		if is_instance_valid(ball):
			ball.taken = true
			if ball.is_connected("collected", _on_ball_collected):
				ball.disconnect("collected", _on_ball_collected)
			ball.queue_free()
	spawned_balls.clear()


func _on_ball_collected(ball: Area3D) -> void:
	if state != State.PLAYING:
		return
	held_indices.append(ball.spawn_index)
	spawned_balls.erase(ball)
	balls_collected = held_indices.size()
	josias.set_anger(balls_collected)
	ambient.pitch_scale = 1.0 + float(balls_collected) * 0.025
	serjo.set_unlocked(balls_collected == 7)
	play_sound("pickup")
	if balls_collected == 7:
		hud.message.text = "Pegou as 7! Volte à cela verde e aperte E para libertar o Serjo!"
	elif balls_collected == 6 and not ruan_spawned:
		spawn_ruan()
		hud.message.text = "O RUAN APARECEU! Ele vai te levar até o Josias."
	else:
		hud.message.text = "Bola %d! O Josias está ficando mais bravo." % balls_collected
	_update_hud()


func _on_player_hurt(_remaining: int) -> void:
	if state != State.PLAYING:
		return
	hud.flash_hit()
	play_sound("hurt")
	play_sound("capture", -2.0)
	held_indices.clear()
	balls_collected = 0
	josias.set_anger(0)
	serjo.set_unlocked(false)
	clear_balls()
	hud.message.text = "VIU AI FESO! O Josias espalhou todas as bolas. Corre!"
	if player.vidas > 0:
		spawn_balls.call_deferred()
	_update_hud()


func _on_player_died() -> void:
	_finish("captures")


func spawn_ruan() -> void:
	if ruan_spawned:
		return
	ruan_spawned = true
	var points := $BallSpawns.get_children()
	var farthest: Node3D = points[0]
	for point in points:
		if point.global_position.distance_squared_to(player.global_position) > farthest.global_position.distance_squared_to(player.global_position):
			farthest = point
	ruan = RUAN_SCENE.instantiate()
	ruan.name = "Ruan"
	ruan.process_mode = Node.PROCESS_MODE_PAUSABLE
	ruan.captured.connect(_on_ruan_capture)
	add_child(ruan)
	ruan.global_position = Vector3(farthest.global_position.x, 0.0, farthest.global_position.z)
	ruan.stun(2.8)
	josias.stun(2.8)
	player.grant_protection(2.8)
	var intro = RUAN_INTRO_SCENE.instantiate()
	intro.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(intro)
	intro.play_intro()
	play_sound("ruan")


func _on_ruan_capture() -> void:
	if state != State.PLAYING:
		return
	var lost := mini(2, balls_collected)
	for i in lost:
		held_indices.pop_back()
	balls_collected = held_indices.size()
	player.grant_protection(3.5)
	josias.stun(3.5)
	player.global_position = _drop_position_near_josias()
	player.velocity = Vector3.ZERO
	josias.set_anger(balls_collected)
	serjo.set_unlocked(balls_collected == 7)
	clear_balls()
	spawn_balls.call_deferred()
	hud.flash_hit()
	play_sound("ruan")
	hud.message.text = "O Ruan te levou até o Josias! Perdeu %d bolas. O Josias está atordoado: foge!" % lost
	_update_hud()


func _drop_position_near_josias() -> Vector3:
	var map: RID = josias.get_world_3d().navigation_map
	var path := NavigationServer3D.map_get_path(map, josias.global_position, player.global_position, true)
	var remaining := 3.0
	for i in range(1, path.size()):
		var length := path[i - 1].distance_to(path[i])
		if length >= remaining:
			var point := path[i - 1].lerp(path[i], remaining / length)
			return Vector3(point.x, 0.05, point.z)
		remaining -= length
	return player.global_position


func _can_reach_cage() -> bool:
	if not serjo.is_near(player.global_position):
		return false
	var query := PhysicsRayQueryParameters3D.create(player.global_position + Vector3.UP, serjo.global_position + Vector3(0, 1, -0.85), 1, [player.get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or hit.collider == serjo.door_body


func _update_hud() -> void:
	hud.update_status(balls_collected, player.vidas, time_left)


func _finish(reason: String) -> void:
	if state != State.PLAYING:
		return
	state = State.ENDING
	game_over = true
	player.set_controls_enabled(false)
	josias.velocity = Vector3.ZERO
	josias.set_physics_process(false)
	if is_instance_valid(ruan):
		ruan.velocity = Vector3.ZERO
		ruan.set_physics_process(false)
	for child in get_children():
		if child is CanvasLayer and child != hud:
			child.queue_free()
	clear_balls()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	hud.show_cinematic()
	var won := reason == "rescue"
	var title := "SERJO LIBERTO!" if won else "VOCÊ PERDEU!"
	var description := "Você juntou as 7 bolas e tirou o Serjo da cela. Os manos estão salvos!"
	if won:
		serjo.rescue()
		play_sound("win")
		await get_tree().create_timer(1.4).timeout
	elif reason == "captures":
		var cinematic := BASKET_ENDING.instantiate()
		add_child(cinematic)
		cinematic.position = Vector3(100, 0, 100)
		play_sound("lose")
		description = "O Josias te pegou 3 vezes e acertou a cesta. Fim de jogo!"
		await get_tree().create_timer(3.2).timeout
	else:
		serjo.prisoner.hide()
		play_sound("lose")
		description = "O tempo acabou. Serjo tirou a própria vida de decepção antes de ser resgatado."
	if not is_inside_tree():
		return
	state = State.ENDED
	hud.show_end(title, description, won)


func _setup_ambient() -> void:
	ambient = AudioStreamPlayer.new()
	add_child(ambient)
	ambient.process_mode = Node.PROCESS_MODE_PAUSABLE
	var stream := load("res://assets/audio/hum.wav") as AudioStreamWAV
	if stream:
		stream = stream.duplicate()
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = int(stream.get_length() * stream.mix_rate)
		ambient.stream = stream
		ambient.volume_db = -17.0
		ambient.play()


func play_sound(sound: String, volume: float = -8.0) -> void:
	var audio := AudioStreamPlayer.new()
	add_child(audio)
	audio.process_mode = Node.PROCESS_MODE_PAUSABLE
	audio.stream = load("res://assets/audio/%s.wav" % sound)
	audio.volume_db = volume
	audio.finished.connect(audio.queue_free)
	audio.play()
