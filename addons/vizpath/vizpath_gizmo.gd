extends EditorNode3DGizmo

func _redraw():
	clear()
	var path := get_node_3d() as VisualizedPath
	if not path.changed_layout.is_connected(_redraw):
		path.changed_layout.connect(_redraw)

	var lines = PackedVector3Array()
	for i in range(path.spots.size()):
		lines.push_back(path.spots[i].point)
		lines.push_back(path.spots[i].point + path.spots[i].normal * path.path_width * 2.0)

	var line_material = get_plugin().get_material("line", self)
	add_lines(lines, line_material, false)
	
	for i in range(path.spots.size()):
		var rotation := Quaternion(Vector3.FORWARD, path.spots[i].normal)
		var basis := Basis(rotation)
		basis = basis.scaled(Vector3(path.path_width,path.path_width,path.path_width))
		var transform := Transform3D(basis, path.spots[i].point)
		add_mesh(get_plugin().spot_mesh, line_material, transform)
	
	var triangle_mesh := path.get_triangle_mesh()
	if triangle_mesh != null:
		add_collision_triangles(triangle_mesh)

func _subgizmos_intersect_frustum(camera : Camera3D, frustrum : Array[Plane]) -> PackedInt32Array:
	var path := get_node_3d() as VisualizedPath
	var gizmos := PackedInt32Array()
	for i in range(path.spots.size()):
		var origin := path.global_transform * path.spots[i].point
		var any_out := false
		for plane in frustrum:
			if plane.is_point_over(origin):
				any_out = true
		if not any_out:
			gizmos.push_back(i)
	return gizmos
	
func _subgizmos_intersect_ray(camera : Camera3D, point : Vector2) -> int:
	var path := get_node_3d() as VisualizedPath
	for i in range(path.spots.size()):
		var origin := path.global_transform * path.spots[i].point
		var p := camera.unproject_position(origin)
		if p.distance_to(point) < 20:
			return i
	return -1

func _get_subgizmo_transform(id : int) -> Transform3D:
	var path := get_node_3d() as VisualizedPath
	var rotation := Quaternion(Vector3.FORWARD, path.spots[id].normal)
	var basis := Basis(rotation)
	var transform := Transform3D(basis, path.spots[id].point)
	return transform

func _set_subgizmo_transform(id : int, transform : Transform3D):
	var path := get_node_3d() as VisualizedPath
	path.spots[id].point = transform.origin
	path.spots[id].normal = transform.basis * Vector3.FORWARD

func _commit_subgizmos( ids : PackedInt32Array, restores : Array[Transform3D], cancel : bool):
	var path := get_node_3d() as VisualizedPath
	if cancel:
		for idx in range(ids.size()):
			var spot := path.spots[ids[idx]]
			spot.point = restores[idx].origin
			spot.normal = restores[idx].basis * Vector3.FORWARD
	else:
		var vizpath_gizmo_plugin := get_plugin() as EditorNode3DGizmoPlugin
		var undo_redo = vizpath_gizmo_plugin.editor_plugin.get_undo_redo()
		undo_redo.create_action("Modify spots")
		for idx in range(ids.size()):
			var spot := path.spots[ids[idx]]
			undo_redo.add_do_property(spot, "point", spot.point)
			undo_redo.add_undo_property(spot, "point", restores[idx].origin)
			undo_redo.add_do_property(spot, "normal", spot.normal)
			undo_redo.add_undo_property(spot, "normal", restores[idx].basis * Vector3.FORWARD)
		undo_redo.commit_action()

