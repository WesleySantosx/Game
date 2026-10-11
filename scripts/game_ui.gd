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
	var help := _label(info, "WASD: mover   SHIFT: correr   F: lanterna   E: interagir   ESC: pausar   R: reiniciar   F11: tela cheia", 16, Vector2(24, -38), Vector2(1200, 30))
	help.anchor_top = 1.0
	help.anchor_bottom = 1.0
	help.modulate = Color(0.65, 0.7, 0.8)
	flash = ColorRect.new()
	root.add_child(flash)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.color = Color(0.85, 0, 0, 0)
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
	_screen("COMO JOGAR", "WASD: andar • Shift: correr • Mouse: olhar • F: lanterna\nE: libertar o Serjo • Esc: pausar • F11: tela cheia\nJosias: perde 1 vida e todas as bolas. Na terceira captura, você perde.\nRuan: perde 2 bolas e vai parar perto do Josias, que fica atordoado por alguns segundos.\nAs bolas perdidas voltam ao mapa. Corra antes que o tempo acabe!")
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
	lives.text = "Vidas: %d / 3" % health
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
