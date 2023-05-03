extends RefCounted
class_name VizMid

var _seg1 : VizSegment
var _seg2 : VizSegment
var _width : float
var _inner_radius : float

var _rotation_point : VisualizationSpot
var _angle : float
var _error : String

func _init(p_seg1 : VizSegment, p_seg2 : VizSegment, p_stroke_width : float, p_inner_radius : float):
	_seg1 = p_seg1
	_seg2 = p_seg2
	_width = p_stroke_width
	_inner_radius = p_inner_radius
	assert(p_seg1.get_end().is_equal(p_seg2.get_begin()))
	_calc_rotation_point()
	var center_distance := calc_center_distance(p_stroke_width, p_inner_radius)
	var turn_distance := calc_turn_distance(center_distance, _angle)
	p_seg1.adjust_end(turn_distance)
	if p_seg1.is_invalid():
		return
	p_seg2.adjust_begin(turn_distance)
	if p_seg2.is_invalid():
		return

# ---------------------------------------------
# Public Methoeds

func is_invalid() -> bool:
	return _error != ""

func get_error() -> String:
	return _error

func update_mesh(_mesh_instance : MeshInstance3D, u : float, num_segs : int, mat : Material):
	return _create_fan(_mesh_instance, u, num_segs, mat)

# ---------------------------------------------
# Private Methods

func _calc_rotation_point():
	var seg1_ray := _seg1.get_end_ray()
	var seg2_ray := _seg2.get_begin_ray()
	_angle = seg1_ray.angle_to(seg2_ray)
	var join_point := _seg1.get_end()
	var plane_normal := seg1_ray.cross(seg2_ray).normalized()
	if plane_normal == Vector3.ZERO:
		plane_normal = join_point.normal
	var binormal = plane_normal.cross(seg1_ray).normalized()
	var d := calc_center_distance(_width, _inner_radius)
	var e := calc_turn_distance(d, _angle)
	_rotation_point = VisualizationSpot.new()
	_rotation_point.point = join_point.point - e * seg1_ray + d * binormal
	_rotation_point.normal = plane_normal

func _create_fan(mesh_node : Node3D, u : float, num_segs : int, mat : Material) -> float:
	var radius := _width/2.0 + _inner_radius
	var arc_len := absf(_angle) * radius
	
	var begin_half_width := _seg1.get_end_binormal() * _width/2.0
	var end_half_width := _seg2.get_begin_binormal() * _width/2.0

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	st.set_color(Color(1, 0, 0))
	st.set_normal(_seg1.get_end().normal)
	
	st.set_uv(Vector2(u, 1))
	st.add_vertex(_seg1.get_end().point + begin_half_width)
	st.set_uv(Vector2(u, 0))
	st.add_vertex(_seg1.get_end().point - begin_half_width)

	var outer_base := _seg1.get_end().point + begin_half_width - _rotation_point.point
	var inner_base := _seg1.get_end().point - begin_half_width - _rotation_point.point
	for i in range(1, num_segs-1):
		var cur_angle : float = _angle * float(i) / float(num_segs-1)
		var cur_arc_len = absf(cur_angle) * radius
		var inner := _rotation_point.point + inner_base.rotated(_rotation_point.normal, cur_angle)
		var outer := _rotation_point.point + outer_base.rotated(_rotation_point.normal, cur_angle)
		st.set_uv(Vector2(u+cur_arc_len, 1))
		st.add_vertex(outer)
		st.set_uv(Vector2(u+cur_arc_len, 0))
		st.add_vertex(inner)

	st.set_uv(Vector2(u+arc_len, 1))
	st.add_vertex(_seg2.get_begin().point + end_half_width)
	st.set_uv(Vector2(u+arc_len, 0))
	st.add_vertex(_seg2.get_begin().point - end_half_width)

	st.set_material(mat)
	mesh_node.mesh = st.commit(mesh_node.mesh)
	
	return u + arc_len

static func calc_center_distance(stroke_width : float, inner_radius : float) -> float:
	return stroke_width / 2.0 + inner_radius

static func calc_turn_distance(center_distance : float, angle : float) -> float:
	return center_distance * tan(abs(angle)/2.0)
