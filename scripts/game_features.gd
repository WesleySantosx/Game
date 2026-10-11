extends Node
## Regras extras da partida. Todos os relógios avançam apenas em PLAYING.

const NAMES = {"shoes": "Tênis do Fabricio", "lungs": "Pulmão do Wesley", "hand": "Mão do Adrian"}
const HAND_COOLDOWN: float = 45.0
const GUN_COOLDOWN: float = 12.0
const GUN_STUN: float = 4.5
const FAT_CHANCE: float = 0.7
var game: Node3D
var items: Array[Node3D] = []
var hits: int = 0
var life_bought: bool = false
var gun_owned: bool = false
var ammo: int = 0
var gun_cooldown: float = 0
var fat_cooldown: float = 0
var fat_attempts: int = 0
var fat_talking: bool = false
var hand_cooldown: float = 0
var reveal_time: float = 0
var revealed_ball: Node3D
var reveal_marker: Label3D
var carry_time: float = 0
var wiggles: int = 0
var carry_visual: Node3D
var gun_visual: Node3D
var skill_context: String = ""
var skill_active: bool = false
var skill_progress: float = 0
var skill_start: float = 0.45
var skill_width: float = 0.2
var skill_delay: float = 0
var fat_successes: int = 0
var threat_timer: float = 0
var hoop_target: Vector3


func setup(owner_game: Node3D) -> void:
	game = owner_game
	process_mode = Node.PROCESS_MODE_PAUSABLE
	var markers := game.get_node("BallSpawns").get_children()
	# Pontos distintos, acessíveis e afastados da cela inicial.
	var choices: Array[int] = []
	for i in markers.size():
		if markers[i].global_position.distance_to(game.player.global_position) > 5.0:
			choices.append(i)
	choices.shuffle()
	var types := ["shoes", "lungs", "hand"]
	for i in types.size():
		create_item(types[i], markers[choices[i]].global_position)
	game.get_node("Fat/Hint").text = "FAT • [E]"
	game.get_node("Fat/Hint").pixel_size = 0.004
	var hoop := Node3D.new()
	game.add_child(hoop)
	hoop.global_position = game.get_node("Fat").global_position + Vector3(0, 0, -1.5)
	var board := BoxMesh.new()
	board.size = Vector3(0.9, 0.65, 0.06)
	mesh(hoop, board, Color(0.65, 0.7, 0.75), Vector3(0, 2.3, 0))
	var rim := TorusMesh.new()
	rim.inner_radius = 0.17
	rim.outer_radius = 0.21
	mesh(hoop, rim, Color(1, 0.3, 0.05), Vector3(0, 2.05, 0.28))
	hoop_target = hoop.global_position + Vector3(0, 2.05, 0.28)


func mesh(parent: Node3D, shape: Mesh, color: Color, position: Vector3) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = shape
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.65
	node.material_override = material
	parent.add_child(node)
	node.position = position
	return node


func create_item(kind: String, position: Vector3) -> Node3D:
	var item := Node3D.new()
	game.add_child(item)
	item.global_position = Vector3(position.x, 0.7, position.z)
	item.set_meta("kind", kind)
	var color := Color(0.3, 0.75, 1.0) if kind == "shoes" else (Color(1, 0.4, 0.55) if kind == "lungs" else Color(1, 0.8, 0.25))
	if kind == "shoes":
		for side in [-1, 1]:
			var box := BoxMesh.new()
			box.size = Vector3(0.16, 0.14, 0.4)
			mesh(item, box, color, Vector3(side * 0.13, 0, 0))
	elif kind == "lungs":
		for side in [-1, 1]:
			var lobe := SphereMesh.new()
			lobe.radius = 0.15
			lobe.height = 0.44
			mesh(item, lobe, color, Vector3(side * 0.15, 0, 0))
	else:
		var palm := BoxMesh.new()
		palm.size = Vector3(0.24, 0.24, 0.1)
		mesh(item, palm, color, Vector3.ZERO)
		for i in 4:
			var finger := CapsuleMesh.new()
			finger.radius = 0.025
			finger.height = 0.2
			mesh(item, finger, color, Vector3(-0.09 + i * 0.06, 0.2, 0))
	var label := Label3D.new()
	item.add_child(label)
	label.text = NAMES[kind]
	label.font_size = 34
	label.pixel_size = 0.008
	label.position.y = 0.55
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = color
	var light := OmniLight3D.new()
	item.add_child(light)
	light.light_color = color
	light.light_energy = 0.7
	light.omni_range = 2.0
	items.append(item)
	return item


