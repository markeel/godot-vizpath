extends RefCounted
class_name VizSimpleLeg

var _error : String = ""
var _begin : VisualizationSpot
var _end : VisualizationSpot
var _width : float
var _bend_lip : float
var _bend : VizBend

var tri_mat : Material = load("res://example/common/materials/white.tres")
var bend_mat : Material = load("res://example/common/materials/red.tres")

const MIN_SEGMENT_LENGTH=0.01
const EPSILON=0.00001

func _init(p_begin : VisualizationSpot, p_end : VisualizationSpot, p_width : float, p_bend_lip : float):
	_begin = p_begin
	_end = p_end
	_width = p_width
	_bend_lip = p_bend_lip
	if not _has_valid_normal():
		return
	if _is_straight():
		return
	_bend = VizBend.new(_begin, _end, p_width, p_bend_lip)
	if not _bend.is_invalid():
		_check_offsets(_begin, _end)

# ---------------------------------------------
# Public Methods

func get_error() -> String:
	if _error != "":
		return _error
	if _bend != null:
		return _bend.get_error()
	return ""

func is_invalid() -> bool:
	if _error != "":
		return true
	if _bend != null:
		return _bend.is_invalid()
	return false

func extend_mesh(mesh_node : Node3D, u : float, left : Vector3, right : Vector3, segs : int, sharpness : float, mat : Material) -> float:
	if _bend == null:
		u = _extend_straight_leg(mesh_node, u, left, right, _begin.point, _end.point, _begin.normal, mat)
	else:
		u = _extend_straight_leg(mesh_node, u, left, right, _begin.point, _bend.get_begin(), _begin.normal, mat)
		if _bend.is_angled():
			u = _create_begin_triangle(mesh_node, u, _begin.normal, _bend.get_begin_triangle(), mat)
		u = _create_bend(mesh_node, u, segs, sharpness, mat)
		if _bend.is_angled():
			u = _create_end_triangle(mesh_node, u, _end.normal, _bend.get_end_triangle(), mat)
		u = _create_straight_leg(mesh_node, u, _bend.get_end(), _end.point, _end.normal, mat)
	return u

func update_mesh(mesh_node : Node3D, u : float, segs : int, sharpness : float, mat : Material) -> float:
	if _bend == null:
		u = _create_straight_leg(mesh_node, u, _begin.point, _end.point, _begin.normal, mat)
	else:
		u = _create_straight_leg(mesh_node, u, _begin.point, _bend.get_begin(), _begin.normal, mat)
		if _bend.is_angled():
			u = _create_begin_triangle(mesh_node, u, _begin.normal, _bend.get_begin_triangle(), mat)
		u = _create_bend(mesh_node, u, segs, sharpness, mat)
		if _bend.is_angled():
			u = _create_end_triangle(mesh_node, u, _end.normal, _bend.get_end_triangle(), mat)
		u = _create_straight_leg(mesh_node, u, _bend.get_end(), _end.point, _end.normal, mat)
	return u

func get_begin() -> VisualizationSpot:
	return _begin

func get_leg_bend_begin() -> Vector3:
	if _bend == null:
		return (_end.point - _begin.point)/2.0
	return _bend.get_begin_triangle().get_leg_mid()

func get_begin_ray() -> Vector3:
	if _bend == null:
		return (_end.point - _begin.point).normalized()
	return (_bend.get_begin() - _begin.point).normalized()

func adjust_begin(distance : float):
	var new_begin := VisualizationSpot.new()
	new_begin.point = _begin.point + distance * get_begin_ray()
	new_begin.normal = _begin.normal
	if _check_offsets(new_begin, _end):
		_begin = new_begin

func get_end() -> VisualizationSpot:
	return _end
	
func get_leg_bend_end() -> Vector3:
	if _bend == null:
		return (_end.point - _begin.point)/2.0
	return _bend.get_end_triangle().get_leg_mid()
	
func get_end_left() -> Vector3:
	var segment := _end.point - get_leg_bend_end()
	var binormal := segment.cross(_end.normal).normalized()
	var half_width = binormal*_width/2.0
	return _end.point - half_width

