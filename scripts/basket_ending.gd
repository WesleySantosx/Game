extends Node3D

var elapsed: float = 0.0
var ball: MeshInstance3D
var start := Vector3(-1.1, 1.55, 0.2)
var basket := Vector3(1.6, 2.3, 0)


func _ready() -> void:
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color(0.18, 0.1, 0.055)
	_box(Vector3(0, -0.05, 0), Vector3(8, 0.1, 7), floor_material)
	var board_material := StandardMaterial3D.new()
	board_material.albedo_color = Color(0.85, 0.9, 0.95)
	_box(Vector3(1.6, 2.65, -0.35), Vector3(1.1, 0.75, 0.08), board_material)
	var metal := StandardMaterial3D.new()
	metal.albedo_color = Color(0.2, 0.22, 0.25)
	_box(Vector3(1.6, 1.3, -0.6), Vector3(0.1, 2.6, 0.1), metal)
	var orange := StandardMaterial3D.new()
	orange.albedo_color = Color(1, 0.32, 0.03)
	var rim := MeshInstance3D.new()
	add_child(rim)
	var torus := TorusMesh.new()
	torus.inner_radius = 0.23
	torus.outer_radius = 0.28
	rim.mesh = torus
	rim.material_override = orange
	rim.position = basket
	ball = MeshInstance3D.new()
	add_child(ball)
	var sphere := SphereMesh.new()
	sphere.radius = 0.19
	sphere.height = 0.38
	ball.mesh = sphere
	var basketball_material := ShaderMaterial.new()
	basketball_material.shader = load("res://assets/basketball.gdshader")
	ball.material_override = basketball_material
	ball.position = start
	var josias := (load("res://scenes/josias.tscn") as PackedScene).instantiate() as Node3D
	add_child(josias)
	josias.position = Vector3(-1.6, 0, 0.2)
	josias.rotation.y = PI / 2.0
	var camera := Camera3D.new()
	add_child(camera)
	camera.position = Vector3(3.8, 2.5, 6)
	camera.look_at(Vector3(0, 1.4, 0), Vector3.UP)
	camera.current = true
	var light := OmniLight3D.new()
	add_child(light)
	light.position = Vector3(0, 4, 2)
	light.light_energy = 3
	light.omni_range = 12
	light.light_color = Color(1, 0.8, 0.55)
	var caption := Label3D.new()
	add_child(caption)
	caption.text = "VIU AI FESO!"
	caption.position = Vector3(-1.4, 2.4, 0)
	caption.font_size = 55
	caption.pixel_size = 0.008
	caption.billboard = BaseMaterial3D.BILLBOARD_ENABLED


func _box(at: Vector3, dimensions: Vector3, material: Material) -> void:
	var mesh := MeshInstance3D.new()
	add_child(mesh)
	mesh.position = at
	var box := BoxMesh.new()
	box.size = dimensions
	mesh.mesh = box
	mesh.material_override = material


func _process(delta: float) -> void:
	elapsed += delta
	if elapsed < 0.6:
		return
	if elapsed < 1.8:
		var progress := (elapsed - 0.6) / 1.2
		ball.position = start.lerp(basket, progress) + Vector3.UP * sin(progress * PI) * 1.2
	else:
		var fall := minf(elapsed - 1.8, 0.7)
		ball.position = basket + Vector3.DOWN * minf(2.1, 4.3 * fall * fall)
	ball.rotate_x(delta * 4)