func can_interact_with(target: Vector3, distance: float) -> bool:
	if game.player.global_position.distance_to(target) > distance:
		return false
	var from: Vector3 = game.player.global_position + Vector3.UP
	var query := PhysicsRayQueryParameters3D.create(from, Vector3(target.x, from.y, target.z), 1, [game.player.get_rid()])
	return game.get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func near_item() -> Node3D:
	var nearest: Node3D
	var distance: float = 2.0
	for item in items:
		var d: float = item.global_position.distance_to(game.player.global_position)
		if d < distance and can_interact_with(item.global_position, 2.0):
			nearest = item
			distance = d
	return nearest


func near_fat() -> bool:
	return can_interact_with(game.get_node("Fat").global_position, 2.8)


func equip_item(item: Node3D, slot: int = -1) -> bool:
	if not is_instance_valid(item) or game.player.carried or skill_context != "":
		return false
	var kind: String = item.get_meta("kind")
	var equipped: Array[String] = game.player.upgrades
	if equipped.has(kind):
		return false
	if equipped.size() == 2:
		if slot < 0 or slot > 1:
			return false
		var old: String = equipped[slot]
		equipped[slot] = kind
		create_item(old, item.global_position)
	else:
		equipped.append(kind)
	items.erase(item)
	item.queue_free()
	game.play_sound("pickup")
	game.hud.message.text = "Equipou %s! Até duas melhorias; a arma tem espaço próprio." % NAMES[kind]
	return true


func lose_on_hit() -> int:
	hits += 1
	var lost: int = game.balls_collected
	if hits == 1:
		lost = maxi(1, floori(float(lost) / 2.0)) if lost > 0 else 0
	if game.player.carried:
		end_carry(true)
	if skill_context == "fat":
		cancel_skill()
	game.hud.jumpscare("josias")
	return lost


func tick(delta: float) -> void:
	gun_cooldown = maxf(0, gun_cooldown - delta)
	fat_cooldown = maxf(0, fat_cooldown - delta)
	hand_cooldown = maxf(0, hand_cooldown - delta)
	reveal_time = maxf(0, reveal_time - delta)
	game.hud.tick_effects(delta)
	var fat: Node3D = game.get_node("Fat")
	var to_player: Vector3 = game.player.global_position - fat.global_position
	if to_player.length() < 4.0:
		fat.rotation.y = lerp_angle(fat.rotation.y, atan2(-to_player.x, -to_player.z), minf(delta * 4.0, 1.0))
	if fat_talking and not near_fat():
		fat_talking = false
	if skill_context == "fat" and not near_fat():
		cancel_skill()
		game.hud.message.text = "Saiu de perto do Fat: desafio cancelado e chance consumida."
	if skill_context != "":
		skill_delay = maxf(0, skill_delay - delta)
		if not skill_active and skill_delay <= 0:
			start_check()
		if skill_active:
			skill_progress += delta / (1.8 if skill_context == "carry" else 2.1)
			if skill_progress >= 1.0:
				resolve_check(false)
	if game.player.carried:
		carry_time += delta
		var ruan = game.ruan
		var shoulder: Vector3 = ruan.global_transform.basis.x * 0.55
		game.player.global_position = ruan.global_position + shoulder + Vector3(0, 0.18, 0)
		if carry_time >= 18.0:
			end_carry(true)
		elif carry_time >= 7.0 and ruan.global_position.distance_to(game.josias.global_position) < 2.8:
			end_carry(false)
		if is_instance_valid(carry_visual):
			carry_visual.position.y = -1.6 + sin(carry_time * 8) * 0.025
	for item in items:
		item.rotation.y += delta * 0.7
	if reveal_time > 0 and is_instance_valid(revealed_ball) and not revealed_ball.taken:
		reveal_marker.global_position = revealed_ball.global_position + Vector3(0, 1, 0)
		reveal_marker.text = "BOLA • %dm" % roundi(game.player.global_position.distance_to(revealed_ball.global_position))
		reveal_marker.show()
	elif is_instance_valid(reveal_marker):
		reveal_marker.hide()
	update_hud()
	# O som acelera quando a ameaça está perto, sem atravessar paredes visualmente.
	threat_timer -= delta
	var proximity: float = game.player.global_position.distance_to(game.josias.global_position)
	if threat_timer <= 0 and proximity < 9 and not game.player.carried and game.josias.stun_remaining <= 0:
		game.play_sound("step", -12.0)
		threat_timer = lerpf(0.35, 1.25, clampf(proximity / 9.0, 0, 1))