func get_end_right() -> Vector3:
	var segment := _end.point - get_leg_bend_end()
	var binormal := segment.cross(_end.normal).normalized()
	var half_width = binormal*_width/2.0
	return _end.point + half_width

func get_end_ray() -> Vector3:
	if _bend == null:
		return (_end.point - _begin.point).normalized()
	return (_end.point - _bend.get_end()).normalized()

func adjust_end(distance : float):
	var new_end := VisualizationSpot.new()
	new_end.point = _end.point - distance * get_end_ray()
	new_end.normal = _end.normal
	if _check_offsets(_begin, new_end):
		_end = new_end

# ---------------------------------------------
# Local Methods

func _check_offsets(p_begin : VisualizationSpot, p_end : VisualizationSpot) -> bool:
	var dir := (_end.point - _begin.point).normalized()
	var min_len := MIN_SEGMENT_LENGTH + EPSILON
	var max_begin := _end.point - dir * min_len
	var max_end := _begin.point + dir * min_len
	if _bend != null:
		max_begin = _bend.get_begin() - dir * min_len
		max_end = _bend.get_end() + dir * min_len
	var new_begin_dir := (max_begin - p_begin.point).normalized()
	var new_end_dir := (p_end.point - max_end).normalized()
	if new_begin_dir.dot(dir) <= 0.0:
		_error = "bend start %s is too near %s to be bent with this width and lip" % [ _begin.point, _end.point ]
		return false
	if new_end_dir.dot(dir) <= 0.0:
		_error = "bend end %s is too near %s to be bent with this width and lip" % [ _end.point, _begin.point ]
		return false
	return true

func _has_valid_normal() -> bool:
	var segment = _end.point - _begin.point
	var binormal = segment.cross(_begin.normal).normalized()
	if not binormal.is_normalized():
		_error = "%s to %s is parallel to normal %s" % [ _begin.point, _end.point, _begin.normal ]
		return false
	return true

func _is_straight() -> bool:
	if _begin.normal.is_equal_approx(_end.normal):
		var segment = _end.point - _begin.point
		if is_equal_approx(segment.dot(_begin.normal), 0.0):
			return true
		_error = "%s to %s have same normal but are not in same plane" % [ _begin.point, _end.point ]
	return false

func _extend_straight_leg(mesh_node : Node3D, u : float, left : Vector3, right : Vector3, begin : Vector3, end : Vector3, normal : Vector3, mat : Material):
	var segment := end - begin
	var binormal := segment.cross(normal).normalized()
	var half_width = binormal*_width/2.0
	var seg := begin - end
	var seg_len := seg.length()

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	st.set_color(Color(1, 0, 0))
	st.set_normal(normal)

	st.set_uv(Vector2(u, 1))
	st.add_vertex(right)

	st.set_uv(Vector2(u, 0))
	st.add_vertex(left)

	st.set_uv(Vector2(u+seg_len, 1))
	st.add_vertex(end+half_width)

	st.set_uv(Vector2(u+seg_len, 0))
	st.add_vertex(end-half_width)

	st.set_material(mat)
	mesh_node.mesh = st.commit(mesh_node.mesh)

	return u + seg_len

func _create_straight_leg(mesh_node : Node3D, u : float, begin : Vector3, end : Vector3, normal : Vector3, mat : Material):
	var segment := end - begin
	var binormal := segment.cross(normal).normalized()
	var half_width = binormal*_width/2.0
	var seg := begin - end
	var seg_len := seg.length()

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	st.set_color(Color(1, 0, 0))
	st.set_normal(normal)

	st.set_uv(Vector2(u, 1))
	st.add_vertex(begin+half_width)

	st.set_uv(Vector2(u, 0))
	st.add_vertex(begin-half_width)

	st.set_uv(Vector2(u+seg_len, 1))
	st.add_vertex(end+half_width)

	st.set_uv(Vector2(u+seg_len, 0))
	st.add_vertex(end-half_width)

	st.set_material(mat)
	mesh_node.mesh = st.commit(mesh_node.mesh)

	return u + seg_len

