extends RefCounted
class_name VizSegment

var _simple_leg : VizSimpleLeg = null
var _compound_leg : VizCompoundLeg = null

func _init(p_begin : VisualizationSpot, p_end : VisualizationSpot, p_width : float, p_bend_lip : float):
	_simple_leg = VizSimpleLeg.new(p_begin, p_end, p_width, p_bend_lip)
	if _simple_leg.is_invalid():
		_compound_leg = VizCompoundLeg.new(p_begin, p_end, p_width, p_bend_lip)

func is_invalid() -> bool:
	if _simple_leg.is_invalid():
		if _compound_leg.is_invalid():
			return true
	return false

func get_error() -> String:
	if _simple_leg.is_invalid():
		if _compound_leg.is_invalid():
			return _compound_leg.get_error()
			
		return _simple_leg.get_error()
	return ""

func get_begin() -> VisualizationSpot:
	if not _simple_leg.is_invalid():
		return _simple_leg.get_begin()
	return _compound_leg.get_begin()

func get_begin_ray() -> Vector3:
	if not _simple_leg.is_invalid():
		return _simple_leg.get_begin_ray()
	return _compound_leg.get_begin_ray()

func get_begin_binormal() -> Vector3:
	if not _simple_leg.is_invalid():
		return _simple_leg.get_begin_ray().cross(_simple_leg.get_begin().normal)
	return _compound_leg.get_begin_ray().cross(_compound_leg.get_begin().normal)

func adjust_begin(distance : float):
	if not _simple_leg.is_invalid():
		_simple_leg.adjust_begin(distance)
		if _simple_leg.is_invalid():
			_compound_leg = VizCompoundLeg.new(_simple_leg.get_begin(), _simple_leg.get_end(), _simple_leg._width, _simple_leg._bend_lip)
	else:
		_compound_leg.adjust_begin(distance)

func get_end() -> VisualizationSpot:
	if not _simple_leg.is_invalid():
		return _simple_leg.get_end()
	return _compound_leg.get_end()

func get_end_ray() -> Vector3:
	if not _simple_leg.is_invalid():
		return _simple_leg.get_end_ray()
	return _compound_leg.get_end_ray()

func get_end_binormal() -> Vector3:
	if not _simple_leg.is_invalid():
		return _simple_leg.get_end_ray().cross(_simple_leg.get_end().normal)
	return _compound_leg.get_end_ray().cross(_compound_leg.get_end().normal)

func adjust_end(distance : float):
	if not _simple_leg.is_invalid():
		_simple_leg.adjust_end(distance)
		if _simple_leg.is_invalid():
			_compound_leg = VizCompoundLeg.new(_simple_leg.get_begin(), _simple_leg.get_end(), _simple_leg._width, _simple_leg._bend_lip)
	else:
		_compound_leg.adjust_end(distance)

func update_mesh(mesh_instance : MeshInstance3D, u : float, segs : int, sharpness : float, mat : Material) -> float:
	if _simple_leg.is_invalid():
		if _compound_leg.is_invalid():
			return u
		u = _compound_leg.update_mesh(mesh_instance, u, segs, sharpness, mat)
	else:
		u = _simple_leg.update_mesh(mesh_instance, u, segs, sharpness, mat)
	return u

func _to_string():
	if not _simple_leg.is_invalid():
		return _simple_leg._to_string()
	if not _compound_leg.is_invalid():
		return _compound_leg._to_string()
	return "invalid segment"
