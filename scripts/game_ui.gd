extends CanvasLayer

signal start_requested
signal resume_requested
signal restart_requested
signal menu_requested
signal quit_requested

var root: Control
var info: Control
var overlay: ColorRect
var panel: VBoxContainer
var counter: Label
var lives: Label
var clock: Label
var anger: Label
var message: Label
var prompt: Label
var flash: ColorRect
var flash_tween: Tween
var stamina_bar: ProgressBar
var equipment: Label
var stun_label: Label
var skill_panel: Control
var skill_title: Label
var skill_track: ColorRect
var skill_zone: ColorRect
var skill_pointer: ColorRect
var scare: TextureRect
var scare_time: float = 0.0


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info = Control.new()
	root.add_child(info)
	info.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	counter = _label(info, "Bolas: 0 / 7", 28, Vector2(24, 20), Vector2(350, 42))
	lives = _label(info, "Vidas: 3 / 3", 22, Vector2(24, 62), Vector2(350, 34))
	anger = _label(info, "Josias: CALMO", 18, Vector2(24, 99), Vector2(450, 30))
	stamina_bar = ProgressBar.new()
	info.add_child(stamina_bar)
	stamina_bar.position = Vector2(24, 139)
	stamina_bar.size = Vector2(240, 16)
	stamina_bar.show_percentage = false
	equipment = _label(info, "", 17, Vector2(24, 165), Vector2(650, 115))
	stun_label = _label(info, "", 22, Vector2(-470, 85), Vector2(440, 95))
	stun_label.anchor_left = 1.0
	stun_label.anchor_right = 1.0
	stun_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	clock = _label(info, "05:00", 32, Vector2(-200, 20), Vector2(175, 50))
	clock.anchor_left = 1.0
	clock.anchor_right = 1.0
	clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var crosshair := _label(info, "+", 24, Vector2(-12, -18), Vector2(24, 36))
	crosshair.anchor_left = 0.5
	crosshair.anchor_top = 0.5
	crosshair.anchor_right = 0.5
	crosshair.anchor_bottom = 0.5
	crosshair.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message = _label(info, "", 20, Vector2(24, -112), Vector2(1100, 65))
	message.anchor_top = 1.0
	message.anchor_bottom = 1.0
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prompt = _label(info, "", 23, Vector2(-400, 70), Vector2(800, 70))
	prompt.anchor_left = 0.5
	prompt.anchor_right = 0.5
	prompt.anchor_top = 0.5
	prompt.anchor_bottom = 0.5
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.modulate = Color(0.65, 1, 0.75)
	var help := _label(info, "WASD mover  SHIFT correr  F lanterna  E interagir  Q revelar  Clique disparar  ESPAÇO habilidade  ESC pausa", 15, Vector2(24, -38), Vector2(1240, 30))
	help.anchor_top = 1.0
	help.anchor_bottom = 1.0
	help.modulate = Color(0.65, 0.7, 0.8)
	flash = ColorRect.new()
	root.add_child(flash)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.color = Color(0.85, 0, 0, 0)
	scare = TextureRect.new()
	root.add_child(scare)
	scare.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scare.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	scare.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	scare.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scare.hide()
	skill_panel = Control.new()
	info.add_child(skill_panel)
	skill_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	skill_panel.offset_left = -260
	skill_panel.offset_right = 260
	skill_panel.offset_top = 170
	skill_panel.offset_bottom = 260
	skill_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	skill_title = _label(skill_panel, "", 22, Vector2(0, -42), Vector2(520, 40))
	skill_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skill_track = ColorRect.new()
	skill_panel.add_child(skill_track)
	skill_track.size = Vector2(520, 26)
	skill_track.color = Color(0.06, 0.07, 0.1, 0.95)
	skill_zone = ColorRect.new()
	skill_track.add_child(skill_zone)
	skill_zone.color = Color(0.25, 0.95, 0.45)
	skill_pointer = ColorRect.new()
	skill_track.add_child(skill_pointer)
	skill_pointer.size = Vector2(5, 40)
	skill_pointer.position.y = -7
	skill_pointer.color = Color.WHITE
	skill_panel.hide()
	overlay = ColorRect.new()
	root.add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.015, 0.02, 0.035, 0.94)
	overlay.hide()


func _label(parent: Node, text: String, font_size: int, offset: Vector2, extent: Vector2) -> Label:
	var label := Label.new()
	parent.add_child(label)
	label.text = text
	label.position = offset
	label.size = extent
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _screen(title: String, description: String, color: Color = Color(0.9, 0.94, 1)) -> void:
	info.hide()
	flash.color.a = 0.0
	overlay.show()
	if is_instance_valid(panel):
		panel.hide()
		panel.queue_free()
	panel = VBoxContainer.new()
	overlay.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -390
	panel.offset_right = 390
	panel.offset_top = -240
	panel.offset_bottom = 240
	panel.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_theme_constant_override("separation", 17)
	var heading := _label(panel, title, 44, Vector2.ZERO, Vector2.ZERO)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.modulate = color
	var text := _label(panel, description, 21, Vector2.ZERO, Vector2.ZERO)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.custom_minimum_size.y = 100


