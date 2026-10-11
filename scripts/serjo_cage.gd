extends Node3D

var unlocked: bool = false
var freed: bool = false
var door: Node3D
var prisoner: Node3D
var sign_label: Label3D
var door_body: StaticBody3D


func _ready() -> void:
	var metal := StandardMaterial3D.new()
	metal.albedo_color = Color(0.25, 0.29, 0.32)
	metal.metallic = 0.8
	metal.roughness = 0.4
	# Paredes laterais e fundo: barras visíveis, colisão contínua.
	for side in [-1.0, 1.0]:
		for z in [-0.85, -0.425, 0.0, 0.425, 0.85]:
			_box(self, Vector3(side, 1.05, z), Vector3(0.07, 2.1, 0.07), metal)
		_solid(self, Vector3(side, 1.05, 0), Vector3(0.08, 2.1, 1.8))
	for x in [-1.0, -0.6, -0.2, 0.2, 0.6, 1.0]:
		_box(self, Vector3(x, 1.05, 0.85), Vector3(0.07, 2.1, 0.07), metal)
	_solid(self, Vector3(0, 1.05, 0.85), Vector3(2.0, 2.1, 0.08))
	for y in [0.05, 2.1]:
		_box(self, Vector3(0, y, 0), Vector3(2.1, 0.07, 1.8), metal)
	door = Node3D.new()
	door.name = "Door"
	add_child(door)
	door.position = Vector3(-1, 0, -0.85)
	for x in [0.0, 0.4, 0.8, 1.2, 1.6, 2.0]:
		_box(door, Vector3(x, 1.05, 0), Vector3(0.07, 2.1, 0.07), metal)
	door_body = _solid(door, Vector3(1, 1.05, 0), Vector3(2.0, 2.1, 0.08))
	prisoner = Node3D.new()
	prisoner.name = "Prisoner"
	add_child(prisoner)
	var clothes := StandardMaterial3D.new()
	clothes.albedo_color = Color(0.95, 0.4, 0.12)
	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = 0.25
	body_mesh.height = 1.2
	var body := MeshInstance3D.new()
	prisoner.add_child(body)
	body.mesh = body_mesh
	body.material_override = clothes
	body.position.y = 0.75
	var skin := StandardMaterial3D.new()
	skin.albedo_color = Color(0.65, 0.43, 0.3)
	var head := MeshInstance3D.new()
	prisoner.add_child(head)
	var sphere := SphereMesh.new()
	sphere.radius = 0.2
	sphere.height = 0.4
	head.mesh = sphere
	head.material_override = skin
	head.position.y = 1.5
	var eyes := StandardMaterial3D.new()
	eyes.albedo_color = Color(0.02, 0.015, 0.01)
	for x in [-0.065, 0.065]:
		_box(prisoner, Vector3(x, 1.53, -0.19), Vector3(0.035, 0.05, 0.02), eyes)
	_box(prisoner, Vector3(0, 1.43, -0.19), Vector3(0.08, 0.018, 0.02), eyes)
	sign_label = Label3D.new()
	add_child(sign_label)
	sign_label.position = Vector3(0, 2.45, -0.9)
	sign_label.font_size = 46
	sign_label.pixel_size = 0.008
	sign_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign_label.text = "SERJO • PRECISA DE 7 BOLAS"
	var light := OmniLight3D.new()
	add_child(light)
	light.position = Vector3(0, 2.3, -0.7)
	light.light_color = Color(0.2, 0.8, 0.55)
	light.light_energy = 1.2
	light.omni_range = 4.0


func _box(parent: Node, at: Vector3, dimensions: Vector3, material: Material) -> void:
	var mesh := MeshInstance3D.new()
	parent.add_child(mesh)
	mesh.position = at
	var box := BoxMesh.new()
	box.size = dimensions
	mesh.mesh = box
	mesh.material_override = material


func _solid(parent: Node, at: Vector3, dimensions: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	parent.add_child(body)
	body.position = at
	var collision := CollisionShape3D.new()
	body.add_child(collision)
	var shape := BoxShape3D.new()
	shape.size = dimensions
	collision.shape = shape
	# Geometria simples usada pelo gerador de navegação, sem aparecer no jogo.
	var source := MeshInstance3D.new()
	body.add_child(source)
	var box := BoxMesh.new()
	box.size = dimensions
	source.mesh = box
	source.visible = false
	return body


func is_near(player_position: Vector3) -> bool:
	var entrance := global_position + Vector3(0, 0, -1.4)
	var difference := player_position - entrance
	difference.y = 0.0
	return difference.length() <= 2.0


func set_unlocked(value: bool) -> void:
	unlocked = value
	sign_label.text = "SERJO • PODE LIBERTAR!" if unlocked else "SERJO • PRECISA DE 7 BOLAS"
	sign_label.modulate = Color(0.45, 1, 0.6) if unlocked else Color.WHITE


func rescue() -> void:
	if freed:
		return
	freed = true
	door_body.get_child(0).set_deferred("disabled", true)
	var tween := create_tween()
	tween.tween_property(door, "rotation:y", -1.65, 0.6)
	tween.tween_property(prisoner, "position:z", -1.7, 0.7)
	sign_label.text = "SERJO LIBERTO!"