func _create_begin_triangle(mesh_node : Node3D, u : float, normal : Vector3, triangle : VizTriangle, mat : Material):
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_color(Color(1, 0, 0))
	st.set_normal(normal)

	st.set_uv(Vector2(u, 0))
	st.add_vertex(triangle.leg_left)
	st.set_uv(Vector2(u + triangle.distance, triangle.get_fwd_side()))
	st.add_vertex(triangle.leg_fwd)
	st.set_uv(Vector2(u, 1))
	st.add_vertex(triangle.leg_right)
	st.set_material(mat)
	mesh_node.mesh = st.commit(mesh_node.mesh)
	return u + triangle.distance

func _create_end_triangle(mesh_node : Node3D, u : float, normal : Vector3, triangle : VizTriangle, mat : Material):
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_color(Color(1, 0, 0))
	st.set_normal(normal)

	st.set_uv(Vector2(u + triangle.distance, 0))
	st.add_vertex(triangle.leg_left)
	st.set_uv(Vector2(u + triangle.distance, 1))
	st.add_vertex(triangle.leg_right)
	st.set_uv(Vector2(u, triangle.get_fwd_side()))
	st.add_vertex(triangle.leg_fwd)
	st.set_material(mat)
	mesh_node.mesh = st.commit(mesh_node.mesh)
	return u + triangle.distance

func _create_bend(mesh_node : Node3D, u : float, segs : int, sharpness : float, mat : Material):
	var right_u := u - _bend.get_begin_triangle().distance
	var left_u := u
	if _bend.is_angled_against_curve():
		right_u = u
		left_u = u - _bend.get_begin_triangle().distance
	var arc_len := 0.0

	var segment := _bend.get_begin() - _begin.point 
	var binormal := segment.cross(_begin.normal).normalized()
	var half_width = _bend.get_half_bend_width()
	var half_width_normal := half_width.normalized()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	st.set_normal(_begin.normal)
	st.set_uv(Vector2(right_u, 1))
	st.add_vertex(_bend.get_begin_triangle().bend_right)
	st.set_uv(Vector2(left_u, 0))
	st.add_vertex(_bend.get_begin_triangle().bend_left)
	var shift_width := _bend.get_shift_width()
	var last_point := _bend.get_arc_begin_point()
	var total_len := 0.0
	for i in range(0, segs):
		var weight := float(i) / float(segs-1)
		var cur_point := _bend.get_arc_point(weight, sharpness)
		total_len += cur_point.distance_to(last_point)
		last_point = cur_point
	total_len += _bend.get_arc_end_point().distance_to(last_point)
	last_point = _bend.get_arc_begin_point()
	for i in range(1, segs-1):
		var weight := float(i) / float(segs-1)
		var cur_point := _bend.get_arc_point(weight, sharpness)
		arc_len += cur_point.distance_to(last_point)
		var shift := shift_width * (arc_len / total_len)
		var pos := cur_point + shift - _bend.get_shift_offset()
		var cur_normal := Vector3(cur_point - last_point).normalized().cross(half_width_normal)
		last_point = cur_point
		st.set_normal(cur_normal)
		st.set_uv(Vector2(right_u + arc_len, 1))
		st.add_vertex(pos-half_width)
		st.set_uv(Vector2(left_u + arc_len, 0))
		st.add_vertex(pos+half_width)
	st.set_normal(_end.normal)
	st.set_uv(Vector2(right_u + total_len, 1))
	st.add_vertex(_bend.get_end_triangle().bend_right)
	st.set_uv(Vector2(left_u + total_len, 0))
	st.add_vertex(_bend.get_end_triangle().bend_left)
	st.set_material(mat)
	mesh_node.mesh = st.commit(mesh_node.mesh)
	u = right_u + total_len
	if _bend.is_angled_against_curve():
		u = left_u + total_len
	return u

func _to_string():
	if _bend != null:
		return "SLEG(%s->%s through %s)" % [ _begin, _end, _bend ]
	return "SLEG(%s->%s)" % [ _begin, _end ]