func update_hud() -> void:
	var hud = game.hud
	hud.stamina_bar.value = game.player.stamina
	hud.stamina_bar.modulate = Color(1, 0.4, 0.3) if game.player.sprint_locked else Color(0.4, 0.9, 1)
	var slots: Array[String] = []
	for kind in game.player.upgrades:
		slots.append(NAMES[kind])
	hud.equipment.text = "Melhorias %d/2: %s" % [slots.size(), " + ".join(slots) if not slots.is_empty() else "procure os objetos iluminados"]
	if game.player.upgrades.has("hand"):
		hud.equipment.text += "\n[Q] Bola revelada por 6s • " + ("PRONTO" if hand_cooldown <= 0 else "%ds" % ceili(hand_cooldown))
	if gun_owned:
		hud.equipment.text += "\nArremessadora: %d/3 • %s" % [ammo, "SEM MUNIÇÃO" if ammo == 0 else ("CLIQUE para disparar" if gun_cooldown <= 0 else "recarga %ds" % ceili(gun_cooldown))]
	if reveal_time > 0 and is_instance_valid(revealed_ball) and not revealed_ball.taken:
		var camera: Camera3D = game.player.get_node("Head/Camera3D")
		var relative: Vector3 = camera.global_basis.inverse() * (revealed_ball.global_position - camera.global_position)
		var bearing: String = "ATRÁS" if relative.z > 0 else ("À ESQUERDA" if relative.x < -2 else ("À DIREITA" if relative.x > 2 else "À FRENTE"))
		hud.equipment.text += "\nBOLA %s • %dm • %.1fs" % [bearing, roundi(relative.length()), reveal_time]
	hud.stun_label.text = "Josias atordoado: %.1fs" % game.josias.stun_remaining if game.josias.stun_remaining > 0 else ""
	if is_instance_valid(game.ruan) and game.ruan.stun_remaining > 0:
		hud.stun_label.text += "\nRuan atordoado: %.1fs" % game.ruan.stun_remaining
	var title := "[ESPAÇO] Escape do Ruan: %d/3" % wiggles if skill_context == "carry" else "[ESPAÇO] Arremesso: %d/2" % fat_successes
	hud.update_skill(skill_active, title, skill_progress, skill_start, skill_width)
	if game.player.carried:
		hud.prompt.text = "RUAN TE CARREGANDO! Acerte o verde para se debater (%d/3)." % wiggles
	elif skill_context == "fat":
		hud.prompt.text = "Desafio do Fat • Dois acertos seguidos. O relógio continua!"
	elif near_fat():
		hud.prompt.text = "[E] Conversar com o Fat"
		if fat_talking:
			hud.prompt.text = "[G] Tentar arma (%d/2 chances)   [T] 5 bolas = +1 vida\n%s" % [fat_attempts, "Vida extra já comprada" if life_bought else "Uma troca de vida por partida"]
	else:
		var item := near_item()
		if item:
			var names: Array[String] = []
			for kind in game.player.upgrades:
				names.append(NAMES[kind])
			hud.prompt.text = "[E] Pegar " + str(NAMES[item.get_meta("kind")]) if names.size() < 2 else "[1] Trocar %s   [2] Trocar %s\npor %s" % [names[0], names[1], NAMES[item.get_meta("kind")]]


func handle_key(key: int) -> bool:
	if key == KEY_SPACE and skill_active:
		resolve_check(skill_progress >= skill_start and skill_progress <= skill_start + skill_width)
		return true
	if game.player.carried or skill_context != "":
		return key in [KEY_E, KEY_Q, KEY_G, KEY_T, KEY_1, KEY_2]
	if key == KEY_Q:
		reveal_ball()
		return true
	if near_fat():
		if key == KEY_E:
			fat_talking = not fat_talking
			return true
		if fat_talking and key == KEY_G:
			try_fat_gun()
			return true
		if fat_talking and key == KEY_T:
			trade_life()
			return true
	var item := near_item()
	if item and key in [KEY_E, KEY_1, KEY_2]:
		if key == KEY_E:
			equip_item(item)
		else:
			equip_item(item, 0 if key == KEY_1 else 1)
		return true
	return false


func trade_life() -> bool:
	if not near_fat() or game.player.carried or life_bought or game.balls_collected < 5:
		game.hud.message.text = "Fat: preciso de 5 bolas. Só posso te dar uma vida extra por partida."
		return false
	life_bought = true
	game.player.vidas += 1
	game.lose_balls(5)
	game.play_sound("pickup")
	game.hud.message.text = "Fat: negócio fechado! +1 vida. As cinco bolas voltaram ao mapa."
	return true


