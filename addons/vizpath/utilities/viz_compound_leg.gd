extends RefCounted
class_name VizCompoundLeg

var _error : String = ""
var _begin : VisualizationSpot
var _end : VisualizationSpot
var _width : float
var _bend_lip : float
var _intermediate_spot : VisualizationSpot = null
var _norm_distance : float
var _max_join_point_on_begin : Vector3
var _max_join_point_on_end : Vector3

func _init(p_begin : VisualizationSpot, p_end : VisualizationSpot, p_width : float, p_bend_lip : float):
	_begin = p_begin
	_end = p_end
	_width = p_width
	_bend_lip = p_bend_lip
	_calc_intermediate_point()
#	_calc_max_offset()
	_calc_intermediate_normal()
	
func _to_string():
	return "CLEG(%s to %s through %s)" % [_begin, _end, _intermediate_spot]

# ---------------------------------------------
# Public Methoeds

func is_invalid() -> bool:
	return _error != ""

func get_error() -> String:
	return _error

func get_begin() -> VisualizationSpot:
	return _begin

func get_begin_ray() -> Vector3:
	return (_max_join_point_on_begin - _begin.point).normalized()

func adjust_begin(distance : float):
	var new_begin := VisualizationSpot.new()
	new_begin.point = _begin.point + distance * get_begin_ray()
	new_begin.normal = _begin.normal
	_begin = new_begin
	_calc_intermediate_normal()

func get_end() -> VisualizationSpot:
	return _end

func get_end_ray() -> Vector3:
	return (_end.point - _max_join_point_on_end).normalized()

func adjust_end(distance : float):
	var new_end := VisualizationSpot.new()
	new_end.point = _end.point - distance * get_end_ray()
	new_end.normal = _end.normal
	_end = new_end
	_calc_intermediate_normal()

var test_mat : Material = load("res://example/common/materials/white.tres")

func update_mesh(mesh_node : Node3D, u : float, segs : int, sharpness : float, mat : Material) -> float:
	var leg1 := VizSimpleLeg.new(_begin, _intermediate_spot, _width, _bend_lip)
	if leg1.is_invalid():
		print("leg1=%s: error=%s" % [ leg1, leg1.get_error() ])
	assert(!leg1.is_invalid())
	var leg2 := VizSimpleLeg.new(_intermediate_spot, _end, _width, _bend_lip)
	if leg2.is_invalid():
		print("leg2: error=%s" % leg2.get_error())
	assert(!leg2.is_invalid())
	u = leg1.update_mesh(mesh_node, u, segs, sharpness, mat)
	var left := leg1.get_end_left()
	var right := leg1.get_end_right()
	u = leg2.extend_mesh(mesh_node, u, left, right, segs, sharpness, mat)
	return u

# ---------------------------------------------
# Local Methods

func _calc_intermediate_point():
	_intermediate_spot = VisualizationSpot.new()
	var intermediate_segment := _end.point - _begin.point
	_intermediate_spot.point = _begin.point + intermediate_segment / 2.0

func _calc_intermediate_normal():
	var begin_plane := Plane(_begin.normal, _begin.point)
	var max_point := begin_plane.project(_intermediate_spot.point)
#	var mid_point_distance := _intermediate_spot.point.distance_to(max_point)
	var mid_point_distance := _begin.point.distance_to(max_point)
	var cur_norm_distance = _bend_lip + VizSimpleLeg.MIN_SEGMENT_LENGTH
	var dir := (max_point - _begin.point).normalized()
	var valid := false
	while cur_norm_distance < mid_point_distance:
		var data := _check_normal(dir, cur_norm_distance)
		if data.size() == 3:
			_max_join_point_on_begin = data[0]
			_max_join_point_on_end = data[1]
			_intermediate_spot.normal = data[2]
			valid = true
			break
		cur_norm_distance += 0.01
	if not valid:
		_error = "%s is too close to %s to make compund leg with lip %s" % [ _begin.point, _end.point, _bend_lip ]
		
func _check_normal(dir : Vector3, norm_distance : float) -> Array:
	var candidate_segment := _intermediate_spot.point - (_begin.point + norm_distance * dir)
	var candidate_segment_dir := candidate_segment.normalized()
	var candidate_normal := ((_begin.normal + _end.normal)/2.0).normalized()
	var candidate_binormal := candidate_normal.cross(candidate_segment_dir).normalized()
	var candidate_mid := VisualizationSpot.new()
	candidate_mid.point = _intermediate_spot.point
	candidate_mid.normal = candidate_segment_dir.cross(candidate_binormal).normalized()
	var leg1 := VizSimpleLeg.new(_begin, candidate_mid, _width, _bend_lip)
	if not leg1.is_invalid():
		var leg2 := VizSimpleLeg.new(candidate_mid, _end, _width, _bend_lip)
		if not leg2.is_invalid():
			return [ leg1.get_leg_bend_begin(), leg2.get_leg_bend_end(), candidate_mid.normal ]
	return []
	