func _button(text: String, callback: Callable, focused: bool = false) -> Button:
	var button := Button.new()
	panel.add_child(button)
	button.text = text
	button.custom_minimum_size.y = 50
	button.add_theme_font_size_override("font_size", 23)
	button.pressed.connect(callback)
	if focused:
		button.grab_focus()
	return button


func show_menu() -> void:
	_screen("RESGATE DO SERJO", "Encontre 7 bolas no labirinto e volte à cela para libertar o Serjo.\nVocê tem 5 minutos e 3 vidas. Na sexta bola, o Ruan entra na caçada.")
	_button("Jogar", func(): start_requested.emit(), true)
	_button("Como jogar", show_instructions)
	_add_volume()
	_button("Sair", func(): quit_requested.emit())


func show_instructions() -> void:
	_screen("COMO JOGAR", "WASD andar • Shift correr (stamina) • F lanterna • E interagir\nJosias tira 1 vida: primeira pancada perde metade das bolas; depois, todas.\nRuan carrega até Josias: acerte 3 testes com ESPAÇO para escapar!\nPegue até 2 melhorias. Com slots cheios, 1 ou 2 troca o item. Q usa a mão.\nFat: E conversar, G tentar arma, T trocar 5 bolas por uma vida extra.\nArma: acerte 2 testes; clique atira. Verde = ESPAÇO! Esc pausa; R reinicia.")
	_button("Voltar", show_menu, true)


func _add_volume() -> void:
	var label := _label(panel, "Volume", 18, Vector2.ZERO, Vector2.ZERO)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var slider := HSlider.new()
	panel.add_child(slider)
	slider.min_value = 0
	slider.max_value = 1
	slider.step = 0.05
	slider.value = AudioServer.get_bus_volume_linear(0)
	slider.value_changed.connect(func(value: float): AudioServer.set_bus_volume_linear(0, value))


func show_pause() -> void:
	_screen("PAUSADO", "O relógio e os inimigos estão parados.")
	_button("Continuar", func(): resume_requested.emit(), true)
	_button("Reiniciar", func(): restart_requested.emit())
	_button("Menu principal", func(): menu_requested.emit())
	_add_volume()


func show_end(title: String, description: String, won: bool) -> void:
	_screen(title, description, Color(0.5, 1, 0.65) if won else Color(1, 0.4, 0.35))
	overlay.color.a = 0.88
	_button("Jogar de novo (R)", func(): restart_requested.emit(), true)
	_button("Menu principal", func(): menu_requested.emit())
	_button("Sair", func(): quit_requested.emit())


func show_game() -> void:
	overlay.hide()
	info.show()


func show_cinematic() -> void:
	overlay.hide()
	info.hide()


func update_status(balls: int, health: int, seconds: float) -> void:
	counter.text = "Bolas: %d / 7" % balls
	lives.text = "Vidas: %d" % health
	var total := ceili(maxf(0, seconds))
	clock.text = "%02d:%02d" % [total / 60, total % 60]
	clock.modulate = Color(1, 0.35, 0.3) if seconds <= 60 else Color.WHITE
	var moods := ["CALMO", "DESCONFIADO", "IRRITADO", "BRAVO", "FURIOSO", "MUITO FURIOSO", "FORA DE SI", "SEM LIMITES"]
	anger.text = "Josias: %s" % moods[clampi(balls, 0, 7)]
	anger.modulate = Color.WHITE.lerp(Color(1, 0.2, 0.1), float(balls) / 7.0)


func flash_hit() -> void:
	if flash_tween:
		flash_tween.kill()
	flash.color.a = 0.4
	flash_tween = create_tween()
	flash_tween.tween_property(flash, "color:a", 0.0, 0.6)


func update_skill(active: bool, title: String, progress: float, zone_start: float, zone_width: float) -> void:
	skill_panel.visible = active
	skill_title.text = title
	skill_zone.position.x = zone_start * 520.0
	skill_zone.size = Vector2(zone_width * 520.0, 26)
	skill_pointer.position.x = progress * 515.0


func jumpscare(who: String) -> void:
	scare.texture = load("res://models/ruan_textured/ruan_face.png" if who == "ruan" else "res://models/josias_textured/josias_face.png")
	scare.modulate = Color(1.0, 0.65, 0.65)
	scare_time = 0.55
	scare.show()


func tick_effects(delta: float) -> void:
	scare_time = maxf(0, scare_time - delta)
	scare.visible = scare_time > 0
	if scare_time > 0:
		scare.modulate.a = minf(1.0, scare_time / 0.15)
