extends SceneTree

# Rode com: godot --headless --path . --script res://tools/bake_nav.gd
# Atualize a malha sempre que a geometria do labirinto mudar.
func _initialize() -> void:
	call_deferred("bake")

func bake() -> void:
	var scene := load("res://scenes/main.tscn") as PackedScene
	var root := scene.instantiate() as Node3D
	root.set_script(null)
	for child in root.get_children():
		if child.name not in ["Floor", "Serjo"] and not (child is CSGBox3D and child.name != "Ceiling"):
			root.remove_child(child)
			child.free()
	get_root().add_child(root)
	await process_frame
	await process_frame
	# A cela gera suas barras e colisões ao entrar na árvore.
	root.get_node("Serjo/Prisoner").free()
	for mesh in root.get_node("Serjo").find_children("*", "MeshInstance3D", true, false):
		mesh.visible = true
	var nav := NavigationMesh.new()
	nav.agent_height = 1.8
	nav.agent_radius = 0.35
	nav.agent_max_climb = 0.4
	nav.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_MESH_INSTANCES
	var geometry := NavigationMeshSourceGeometryData3D.new()
	NavigationServer3D.parse_source_geometry_data(nav, geometry, root)
	NavigationServer3D.bake_from_source_geometry_data(nav, geometry)
	print("Vertices: ", nav.vertices.size(), ", poligonos: ", nav.get_polygon_count())
	if nav.get_polygon_count() == 0:
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute("res://navigation")
	var error := ResourceSaver.save(nav, "res://navigation/labyrinth_navmesh.tres")
	quit(error)