func try_fat_gun() -> void:
	if not near_fat() or gun_owned or fat_attempts >= 2 or fat_cooldown > 0:
		game.hud.message.text = "Fat: %s" % ("já te dei a arma!" if gun_owned else ("acabaram as duas chances!" if fat_attempts >= 2 else "volta em %ds." % ceili(fat_cooldown)))
		return
	fat_attempts += 1
	fat_cooldown = 45
	if randf() > FAT_CHANCE:
		game.hud.message.text = "Fat: hoje não... Tenta de novo depois de 45s (se ainda tiver chance)."
		return
	fat_successes = 0
	skill_context = "fat"
	skill_delay = 0.65
	game.player.grant_protection(5.5)
	game.hud.message.text = "Fat: teve sorte! Acerte DOIS arremessos seguidos no verde para ganhar a arma!"


func start_check() -> void:
	skill_active = true
	skill_progress = 0
	skill_width = 0.22 if skill_context == "carry" else 0.18
	skill_start = randf_range(0.3, 0.72)
	game.play_sound("pickup", -19.0)


func resolve_check(success: bool) -> void:
	if not skill_active:
		return
	skill_active = false
	skill_delay = 0.65
	game.play_sound("pickup" if success else "hurt", -13.0)
	if skill_context == "carry":
		wiggles = mini(3, wiggles + 1) if success else maxi(0, wiggles - 1)
		if wiggles >= 3:
			end_carry(true)
	elif skill_context == "fat":
		if not success:
			cancel_skill()
			game.hud.message.text = "Fat: errou o arremesso! Essa chance foi embora."
		else:
			fat_successes += 1
			show_throw(hoop_target, false)
			if fat_successes >= 2:
				cancel_skill()
				give_gun()


func cancel_skill() -> void:
	skill_active = false
	skill_context = ""
	game.hud.skill_panel.hide()


func begin_carry() -> void:
	if game.player.carried:
		return
	cancel_skill()
	fat_talking = false
	game.player.carried = true
	if is_instance_valid(gun_visual):
		gun_visual.hide()
	game.player.collision_layer = 0
	game.player.collision_mask = 0
	game.player.velocity = Vector3.ZERO
	game.ruan.carrying = true
	game.ruan.get_node("Visual").hide()
	game.ruan.delivery_target = game.josias
	game.ruan.speed = 3.2
	game.ruan.stun_remaining = 0
	game.ruan.path_update_time = 0
	carry_time = 0
	wiggles = 0
	skill_context = "carry"
	skill_delay = 0.8
	carry_visual = load("res://scenes/ruan.tscn").instantiate()
	game.player.get_node("Head/Camera3D").add_child(carry_visual)
	carry_visual.position = Vector3(0.52, -1.6, -1.05)
	carry_visual.scale = Vector3.ONE * 0.9
	carry_visual.rotation.y = PI * 0.8
	game.hud.jumpscare("ruan")
	game.play_sound("ruan")


func end_carry(escaped: bool) -> void:
	if not game.player.carried:
		return
	cancel_skill()
	game.player.carried = false
	if is_instance_valid(gun_visual):
		gun_visual.show()
	game.player.collision_layer = 1
	game.player.collision_mask = 3
	game.player.global_position = Vector3(game.ruan.global_position.x, 0.05, game.ruan.global_position.z)
	game.player.grant_protection(2.5 if escaped else 3.5)
	game.ruan.carrying = false
	game.ruan.get_node("Visual").show()
	game.ruan.speed = game.ruan.base_speed
	game.ruan.stun(6.0 if escaped else 8.0)
	if is_instance_valid(carry_visual):
		carry_visual.queue_free()
	if escaped:
		game.hud.message.text = "Se soltou do Ruan! Nenhuma bola perdida. CORRE!"
	else:
		game.lose_balls(mini(2, game.balls_collected))
		game.josias.stun(3.5)
		game.hud.message.text = "O Ruan te entregou! Perdeu até 2 bolas. Josias atordoado por 3,5s: FOGE!"


