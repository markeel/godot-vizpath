extends RefCounted
class_name VizTriangle

var leg_right : Vector3
var leg_left : Vector3
var leg_fwd : Vector3
var bend_right : Vector3
var bend_left : Vector3
var distance : float
var fwd_side : float

func update(dir : Vector3, join_point : Vector3, binormal : Vector3, p_width : float, p_bend_lip : float, bend_normal : Vector3, bend_side : float, curve_side : float):
	var half_width := p_width / 2.0
	if bend_side == 0:
		leg_left = join_point - half_width * binormal - p_bend_lip * dir
		leg_right = join_point + half_width * binormal - p_bend_lip * dir
		bend_left = leg_left
		bend_right = leg_right
		distance = 0.0
	else:
		var cos_theta := dir.dot(bend_side * bend_normal)
		var sin_theta := sqrt(1-cos_theta*cos_theta)
		var width := half_width / sin_theta
		var lip_distance := p_bend_lip / sin_theta
		var bend_width = width * cos_theta
		leg_left = join_point - half_width * binormal - bend_width * dir - lip_distance * dir
		leg_right = join_point + half_width * binormal - bend_width * dir - lip_distance * dir
		leg_fwd = join_point - curve_side * bend_side * half_width * binormal + bend_width * dir - lip_distance * dir
		distance = bend_width * 2.0
		if bend_side * curve_side < 0:
			bend_left = leg_left
			bend_right = leg_fwd
			fwd_side = 1.0
		else:
			bend_left = leg_fwd
			bend_right = leg_right
			fwd_side = 0.0

func get_fwd_side():
	return fwd_side

func get_leg_mid() -> Vector3:
	return leg_left - (leg_left - leg_right) / 2.0

func get_bend_mid() -> Vector3:
	return bend_left - (bend_left - bend_right) / 2.0
