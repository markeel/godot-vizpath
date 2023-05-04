@tool
extends Resource
class_name VisualizationSpot

## The VisualizationSpot class is a resource that allows the definition
## of a spot for a VisualizedPath.
##
## A VisualizationSpot contains a point (local space) and a normal (local space)
## that identifies where the path starts, ends, or turns.

## The point in local space where the path originates, terminates, or turns
@export var point : Vector3 :
	set(p):
		point = p
		emit_changed()

## The normal defining the up direction of the plane this path will be in at this
## point.
@export var normal : Vector3 :
	set(n):
		normal = n
		emit_changed()

func _init():
	point = Vector3.ZERO
	normal = Vector3.FORWARD

func is_equal(other):
	if not point.is_equal_approx(other.point):
		return false
	if not normal.is_equal_approx(other.normal):
		return false
	return true

func _to_string():
	return "%s/%s" % [point, normal]