func reveal_ball() -> void:
	if not game.player.upgrades.has("hand") or hand_cooldown > 0:
		return
	var available: Array[Node3D] = []
	for ball in game.spawned_balls:
		if is_instance_valid(ball) and not ball.taken:
			available.append(ball)
	if available.is_empty():
		game.hud.message.text = "Já está com todas! Volte à cela verde."
		return
	revealed_ball = available.pick_random()
	hand_cooldown = HAND_COOLDOWN
	reveal_time = 6.0
	if not is_instance_valid(reveal_marker):
		reveal_marker = Label3D.new()
		game.add_child(reveal_marker)
		reveal_marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		reveal_marker.no_depth_test = true
		reveal_marker.fixed_size = true
		reveal_marker.font_size = 56
		reveal_marker.modulate = Color(1, 0.85, 0.15)
	game.play_sound("pickup")
	game.hud.message.text = "Adrian revelou uma bola por 6 segundos, mesmo através das paredes!"


func give_gun() -> void:
	gun_owned = true
	ammo = 3
	game.hud.message.text = "Fat: toma a Arremessadora! Clique lança uma boneca-mulher e atordoa o Josias. 3 disparos!"
	gun_visual = Node3D.new()
	game.player.get_node("Head/Camera3D").add_child(gun_visual)
	gun_visual.position = Vector3(0.28, -0.28, -0.55)
	var barrel := CylinderMesh.new()
	barrel.top_radius = 0.075
	barrel.bottom_radius = 0.1
	barrel.height = 0.4
	var tube := mesh(gun_visual, barrel, Color(0.25, 0.3, 0.38), Vector3.ZERO)
	tube.rotation.x = PI / 2
	var grip := BoxMesh.new()
	grip.size = Vector3(0.08, 0.16, 0.1)
	mesh(gun_visual, grip, Color(0.1, 0.1, 0.12), Vector3(0, -0.12, 0.1))


func fire() -> void:
	if not gun_owned or ammo <= 0 or gun_cooldown > 0 or game.player.carried or skill_context != "":
		return
	ammo -= 1
	gun_cooldown = GUN_COOLDOWN
	var camera: Camera3D = game.player.get_node("Head/Camera3D")
	var origin := camera.global_position
	var destination := origin - camera.global_basis.z * 16.0
	var ray := PhysicsRayQueryParameters3D.create(origin, destination, 3, [game.player.get_rid()])
	var hit := game.get_world_3d().direct_space_state.intersect_ray(ray)
	var target: Node3D
	if not hit.is_empty():
		destination = hit.position
		if hit.collider == game.josias:
			target = game.josias
	show_throw(destination, true, target)
	game.play_sound("ruan", -15.0)
	game.hud.message.text = "Boneca lançada! Acerte o Josias para atordoar por 4,5s."


func show_throw(destination: Vector3, doll: bool, target: Node3D = null) -> void:
	var projectile := Node3D.new()
	projectile.process_mode = Node.PROCESS_MODE_PAUSABLE
	game.add_child(projectile)
	projectile.global_position = game.player.get_node("Head/Camera3D").global_position + Vector3(0, -0.2, 0)
	if doll:
		var dress := CylinderMesh.new()
		dress.top_radius = 0.08
		dress.bottom_radius = 0.18
		dress.height = 0.4
		mesh(projectile, dress, Color(0.85, 0.2, 0.6), Vector3.ZERO)
		var head := SphereMesh.new()
		head.radius = 0.09
		head.height = 0.18
		mesh(projectile, head, Color(0.8, 0.58, 0.4), Vector3(0, 0.3, 0))
		for side in [-1, 1]:
			var limb := CapsuleMesh.new()
			limb.radius = 0.025
			limb.height = 0.24
			mesh(projectile, limb, Color(0.8, 0.58, 0.4), Vector3(side * 0.1, -0.28, 0))
	else:
		var ball := SphereMesh.new()
		ball.radius = 0.13
		ball.height = 0.26
		mesh(projectile, ball, Color(1, 0.4, 0.05), Vector3.ZERO)
	var duration := clampf(projectile.global_position.distance_to(destination) / 25.0, 0.12, 0.6)
	var tween := projectile.create_tween()
	tween.tween_property(projectile, "global_position", destination, duration)
	tween.tween_callback(func():
		if is_instance_valid(target) and game.state == game.State.PLAYING:
			target.stun(GUN_STUN)
			game.hud.message.text = "ACERTOU! Josias atordoado. Aproveita para fugir!"
		projectile.queue_free())


func cleanup() -> void:
	cancel_skill()
	game.hud.scare.hide()
	game.hud.scare_time = 0
	if is_instance_valid(reveal_marker):
		reveal_marker.hide()
	if is_instance_valid(carry_visual):
		carry_visual.hide()
	if is_instance_valid(gun_visual):
		gun_visual.hide()
