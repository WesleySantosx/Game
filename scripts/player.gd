extends CharacterBody3D

signal vidas_alteradas(quantidade: int)
signal morreu

@export var walk_speed: float = 3.5
@export var sprint_speed: float = 6.0
@export var mouse_sensitivity: float = 0.002

@onready var head: Node3D = $Head
@onready var flashlight: SpotLight3D = $Head/Camera3D/Flashlight

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var vidas: int = 3
var invulneravel: bool = false
var tempo_invulneravel: float = 0.0
var controls_enabled: bool = true
var footsteps: AudioStreamPlayer
var footstep_time: float = 0.0
var carried: bool = false
var stamina: float = 100.0
var stamina_delay: float = 0.0
var sprint_locked: bool = false
var upgrades: Array[String] = []

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	footsteps = AudioStreamPlayer.new()
	add_child(footsteps)
	footsteps.stream = load("res://assets/audio/step.wav")
	footsteps.volume_db = -16.0


func set_controls_enabled(value: bool) -> void:
	controls_enabled = value
	set_physics_process(value)
	if not value:
		velocity = Vector3.ZERO


func grant_protection(seconds: float) -> void:
	tempo_invulneravel = maxf(tempo_invulneravel, seconds)
	invulneravel = true

func _unhandled_input(event: InputEvent) -> void:
	if vidas <= 0 or not controls_enabled:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_F and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			flashlight.visible = not flashlight.visible
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotation.x = clampf(head.rotation.x - event.relative.y * mouse_sensitivity, -1.4, 1.4)

func _physics_process(delta: float) -> void:
	tempo_invulneravel = maxf(tempo_invulneravel - delta, 0.0)
	invulneravel = tempo_invulneravel > 0.0
	if carried:
		velocity = Vector3.ZERO
		return
	var input_direction := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := transform.basis * Vector3(input_direction.x, 0, input_direction.y)
	if stamina >= 25.0:
		sprint_locked = false
	var sprinting := Input.is_action_pressed("sprint") and input_direction.length() > 0.1 and not sprint_locked and stamina > 0.0
	var speed := sprint_speed * (1.18 if upgrades.has("shoes") else 1.0) if sprinting else walk_speed
	if sprinting:
		stamina = maxf(0.0, stamina - delta * 20.0)
		stamina_delay = 0.4 if upgrades.has("lungs") else 0.9
		if stamina == 0.0:
			sprint_locked = true
	else:
		stamina_delay = maxf(0.0, stamina_delay - delta)
		if stamina_delay <= 0.0:
			stamina = minf(100.0, stamina + delta * (34.0 if upgrades.has("lungs") else 20.0))
	var camera: Camera3D = $Head/Camera3D
	camera.fov = lerpf(camera.fov, 82.0 if sprinting else 75.0, minf(delta * 6.0, 1.0))
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0
	move_and_slide()
	if is_on_floor() and Vector2(velocity.x, velocity.z).length() > 0.2:
		footstep_time -= delta
		if footstep_time <= 0:
			footsteps.pitch_scale = randf_range(1.0, 1.15)
			footsteps.play()
			footstep_time = 0.3 if sprinting else 0.48

func tomar_dano() -> bool:
	if invulneravel or carried or vidas <= 0 or not controls_enabled:
		return false

	vidas -= 1
	grant_protection(2.0)
	vidas_alteradas.emit(vidas)

	if vidas == 0:
		velocity = Vector3.ZERO
		set_physics_process(false)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		morreu.emit()
	return true
