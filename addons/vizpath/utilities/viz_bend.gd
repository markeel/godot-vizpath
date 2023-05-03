extends RefCounted
class_name VizBend

var _error : String

var _bend_normal : Vector3
var _bend_plane : Plane
var _begin_on_bend_plane : Vector3
var _end_on_bend_plane : Vector3
var _intersect_data : OptVector3

var _plane_join_point : Vector3

var _bend_side : float
var _curve_side : float

var _bend_begin_triangle : VizTriangle
var _bend_end_triangle : VizTriangle

var _arc_begin_mid : Vector3
var _arc_end_mid : Vector3

var _begin : Vector3
var _begin_dir : Vector3
var _end : Vector3
var _end_dir : Vector3

class OptVector3:
	var vector : Vector3
	func _init(p_data : Vector3):
		vector = p_data

func _init(p_begin : VisualizationSpot, p_end : VisualizationSpot, p_width : float, p_bend_lip : float):
	if not _is_bendable(p_begin, p_end):
		return
	
	_calc_bend_normal(p_begin, p_end)
	if not _calc_intersection_point(p_begin, p_end):
		return
	_calc_join_point(p_begin, p_end)
	_calc_bend_side(p_begin, p_end)
	_calc_triangles(p_begin, p_end, p_width, p_bend_lip)
	_calc_arc_plane()
	_begin = _bend_begin_triangle.get_leg_mid()
	if not _is_in_order(p_begin.point, _begin, _plane_join_point):
		_error = "bend point is too close to beginning for %s to %s with lip %s" % [p_begin.point, p_end.point, p_bend_lip]
		return
	_end = _bend_end_triangle.get_leg_mid()
	if not _is_in_order(_plane_join_point, _end, p_end.point):
		_error = "bend point is too close to end for %s to %s with lip %s" % [p_begin.point, p_end.point, p_bend_lip]
		return

func _to_string():
	return "%s->%s->%s" % [_begin, _plane_join_point, _end]

# ---------------------------------------------
# Public Methoeds

func get_error() -> String:
	return _error

func is_invalid() -> bool:
	if _error != "":
		return true
	return false

func get_begin() -> Vector3:
	return _begin

func get_end() -> Vector3:
	return _end

func is_angled() -> bool:
	return not is_zero_approx(_bend_side)

func is_angled_against_curve() -> bool:
	if _bend_side * _curve_side < 0:
		return true
	return false

func get_half_leg_width() -> Vector3:
	return (_bend_begin_triangle.leg_left - _bend_begin_triangle.leg_right) / 2.0

func get_half_bend_width() -> Vector3:
	return (_bend_begin_triangle.bend_left - _bend_begin_triangle.bend_right) / 2.0

func get_begin_triangle() -> VizTriangle:
	return _bend_begin_triangle

func get_end_triangle() -> VizTriangle:
	return _bend_end_triangle
	
func get_shift_width() -> Vector3:
	return _arc_begin_mid - _bend_begin_triangle.get_bend_mid() + _bend_end_triangle.get_bend_mid() - _arc_end_mid

func get_shift_offset() -> Vector3:	
	return _arc_begin_mid - _bend_begin_triangle.get_bend_mid()

func get_arc_begin_point() -> Vector3:
	return _arc_begin_mid

func get_arc_end_point() -> Vector3:
	return _arc_end_mid

func get_arc_point(weight : float, sharpness : float) -> Vector3:
	return _curve_point(_arc_begin_mid, _plane_join_point, _arc_end_mid, weight, sharpness)

# ---------------------------------------------
# Private Methods

func _curve_point(p0 : Vector3, p1 : Vector3, p2 : Vector3, t : float, s : float) -> Vector3:
	var p := p1 + pow(1-t, 2.0) * s * (p0-p1) + pow(t, 2.0) * s * (p2-p1)
	return p

func _is_in_order(b : Vector3, m : Vector3, e : Vector3) -> bool:
	return (e-m).normalized().dot((m-b).normalized()) > 0

func _is_bendable(p_begin : VisualizationSpot, p_end : VisualizationSpot) -> bool:
	var dir := (p_end.point - p_begin.point).normalized()
	var begin_norm_sign := signf(dir.dot(p_begin.normal))
	var end_norm_sign := signf(dir.dot(p_end.normal))
	if begin_norm_sign == end_norm_sign:
		_error = "%s cannot be twisted into %s" % [ p_begin.normal, p_end.normal ]
		return false
	_curve_side = end_norm_sign
	return true

func _calc_bend_normal(p_begin : VisualizationSpot, p_end : VisualizationSpot):
	var middle = p_begin.point + (p_end.point - p_begin.point) / 2.0
	_bend_normal = p_begin.normal.cross(p_end.normal).normalized()
	_bend_plane = Plane(_bend_normal, middle)

func _calc_intersection_point(p_begin : VisualizationSpot, p_end : VisualizationSpot) -> bool:
	_begin_on_bend_plane = _bend_plane.project(p_begin.point)
	_end_on_bend_plane = _bend_plane.project(p_end.point)
	var dir := _end_on_bend_plane - _begin_on_bend_plane
	var begin_normal_on_bend_plane := _bend_plane.project(p_begin.point + p_begin.normal) - _begin_on_bend_plane
	var end_normal_on_bend_plane := _bend_plane.project(p_end.point + p_end.normal) - _end_on_bend_plane
	var begin_bend_binormal := begin_normal_on_bend_plane.cross(dir)
	var begin_bend_tangent := begin_bend_binormal.cross(begin_normal_on_bend_plane).normalized()
	var end_bend_binormal := end_normal_on_bend_plane.cross(dir)
	var end_bend_tangent := end_bend_binormal.cross(end_normal_on_bend_plane).normalized()
	_intersect_data = _intersect(_begin_on_bend_plane, begin_bend_tangent, _end_on_bend_plane, end_bend_tangent, _bend_normal)
	if _intersect_data == null:
		_error = "intersection failed unexpectedly: normal %s at %s is parallel with normal %s at %s" % [ begin_normal_on_bend_plane, _begin_on_bend_plane, end_normal_on_bend_plane, _end_on_bend_plane ]
		return false
	return true

func _calc_join_point(p_begin : VisualizationSpot, p_end : VisualizationSpot):
	var begin_bend_from_intersect := p_begin.point + _intersect_data.vector - _begin_on_bend_plane
	var end_bend_from_intersect := p_end.point + _intersect_data.vector - _end_on_bend_plane
	var begin_intersect_distance := begin_bend_from_intersect.distance_to(p_begin.point)
	var end_intersect_distance := end_bend_from_intersect.distance_to(p_end.point)
	var begin_to_end_on_bend_distance := end_bend_from_intersect.distance_to(begin_bend_from_intersect)
	var begin_to_end_intersect_join_numerator := begin_to_end_on_bend_distance * begin_intersect_distance / end_intersect_distance
	var begin_to_end_intersect_join_denominator := 1.0 + begin_intersect_distance / end_intersect_distance
	var begin_on_end_intersect_join_distance := begin_to_end_intersect_join_numerator / begin_to_end_intersect_join_denominator
	var begin_bend_dir := begin_bend_from_intersect - p_begin.point
	var end_bend_dir := end_bend_from_intersect - p_begin.point
	var begin_to_end_normal := begin_bend_dir.cross(end_bend_dir)
	var begin_to_end_binormal := begin_to_end_normal.cross(_bend_normal)
	var begin_on_end_intersect_side = signf(end_bend_dir.dot(begin_to_end_binormal))
	_plane_join_point = begin_bend_from_intersect - begin_on_end_intersect_side * begin_on_end_intersect_join_distance * _bend_normal

func _calc_bend_side(p_begin : VisualizationSpot, p_end : VisualizationSpot):
	_begin_dir = Vector3(_plane_join_point - p_begin.point).normalized()
	_end_dir = Vector3(p_end.point - _plane_join_point).normalized()
	_bend_side = signf(_bend_normal.dot(_end_dir))

func _calc_triangles(p_begin : VisualizationSpot, p_end : VisualizationSpot, p_width : float, p_bend_lip : float):
	var begin_binormal := _begin_dir.cross(p_begin.normal).normalized()
	var end_binormal := _end_dir.cross(p_end.normal).normalized()
	_bend_begin_triangle = VizTriangle.new()
	_bend_begin_triangle.update(_begin_dir, _plane_join_point, begin_binormal, p_width, p_bend_lip, _bend_normal, _bend_side, _curve_side)
	_bend_end_triangle = VizTriangle.new()
	_bend_end_triangle.update(-_end_dir, _plane_join_point, end_binormal, p_width, p_bend_lip, _bend_normal, -_bend_side, _curve_side)

func _calc_arc_plane():
	var begin_mid := _bend_begin_triangle.get_leg_mid()
	var end_mid := _bend_end_triangle.get_leg_mid()
	var arc_center := _plane_join_point - (_plane_join_point - begin_mid) - (_plane_join_point - end_mid)
	var arc_plane := Plane(_bend_normal, arc_center)
	_arc_begin_mid = arc_plane.project(_bend_begin_triangle.get_bend_mid())
	_arc_end_mid = arc_plane.project(_bend_end_triangle.get_bend_mid())

func _intersect(a : Vector3, a_norm : Vector3, b : Vector3, b_norm : Vector3, plane_norm : Vector3) -> OptVector3:
	var seg := b - a
	var seg_len := seg.length()
	var seg_norm := seg.normalized()
	var alpha_sign := signf(b_norm.cross(a_norm).dot(plane_norm))
	var cos_alpha := b_norm.dot(a_norm)
	var beta_sign := signf(seg_norm.cross(b_norm).dot(plane_norm))
	var cos_beta := seg_norm.dot(b_norm)
	var intersect_side := alpha_sign * beta_sign
	var sin_alpha := sqrt(1 - cos_alpha*cos_alpha)
	var sin_beta := sqrt(1 - cos_beta*cos_beta)
	if is_equal_approx(sin_alpha, 0.0):
		return null
	var q := seg_len * sin_beta / sin_alpha
	var p := a - intersect_side * q * a_norm
	return OptVector3.new(p)

